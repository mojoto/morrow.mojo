#!/usr/bin/env bash
set -euo pipefail

__wrap__() {

VERSION="${MAGIC_VERSION:-latest}"
REPO="${MAGIC_REPO:-magic}"
MODULAR_HOME="${MODULAR_HOME:-"$HOME/.modular"}"
MODULAR_HOME="${MODULAR_HOME/#\~/$HOME}"
BIN_DIR="$MODULAR_HOME/bin"

if [[ "${REPO}" == "prerelease" ]]; then
  REPO="magic-prerelease"
fi

PLATFORM="$(uname -s)"
ARCH="${MAGIC_ARCH:-$(uname -m)}"

if [[ "${PLATFORM}" == "Darwin" ]]; then
  PLATFORM="apple-darwin"
elif [[ "${PLATFORM}" == "Linux" ]]; then
  PLATFORM="unknown-linux-musl"
elif [[ $(uname -o) == "Msys" ]]; then
  PLATFORM="pc-windows-msvc"
fi

if [[ "${ARCH}" == "arm64" ]] || [[ "${ARCH}" == "aarch64" ]]; then
  ARCH="aarch64"
fi

BINARY="magic-${ARCH}-${PLATFORM}"

if [[ "${VERSION}" == "latest" ]]; then
  printf "Installing the latest version of Magic...\n"
else
  printf "Installing version %s of Magic...\n" "${VERSION}"
fi

DOWNLOAD_URL="https://dl.modular.com/public/${REPO}/raw/versions/${VERSION}/${BINARY}"

mkdir -p "$BIN_DIR"

# Test if stdout is a terminal before showing progress
if [[ ! -t 1 ]]; then
  CURL_OPTIONS="--silent"  # --no-progress-meter is better, but only available in 7.67+
  WGET_OPTIONS="--no-verbose"
else
  CURL_OPTIONS="--no-silent"
  WGET_OPTIONS="--show-progress"
fi

if hash curl 2> /dev/null; then
  HTTP_CODE=$(curl -SL $CURL_OPTIONS "$DOWNLOAD_URL" --output "${BIN_DIR}/magic" --write-out "%{http_code}")
  if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 499 ]]; then
    echo "error: ${HTTP_CODE} response. Please try again later."
    exit 1
  elif [[ ${HTTP_CODE} -gt 299 ]]; then
    echo "error: '${DOWNLOAD_URL}' not found."
    echo "Sorry, Magic is not available for your OS and CPU architecture. " \
         "See https://modul.ar/requirements."
    exit 1
  fi
elif hash wget 2> /dev/null; then
  if ! wget $WGET_OPTIONS --output-document="${BIN_DIR}/magic" "$DOWNLOAD_URL"; then
    echo "error: '${DOWNLOAD_URL}' not found."
    echo "Sorry, Magic is not available for your OS and CPU architecture. " \
         "See https://modul.ar/requirements."
    exit 1
  fi
fi

# gh release download --repo modularml/magic $VERSION -p $BINARY --clobber -O "${BIN_DIR}/magic"
chmod +x "${BIN_DIR}/magic"

echo "Done. The 'magic' binary is in '${BIN_DIR}'"

update_shell() {
    FILE=$1
    LINE=$2

    # Expand ~ to full home directory path if present
    FILE="${FILE/#\~/$HOME}"

    # shell update can be suppressed by `MAGIC_NO_PATH_UPDATE` env var
    [[ -n "${MAGIC_NO_PATH_UPDATE-}" ]] && echo "No path update because MAGIC_NO_PATH_UPDATE has a value" && return

    # Create the file if it doesn't exist
    if [ -f "${FILE}" ]; then
        touch "${FILE}"
    fi

    # Append the line if not already present
    if ! grep -Fxq "${LINE}" "${FILE}" 2>/dev/null
    then
        printf "\n%s" "${LINE}" >> "${FILE}"
        printf "\nTwo more steps:\n"
        printf "1. To use 'magic', run this command so it's in your PATH:\n"
        printf "source %s\n" "${FILE}"
        printf "2. To build with MAX and Mojo, go to http://modul.ar/get-started\n"
    fi
}

case "$(basename "$SHELL")" in
    sh)
        if [ -w ~/.bash_profile ]; then
            BASH_FILE=~/.bash_profile
        else
            # Default to bashrc as that is used in non login shells instead of the profile.
            BASH_FILE=~/.bashrc
        fi
        LINE="export PATH=\"\$PATH:${BIN_DIR}\""
        update_shell $BASH_FILE "$LINE"
        ;;

    bash)
        if [ -w ~/.bash_profile ]; then
            BASH_FILE=~/.bash_profile
        else
            # Default to bashrc as that is used in non login shells instead of the profile.
            BASH_FILE=~/.bashrc
        fi
        LINE="export PATH=\"\$PATH:${BIN_DIR}\""
        update_shell $BASH_FILE "$LINE"
        ;;

    fish)
        LINE="fish_add_path ${BIN_DIR}"
        update_shell ~/.config/fish/config.fish "$LINE"
        ;;

    zsh)
        LINE="export PATH=\"\$PATH:${BIN_DIR}\""
        update_shell ~/.zshrc "$LINE"
        ;;

    tcsh)
        LINE="set path = ( \$path ${BIN_DIR} )"
        update_shell ~/.tcshrc "$LINE"
        ;;

    *)
        echo "Could not update shell: $(basename "$SHELL")"
        echo "Please permanently add '${BIN_DIR}' to your ${PATH} to enable the 'magic' command."
        ;;
esac

echo magic-unknown > "${MODULAR_HOME}/webUserId"

WEB_USER_ID=""
if [[ -f "${MODULAR_HOME}/webUserId" ]]; then
  WEB_USER_ID=$(cat "${MODULAR_HOME}/webUserId")
fi

CURRENT_TIME=0
if command -v python3 &> /dev/null; then
    CURRENT_TIME=$(python3 -c "from time import time; print(int(time() * 1_000_000_000))")
elif command -v date &> /dev/null; then
    CURRENT_TIME=$(date +%s%N)
fi

JSON_DATA=$(cat <<EOF
{
  "resourceLogs": [
    {
      "resource": {
        "attributes": [
          {"key": "enduser.id", "value": {"stringValue": ""}},
          {"key": "web.user.id", "value": {"stringValue": "${WEB_USER_ID}"}},
          {"key": "service.name", "value": {"stringValue": "unknown_service"}},
          {"key": "telemetry.sdk.language", "value": {"stringValue": "cpp"}},
          {"key": "telemetry.sdk.version", "value": {"stringValue": "1.14.2"}},
          {"key": "telemetry.sdk.name", "value": {"stringValue": "opentelemetry"}}
        ]
      },
      "scopeLogs": [
        {
          "logRecords": [
            {
              "attributes": [
                {"key": "event.domain", "value": {"stringValue": "modular"}},
                {"key": "event.name", "value": {"stringValue": "install.magic"}}
              ],
              "body": {"stringValue": ""},
              "observedTimeUnixNano": "${CURRENT_TIME}",
              "severityNumber": 9,
              "severityText": "INFO"
            }
          ],
          "scope": {"name": "modular_logger"}
        }
      ]
    }
  ]
}
EOF
  )
  {
    curl --silent --show-error --header "Content-Type: application/json" \
      --header "Host: telemetry.modular.com:443" \
      --header "Accept: */*" \
      --data "${JSON_DATA}" \
      "https://telemetry.modular.com:443/v1/logs" > /dev/null 2>&1 &
  } || true

}; __wrap__

