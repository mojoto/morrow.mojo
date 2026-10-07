"""Proleptic Gregorian calendar arithmetic and default English names.

Ordinals count days from 0001-01-01 (ordinal 1), as in Python's `datetime`.
"""

comptime US_PER_SECOND = 1_000_000
comptime US_PER_MINUTE = 60 * US_PER_SECOND
comptime US_PER_HOUR = 60 * US_PER_MINUTE
comptime US_PER_DAY = 24 * US_PER_HOUR
comptime SECONDS_PER_DAY = 86400
comptime UNIX_EPOCH_ORDINAL = 719163  # 1970-01-01
comptime MAX_ORDINAL = 3652059  # 9999-12-31

# Timestamps above these thresholds are read as milliseconds, then
# microseconds, like Arrow's normalize_timestamp (3000-01-01 in seconds).
comptime MAX_TIMESTAMP = 32503737600
comptime MAX_TIMESTAMP_MS = MAX_TIMESTAMP * 1000
comptime MAX_TIMESTAMP_US = MAX_TIMESTAMP * 1_000_000

comptime _DAYS_IN_400_YEARS = 146097
comptime _DAYS_IN_100_YEARS = 36524
comptime _DAYS_IN_4_YEARS = 1461


def is_leap(year: Int) -> Bool:
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


def days_before_year(year: Int) -> Int:
    """Days before January 1st of year."""
    var y = year - 1
    return y * 365 + y // 4 - y // 100 + y // 400


def days_in_month(year: Int, month: Int) -> Int:
    if month == 2:
        return 29 if is_leap(year) else 28
    if month == 4 or month == 6 or month == 9 or month == 11:
        return 30
    return 31


def days_before_month(year: Int, month: Int) -> Int:
    """Days in year before the first day of month."""
    var days = 0
    if month == 2:
        days = 31
    elif month == 3:
        days = 59
    elif month == 4:
        days = 90
    elif month == 5:
        days = 120
    elif month == 6:
        days = 151
    elif month == 7:
        days = 181
    elif month == 8:
        days = 212
    elif month == 9:
        days = 243
    elif month == 10:
        days = 273
    elif month == 11:
        days = 304
    elif month == 12:
        days = 334
    if month > 2 and is_leap(year):
        days += 1
    return days


@always_inline
def ymd2ord(year: Int, month: Int, day: Int) -> Int:
    return days_before_year(year) + days_before_month(year, month) + day


def ord2ymd(ordinal: Int) -> Tuple[Int, Int, Int]:
    """Year, month and day of an ordinal (CPython's `_ord2ymd`)."""
    # Work from the 400-year cycle containing the day, then 100-, 4- and
    # 1-year cycles. n is the zero-based day offset into each cycle.
    var n = ordinal - 1
    var n400 = n // _DAYS_IN_400_YEARS
    n = n % _DAYS_IN_400_YEARS
    var n100 = n // _DAYS_IN_100_YEARS
    n = n % _DAYS_IN_100_YEARS
    var n4 = n // _DAYS_IN_4_YEARS
    n = n % _DAYS_IN_4_YEARS
    var n1 = n // 365
    n = n % 365
    var year = n400 * 400 + 1 + n100 * 100 + n4 * 4 + n1
    # n1 or n100 reach 4 only on the last day of a 4- or 400-year cycle.
    if n1 == 4 or n100 == 4:
        return (year - 1, 12, 31)

    # The estimate is exact or one month too large.
    var month = (n + 50) >> 5
    if days_before_month(year, month) > n:
        month -= 1
    return (year, month, n - days_before_month(year, month) + 1)


def isoweekday_of(ordinal: Int) -> Int:
    """ISO weekday (Monday 1 .. Sunday 7); 0001-01-01 was a Monday."""
    return ordinal % 7 or 7


def day_of_year(year: Int, month: Int, day: Int) -> Int:
    return days_before_month(year, month) + day


def iso_week1_monday(year: Int) -> Int:
    """Ordinal of the Monday starting ISO week 1 of year."""
    var fourth_jan = ymd2ord(year, 1, 4)
    return fourth_jan - isoweekday_of(fourth_jan) + 1


def iso_calendar(year: Int, month: Int, day: Int) -> Tuple[Int, Int, Int]:
    """ISO year, week number and weekday of a date."""
    var ordinal = ymd2ord(year, month, day)
    var iso_year = year
    var week1 = iso_week1_monday(iso_year)
    if ordinal < week1:
        iso_year -= 1
        week1 = iso_week1_monday(iso_year)
    else:
        var next_week1 = iso_week1_monday(iso_year + 1)
        if ordinal >= next_week1:
            iso_year += 1
            week1 = next_week1
    return (iso_year, (ordinal - week1) // 7 + 1, isoweekday_of(ordinal))


def epoch_seconds(
    year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int
) -> Int:
    """Seconds from 1970-01-01T00:00:00 to the given wall time."""
    return (
        (ymd2ord(year, month, day) - UNIX_EPOCH_ORDINAL) * SECONDS_PER_DAY
        + hour * 3600
        + minute * 60
        + second
    )


def normalize_timestamp(timestamp: Float64) raises -> Float64:
    """Read millisecond and microsecond timestamps as seconds."""
    if timestamp > Float64(MAX_TIMESTAMP):
        if timestamp < Float64(MAX_TIMESTAMP_MS):
            return timestamp / 1000
        if timestamp < Float64(MAX_TIMESTAMP_US):
            return timestamp / 1_000_000
        raise Error(
            "The specified timestamp " + String(timestamp) + "is too large."
        )
    return timestamp


def month_name(month: Int) -> String:
    if month == 1:
        return "January"
    if month == 2:
        return "February"
    if month == 3:
        return "March"
    if month == 4:
        return "April"
    if month == 5:
        return "May"
    if month == 6:
        return "June"
    if month == 7:
        return "July"
    if month == 8:
        return "August"
    if month == 9:
        return "September"
    if month == 10:
        return "October"
    if month == 11:
        return "November"
    if month == 12:
        return "December"
    return ""


def month_abbreviation(month: Int) -> String:
    if month < 1 or month > 12:
        return ""
    return String(month_name(month)[byte=0:3])


def day_name(isoweekday: Int) -> String:
    if isoweekday == 1:
        return "Monday"
    if isoweekday == 2:
        return "Tuesday"
    if isoweekday == 3:
        return "Wednesday"
    if isoweekday == 4:
        return "Thursday"
    if isoweekday == 5:
        return "Friday"
    if isoweekday == 6:
        return "Saturday"
    if isoweekday == 7:
        return "Sunday"
    return ""


def day_abbreviation(isoweekday: Int) -> String:
    if isoweekday < 1 or isoweekday > 7:
        return ""
    return String(day_name(isoweekday)[byte=0:3])
