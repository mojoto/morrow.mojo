"""Private TZif (RFC 8536) reader for timezone abbreviations such as EDT.

ICU supplies offsets; tzdata abbreviations come from the system zoneinfo files
so they match Python's zoneinfo and Arrow.
"""
from std.os import getenv
from std.os.path import exists


def _zone_path(zone: String) -> String:
    if zone == "local":
        var tz = getenv("TZ")
        if tz.byte_length() > 0:
            var name = String(tz[byte=1:]) if tz.as_bytes()[0] == 58 else tz
            if name.byte_length() > 0 and name.as_bytes()[0] == 47:
                return name if exists(name) else ""
            var path = _zone_path(name)
            if path.byte_length() > 0:
                return path
        return "/etc/localtime" if exists("/etc/localtime") else ""
    if zone.byte_length() == 0 or zone.find("..") >= 0:
        return ""
    var roots = List[String]()
    var tzdir = getenv("TZDIR")
    if tzdir.byte_length() > 0:
        roots.append(tzdir)
    roots.append("/usr/share/zoneinfo")
    roots.append("/usr/lib/zoneinfo")
    roots.append("/usr/share/lib/zoneinfo")
    for root in roots:
        var path = root + "/" + zone
        if exists(path):
            return path
    return ""


def _u32(data: List[UInt8], pos: Int) -> Int:
    return (
        (Int(data[pos]) << 24)
        | (Int(data[pos + 1]) << 16)
        | (Int(data[pos + 2]) << 8)
        | Int(data[pos + 3])
    )


def _i32(data: List[UInt8], pos: Int) -> Int:
    var value = _u32(data, pos)
    return value - (1 << 32) if value >= (1 << 31) else value


def _i64(data: List[UInt8], pos: Int) -> Int:
    var value = 0
    for i in range(8):
        value = (value << 8) | Int(data[pos + i])
    return value


def _is_alpha(byte: Int) -> Bool:
    return (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)


def _footer_names(footer: String) -> List[String]:
    """Standard and daylight names from a POSIX TZ string like EST5EDT,..."""
    var names = List[String]()
    var pos = 0
    var length = footer.byte_length()
    while pos < length and len(names) < 2:
        var start = pos
        var end = pos
        if footer.as_bytes()[pos] == 60:
            end = pos + 1
            while end < length and footer.as_bytes()[end] != 62:
                end += 1
            if end >= length:
                break
            names.append(String(footer[byte = start + 1 : end]))
            pos = end + 1
        else:
            while end < length and _is_alpha(Int(footer.as_bytes()[end])):
                end += 1
            if end - start < 3:
                break
            names.append(String(footer[byte=start:end]))
            pos = end
        # Skip the offset that follows a name.
        while pos < length:
            var byte = Int(footer.as_bytes()[pos])
            if byte == 44 or byte == 60 or _is_alpha(byte):
                break
            pos += 1
        if pos < length and footer.as_bytes()[pos] == 44:
            break
    return names^


def _abbreviation_at(chars: List[UInt8], start: Int, index: Int) -> String:
    var result = String("")
    var pos = start + index
    while pos < len(chars) and chars[pos] != 0:
        result += chr(Int(chars[pos]))
        pos += 1
    return result


def _read(path: String) -> List[UInt8]:
    try:
        with open(path, "r") as file:
            return file.read_bytes()
    except:
        return List[UInt8]()


def tzif_abbreviation(zone: String, timestamp: Int, is_dst: Bool) -> String:
    """Return the tzdata abbreviation in effect, or "" when unavailable."""
    var path = _zone_path(zone)
    if path.byte_length() == 0:
        return ""
    var data = _read(path)
    if (
        len(data) < 44
        or data[0] != 84
        or data[1] != 90
        or data[2] != 105
        or data[3] != 102
    ):
        return ""
    var base = 0
    var time_size = 4
    if data[4] >= 50:
        var v1 = (
            _u32(data, 32) * 5
            + _u32(data, 36) * 6
            + _u32(data, 40)
            + _u32(data, 28) * 8
            + _u32(data, 24)
            + _u32(data, 20)
        )
        base = 44 + v1
        time_size = 8
        if len(data) < base + 44:
            return ""
    var isutcnt = _u32(data, base + 20)
    var isstdcnt = _u32(data, base + 24)
    var leapcnt = _u32(data, base + 28)
    var timecnt = _u32(data, base + 32)
    var typecnt = _u32(data, base + 36)
    var charcnt = _u32(data, base + 40)
    var times = base + 44
    var indexes = times + timecnt * time_size
    var types = indexes + timecnt
    var chars = types + typecnt * 6
    var end = chars + charcnt + leapcnt * (time_size + 4) + isstdcnt + isutcnt
    if typecnt == 0 or len(data) < end:
        return ""

    var type_index = 0
    var last = -1
    for i in range(timecnt):
        var at = _i64(data, times + i * 8) if time_size == 8 else _i32(
            data, times + i * 4
        )
        if at > timestamp:
            break
        last = i
    if last >= 0:
        type_index = Int(data[indexes + last])
    if last == timecnt - 1 and time_size == 8:
        # After the last transition the POSIX footer governs future rules.
        var footer_start = end + 1
        var footer_end = footer_start
        while footer_end < len(data) and data[footer_end] != 10:
            footer_end += 1
        var footer = String("")
        for i in range(footer_start, footer_end):
            footer += chr(Int(data[i]))
        var names = _footer_names(footer)
        if len(names) == 2 and is_dst:
            return names[1]
        if len(names) >= 1:
            return names[0]
    var record = types + type_index * 6
    return _abbreviation_at(data, chars, Int(data[record + 5]))
