from .morrow import (
    Morrow,
    MorrowDate,
    MorrowIsoCalendar,
    MorrowSpan,
    MorrowTime,
    MorrowTimeTuple,
)
from .timezone import TimeZone
from .timedelta import TimeDelta

comptime __version__ = "0.6.0"

comptime FORMAT_ATOM = "YYYY-MM-DD HH:mm:ssZZ"
comptime FORMAT_COOKIE = "dddd, DD-MMM-YYYY HH:mm:ss ZZZ"
comptime FORMAT_RSS = "ddd, DD MMM YYYY HH:mm:ss Z"
comptime FORMAT_RFC822 = "ddd, DD MMM YY HH:mm:ss Z"
comptime FORMAT_RFC850 = "dddd, DD-MMM-YY HH:mm:ss ZZZ"
comptime FORMAT_RFC1036 = "ddd, DD MMM YY HH:mm:ss Z"
comptime FORMAT_RFC1123 = "ddd, DD MMM YYYY HH:mm:ss Z"
comptime FORMAT_RFC2822 = "ddd, DD MMM YYYY HH:mm:ss Z"
comptime FORMAT_RFC3339 = "YYYY-MM-DD HH:mm:ssZZ"
comptime FORMAT_RFC3339_STRICT = "YYYY-MM-DDTHH:mm:ssZZ"
comptime FORMAT_W3C = "YYYY-MM-DD HH:mm:ssZZ"
