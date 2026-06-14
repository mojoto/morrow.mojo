# todo: hardcode for tmp
comptime _MAX_TIMESTAMP: Int = 32503737600
comptime MAX_TIMESTAMP = _MAX_TIMESTAMP
comptime MAX_TIMESTAMP_MS = MAX_TIMESTAMP * 1000
comptime MAX_TIMESTAMP_US = MAX_TIMESTAMP * 1_000_000


fn days_in_month(month: Int) -> Int:
    if month == 1:
        return 31
    if month == 2:
        return 28
    if month == 3:
        return 31
    if month == 4:
        return 30
    if month == 5:
        return 31
    if month == 6:
        return 30
    if month == 7:
        return 31
    if month == 8:
        return 31
    if month == 9:
        return 30
    if month == 10:
        return 31
    if month == 11:
        return 30
    if month == 12:
        return 31
    return -1


fn days_before_month(month: Int) -> Int:
    if month == 1:
        return 0
    if month == 2:
        return 31
    if month == 3:
        return 59
    if month == 4:
        return 90
    if month == 5:
        return 120
    if month == 6:
        return 151
    if month == 7:
        return 181
    if month == 8:
        return 212
    if month == 9:
        return 243
    if month == 10:
        return 273
    if month == 11:
        return 304
    if month == 12:
        return 334
    return -1


fn month_name(month: Int) -> String:
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


fn month_abbreviation(month: Int) -> String:
    if month == 1:
        return "Jan"
    if month == 2:
        return "Feb"
    if month == 3:
        return "Mar"
    if month == 4:
        return "Apr"
    if month == 5:
        return "May"
    if month == 6:
        return "Jun"
    if month == 7:
        return "Jul"
    if month == 8:
        return "Aug"
    if month == 9:
        return "Sep"
    if month == 10:
        return "Oct"
    if month == 11:
        return "Nov"
    if month == 12:
        return "Dec"
    return ""


fn day_name(day: Int) -> String:
    if day == 1:
        return "Monday"
    if day == 2:
        return "Tuesday"
    if day == 3:
        return "Wednesday"
    if day == 4:
        return "Thursday"
    if day == 5:
        return "Friday"
    if day == 6:
        return "Saturday"
    if day == 7:
        return "Sunday"
    return ""


fn day_abbreviation(day: Int) -> String:
    if day == 1:
        return "Mon"
    if day == 2:
        return "Tue"
    if day == 3:
        return "Wed"
    if day == 4:
        return "Thu"
    if day == 5:
        return "Fri"
    if day == 6:
        return "Sat"
    if day == 7:
        return "Sun"
    return ""
