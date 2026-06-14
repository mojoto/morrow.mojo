from .constants import MAX_TIMESTAMP, MAX_TIMESTAMP_MS, MAX_TIMESTAMP_US
from .constants import days_in_month, days_before_month


def _is_leap(year: Int) -> Bool:
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
    return days_in_month(month)


def _days_before_month(year: Int, month: Int) -> Int:
    """
    Calculate the number of days in a year preceding the first day of a given month.
    """
    if month > 2 and _is_leap(year):
        return days_before_month(month) + 1
    return days_before_month(month)


@always_inline
def _ymd2ord(year: Int, month: Int, day: Int) -> Int:
    """
    Convert a date to ordinal, considering 01-Jan-0001 as day 1.
    """
    return _days_before_year(year) + _days_before_month(year, month) + day


def normalize_timestamp(timestamp: Float64) raises -> Float64:
    """
    Normalize millisecond and microsecond timestamps into standard timestamps.
    """
    var timestamp_ = timestamp
    if timestamp_ > Float64(MAX_TIMESTAMP):
        if timestamp_ < Float64(MAX_TIMESTAMP_MS):
            timestamp_ /= 1000
        elif timestamp_ < Float64(MAX_TIMESTAMP_US):
            timestamp_ /= 1_000_000
        else:
            raise Error(
                "The specified timestamp "
                + String(timestamp_)
                + "is too large."
            )
    return timestamp_
