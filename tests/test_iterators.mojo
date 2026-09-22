from std.testing import assert_equal, assert_true, assert_raises, TestSuite
from std.iter import StopIteration
from morrow import Morrow, TimeZone
from morrow._libc import c_localtime


def test_creation_contract() raises:
    var dt = Morrow(2024, 2, 29)
    assert_equal(String(dt), "2024-02-29T00:00:00.000000+00:00")
    assert_true(dt.naive().tz.is_none())
    assert_true(not (dt == dt.naive()))
    var rejected = False
    try:
        _ = Morrow(2023, 2, 29)
    except e:
        rejected = True
    assert_true(rejected)
    rejected = False
    try:
        _ = dt < dt.naive()
    except e:
        rejected = True
    assert_true(rejected)
    rejected = False
    try:
        _ = dt - dt.naive()
    except e:
        rejected = True
    assert_true(rejected)


def test_shift_overflow() raises:
    var rejected = False
    try:
        _ = Morrow(2024, 1, 1).shift(hours=9223372036854775807)
    except e:
        rejected = True
    assert_true(rejected)
    rejected = False
    try:
        _ = Morrow.max().shift(microseconds=1)
    except e:
        rejected = True
    assert_true(rejected)


def test_lazy_points_and_calendar_edges() raises:
    var start = Morrow(2024, 1, 31)
    var end = Morrow(2024, 5, 31)
    var expected: List[Int] = [31, 29, 31, 30, 31]
    var i = 0
    for point in Morrow.iter_range("month", start, end):
        assert_equal(point.day, expected[i])
        i += 1
        assert_true(i <= 5)
    assert_equal(i, 5)
    i = 0
    for point in Morrow.iter_range("microsecond", Morrow.min(), Morrow.max()):
        assert_equal(point.microsecond, i)
        i += 1
        if i == 3:
            break
    assert_equal(i, 3)
    assert_equal(len(Morrow.range("microsecond", Morrow.max(), limit=1)), 1)
    assert_equal(len(Morrow.range("day", start, limit=0)), 0)
    assert_equal(len(Morrow.range("day", end, start)), 0)
    var last = Morrow.iter_range("microsecond", Morrow.max(), Morrow.max())
    assert_date(last.__next__(), Morrow.max())
    var stopped = False
    try:
        _ = last.__next__()
    except StopIteration:
        stopped = True
    assert_true(stopped)


def test_lazy_spans_and_grouping() raises:
    var start = Morrow(2024, 1, 31, 12)
    var end = Morrow(2024, 5, 15)
    var i = 0
    for span in Morrow.iter_span_range("month", start, end, exact=True):
        assert_equal(
            span.start.day, 31 if i == 0 or i == 2 else 29 if i == 1 else 30
        )
        i += 1
        assert_true(i <= 4)
    assert_equal(i, 4)
    i = 0
    for span in Morrow.iter_interval(
        "month", start, end, interval=3, exact=True
    ):
        if i == 0:
            assert_date(span.start, start)
            assert_date(
                span.end, Morrow(2024, 4, 30, 12).shift(microseconds=-1)
            )
        else:
            assert_date(span.end, end.shift(microseconds=-1))
        i += 1
        assert_true(i <= 2)
    assert_equal(i, 2)
    # A huge interval range with limit=1 must not materialize the base range.
    i = 0
    for span in Morrow.iter_interval(
        "second",
        Morrow(2024, 1, 1),
        Morrow(2030, 1, 1),
        interval=2,
        limit=1,
        exact=True,
    ):
        assert_date(span.end, Morrow(2024, 1, 1, 0, 0, 1, 999999))
        i += 1
    assert_equal(i, 1)


def test_nth_weekday() raises:
    var monday = Morrow(2024, 1, 1)
    assert_date(monday.shift_weekday(0), monday)
    assert_date(monday.shift_weekday(0, -1), monday)
    assert_date(monday.shift_weekday(4, 2), Morrow(2024, 1, 12))
    assert_date(monday.shift_weekday(4, -2), Morrow(2023, 12, 22))


