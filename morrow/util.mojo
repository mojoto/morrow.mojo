from .constants import MAX_TIMESTAMP, MAX_TIMESTAMP_MS, MAX_TIMESTAMP_US
from .constants import _DAYS_IN_MONTH, _DAYS_BEFORE_MONTH


fn _is_leap(year: Int) -> Bool:
    """
    Determine if a given year is a leap year.
    """
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


def _days_before_year(year: Int) -> Int:
    """
    Calculate the number of days before January 1st of a given year.
    """
    var y = year - 1
    return y * 365 + y // 4 - y // 100 + y // 400


def _days_in_month(year: Int, month: Int) -> Int:
    """
    Calculate the number of days in a specific month of a given year.
    """
    if month == 2 and _is_leap(year):
        return 29
    return _DAYS_IN_MONTH[month]


def _days_before_month(year: Int, month: Int) -> Int:
    """
    Calculate the number of days in a year preceding the first day of a given month.
    """
    if month > 2 and _is_leap(year):
        return _DAYS_BEFORE_MONTH[month] + 1
    return _DAYS_BEFORE_MONTH[month]


@always_inline
def _ymd2ord(year: Int, month: Int, day: Int) -> Int:
    """
    Convert a date to ordinal, considering 01-Jan-0001 as day 1.
    """
    dim = _days_in_month(year, month)
    return _days_before_year(year) + _days_before_month(year, month) + day


def normalize_timestamp(timestamp: Float64) -> Float64:
    """
    Normalize millisecond and microsecond timestamps into standard timestamps.
    """
    if timestamp > MAX_TIMESTAMP:
        if timestamp < MAX_TIMESTAMP_MS:
            timestamp /= 1000
        elif timestamp < MAX_TIMESTAMP_US:
            timestamp /= 1_000_000
        else:
            raise Error(
                "The specified timestamp " + str(timestamp) + "is too large."
            )
    return timestamp
