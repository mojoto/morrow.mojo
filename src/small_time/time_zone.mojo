from collections import Optional
import .c

alias UTC_TZ = TimeZone(0, String("UTC"))
"""UTC Timezone."""


fn local() -> TimeZone:
    """Returns the local timezone.
    
    Returns:
        Local timezone.
    """
    var local_t = c.localtime(0)
    return TimeZone(int(local_t.tm_gmtoff), String("local"))


fn from_utc(utc_str: String) raises -> TimeZone:
    """Creates a timezone from a string.

    Args:
        utc_str: UTC string.
    
    Returns:
        Timezone.
    
    Raises:
        Error: If the UTC string is invalid.
    """
    if len(utc_str) == 0:
        raise Error("utc_str is empty")
    if utc_str == "utc" or utc_str == "UTC" or utc_str == "Z":
        return TimeZone(0, String("utc"))
    var p = 3 if len(utc_str) > 3 and utc_str[0:3] == "UTC" else 0

    var sign = -1 if utc_str[p] == "-" else 1
    if utc_str[p] == "+" or utc_str[p] == "-":
        p += 1

    if len(utc_str) < p + 2 or not isdigit(ord(utc_str[p])) or not isdigit(ord(utc_str[p + 1])):
        raise Error("utc_str format is invalid")
    var hours: Int = atol(utc_str[p : p + 2])
    p += 2

    var minutes: Int
    if len(utc_str) <= p:
        minutes = 0
    elif len(utc_str) == p + 3 and utc_str[p] == ":":
        minutes = atol(utc_str[p + 1 : p + 3])
    elif len(utc_str) == p + 2 and isdigit(ord(utc_str[p])):
        minutes = atol(utc_str[p : p + 2])
    else:
        minutes = 0
        raise Error("utc_str format is invalid")
    var offset: Int = sign * (hours * 3600 + minutes * 60)
    return TimeZone(offset)


@value
struct TimeZone(Stringable):
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
        var hh = offset_abs // 3600
        var mm = offset_abs % 3600
        return sign + str(hh).rjust(2, "0") + sep + str(mm).rjust(2, "0")