def test_local_target_date() raises:
    var timestamps: List[Int] = [0, 1704067200, 1719792000]
    for timestamp in timestamps:
        var tm = c_localtime(timestamp)
        var dt = Morrow.utcfromtimestamp(timestamp).to("local")
        assert_equal(dt.tz.offset, Int(tm.tm_gmtoff))
        assert_equal(dt.hour, Int(tm.tm_hour))
        assert_equal(dt.int_timestamp(), timestamp)
        var wall = Morrow(
            dt.year,
            dt.month,
            dt.day,
            dt.hour,
            dt.minute,
            dt.second,
            tz=TimeZone.local(),
        )
        assert_equal(wall.tz.offset, Int(tm.tm_gmtoff))


def assert_date(left: Morrow, right: Morrow) raises:
    assert_equal(String(left), String(right))


def test_iterator_copy_preserves_independent_progress() raises:
    var start = Morrow(2024, 1, 1)
    var iterator = Morrow.iter_range("day", start, limit=3)
    assert_date(iterator.__next__(), start)
    var copied = iterator
    assert_date(iterator.__next__(), start.shift(days=1))
    assert_date(copied.__next__(), start.shift(days=1))
    assert_date(copied.__next__(), start.shift(days=2))
    assert_date(iterator.__next__(), start.shift(days=2))


def test_iterator_repeated_exhaustion() raises:
    var dt = Morrow(2024, 1, 1)
    var iterator = Morrow.iter_range("day", dt, dt)
    _ = iterator.__next__()
    for _ in range(3):
        var stopped = False
        try:
            _ = iterator.__next__()
        except StopIteration:
            stopped = True
        assert_true(stopped)


def test_reversed_ranges_inside_same_frame_are_empty() raises:
    var start = Morrow(2024, 1, 1, 12)
    var end = Morrow(2024, 1, 1, 10)
    assert_equal(len(Morrow.range("day", start, end)), 0)
    assert_equal(len(Morrow.span_range("day", start, end)), 0)
    assert_equal(len(Morrow.interval("day", start, end)), 0)


def test_zero_limits_for_all_range_types() raises:
    var start = Morrow(2024, 1, 1)
    var end = start.shift(days=5)
    assert_equal(len(Morrow.range("day", start, end, limit=0)), 0)
    assert_equal(len(Morrow.span_range("day", start, end, limit=0)), 0)
    assert_equal(len(Morrow.interval("day", start, end, limit=0)), 0)


def test_invalid_iterator_configuration() raises:
    var dt = Morrow(2024, 1, 1)
    with assert_raises():
        _ = Morrow.iter_range("invalid", dt, limit=1)
    with assert_raises():
        _ = Morrow.iter_span_range("day", dt, dt, bounds="🌙")
    with assert_raises():
        _ = Morrow.iter_interval("day", dt, dt, interval=0)
    with assert_raises():
        _ = Morrow.iter_interval("day", dt, dt, interval=-1)
    with assert_raises():
        _ = Morrow.iter_span_range("week", dt, dt, week_start=0)


def test_lazy_and_eager_points_agree_across_frames() raises:
    var start = Morrow(2024, 1, 31, 12)
    var end = Morrow(2025, 5, 1)
    var frames: List[String] = [
        "year",
        "quarter",
        "month",
        "week",
        "day",
        "hour",
        "minute",
        "second",
        "microsecond",
    ]
    for frame in frames:
        var points = Morrow.range(frame, start, end, limit=4)
        var i = 0
        for point in Morrow.iter_range(frame, start, end, limit=4):
            assert_date(point, points[i])
            i += 1
        assert_equal(i, len(points))


def test_exact_spans_clip_final_end() raises:
    var start = Morrow(2024, 1, 1, 12)
    var end = Morrow(2024, 1, 3, 6)
    var spans = Morrow.span_range("day", start, end, exact=True)
    assert_equal(len(spans), 2)
    assert_date(spans[0].start, start)
    assert_date(spans[1].end, end.shift(microseconds=-1))
    assert_date(spans[0].end.shift(microseconds=1), spans[1].start)


def test_interval_retains_final_partial_group() raises:
    var start = Morrow(2024, 1, 1)
    var end = Morrow(2024, 1, 6)
    var spans = Morrow.interval("day", start, end, interval=2, exact=True)
    assert_equal(len(spans), 3)
    assert_date(spans[2].start, Morrow(2024, 1, 5))
    assert_date(spans[2].end, end.shift(microseconds=-1))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
