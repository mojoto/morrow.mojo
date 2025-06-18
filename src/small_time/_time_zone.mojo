from collections import Optional
import small_time.c

alias UTC = "UTC"
alias UTC_TZ = TimeZone(0, UTC)
"""UTC Timezone."""

alias DASH = "-"
alias PLUS = "+"
alias COLON = ":"


fn local() raises -> TimeZone:
    """Returns the local timezone.
    
    Returns:
        Local timezone.
    """
    var local_t = c.get_local_time(0)
    return TimeZone(Int(local_t.time_zone_offset), "local")


fn _is_numeric(c: Byte) -> Bool:
    """Checks if a character is numeric.
    
    Args:
        c: Character.
    
    Returns:
        True if the character is numeric, False otherwise.
    """
    return c >= ord("0") and c <= ord("9")


fn from_utc(tz: StringSlice) raises -> TimeZone:
    """Creates a timezone from a string.

    Args:
        tz: UTC string.

    Returns:
        Timezone.

    Raises:
        Error: If the UTC string is invalid.
    """
    if len(tz) == 0:
        raise Error("utc is empty")

    if tz == "utc" or tz == "UTC" or tz == "Z":
        return TimeZone(0, String("utc"))

    var i = 0
    # Skip the UTC prefix.
    if len(tz) > 3 and tz[0:3] == UTC:
        i = 3

    var sign = -1 if tz[i] == DASH else 1
    if tz[i] == PLUS or tz[i] == DASH:
        i += 1

    if len(tz) < i + 2 or not _is_numeric(ord(tz[i])) or not _is_numeric(ord(tz[i + 1])):
        raise Error("utc format is invalid")
    var hours = atol(tz[i : i + 2])
    i += 2

    var minutes: Int
    if len(tz) <= i:
        minutes = 0
    elif len(tz) == i + 3 and tz[i] == COLON:
        minutes = atol(tz[i + 1 : i + 3])
    elif len(tz) == i + 2 and _is_numeric(ord(tz[i])):
        minutes = atol(tz[i : i + 2])
    else:
        raise Error("`tz` format is invalid")

    var offset = sign * (hours * 3600 + minutes * 60)
    return TimeZone(offset)


@fieldwise_init
struct TimeZone(Copyable, ExplicitlyCopyable, Movable, Stringable):
    """Timezone."""
    var offset: Int
    """Offset in seconds."""
    var name: Optional[String]
    """Name of the timezone."""

    fn __init__(out self, offset: Int = 0, name: String = "utc"):
        """Initializes a new timezone.

        Args:
            offset: Offset in seconds.
            name: Name of the timezone.
        """
        self.offset = offset
        self.name = name

    fn __str__(self) -> String:
        """String representation of the timezone.

        Returns:
            String representation.
        """
        if self.name:
            return self.name.value()
        return ""

    fn __bool__(self) -> Bool:
        """Checks if the timezone is valid.

        Returns:
            True if the timezone is valid, False otherwise.
        """
        return self.name.__bool__()

    fn format(self, sep: String = ":") -> String:
        """Formats the timezone.

        Args:
            sep: Separator between hours and minutes.

        Returns:
            Formatted timezone.
        """
        var sign: String
        var offset_abs: Int
        if self.offset < 0:
            sign = "-"
            offset_abs = -self.offset
        else:
            sign = "+"
            offset_abs = self.offset
        var hh = String(offset_abs // 3600)
        var mm = String(offset_abs % 3600)
        return String(sign, hh.rjust(2, "0"), sep, mm.rjust(2, "0"))
