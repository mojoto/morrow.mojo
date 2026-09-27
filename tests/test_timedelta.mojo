from std.testing import assert_equal, assert_raises, assert_true, TestSuite

from morrow import TimeDelta
from morrow.timedelta import Max, Min, Resolution


def test_timedelta() raises:
    assert_equal(String(TimeDelta(microseconds=1)), "0:00:00.000001")
    assert_equal(String(TimeDelta(milliseconds=1)), "0:00:00.001000")
    assert_equal(String(TimeDelta(microseconds=-1)), "-1 day, 23:59:59.999999")

    assert_equal(TimeDelta(3, 2, 100).total_seconds(), 259202.0001)
    assert_true(
        TimeDelta(2, 1, 50)
        .__add__(TimeDelta(1, 1, 50))
        .__eq__(TimeDelta(3, 2, 100))
    )
    assert_true(
        TimeDelta(3, 2, 100)
        .__sub__(TimeDelta(2, 1, 50))
        .__eq__(TimeDelta(1, 1, 50))
    )
    assert_true(TimeDelta(3, 2, 100).__neg__().__eq__(TimeDelta(-3, -2, -100)))
    assert_true(TimeDelta(-3, -2, -100).__abs__().__eq__(TimeDelta(3, 2, 100)))
    assert_true(TimeDelta(1, 1, 50).__le__(TimeDelta(1, 1, 51)))
    assert_true(TimeDelta(1, 1, 50).__le__(TimeDelta(1, 1, 50)))
    assert_true(TimeDelta(1, 1, 50).__lt__(TimeDelta(1, 1, 51)))
    assert_true(not TimeDelta(1, 1, 50).__lt__(TimeDelta(1, 1, 50)))
    assert_true(TimeDelta(1, 1, 50).__ge__(TimeDelta(1, 1, 50)))
    assert_true(TimeDelta(1, 1, 50).__ge__(TimeDelta(1, 1, 49)))
    assert_true(not TimeDelta(1, 1, 50).__gt__(TimeDelta(1, 1, 50)))
    assert_true(TimeDelta(1, 1, 50).__gt__(TimeDelta(1, 1, 49)))
    assert_equal(
        String(
            TimeDelta(
                weeks=100,
                days=100,
                hours=100,
                minutes=100,
                seconds=100,
                microseconds=10000000,
                milliseconds=10000000000,
            )
        ),
        "919 days, 23:28:30",
    )


def test_timedelta_public_operators() raises:
    var one_day = TimeDelta(days=1)
    var one_hour = TimeDelta(hours=1)

    assert_true(one_hour.__radd__(one_day).__eq__(TimeDelta(days=1, hours=1)))
    assert_true(one_hour.__rsub__(one_day).__eq__(TimeDelta(hours=23)))
    assert_true(one_hour.__pos__().__eq__(one_hour))

    assert_true(TimeDelta(seconds=90).__mul__(2).__eq__(TimeDelta(minutes=3)))
    assert_true(TimeDelta(seconds=90).__rmul__(2).__eq__(TimeDelta(minutes=3)))
    assert_true(
        TimeDelta(hours=2, minutes=5)
        .__mod__(TimeDelta(hours=1))
        .__eq__(TimeDelta(minutes=5))
    )

    assert_true(TimeDelta(seconds=1).__bool__())
    assert_true(TimeDelta(microseconds=1).__bool__())
    assert_true(not TimeDelta().__bool__())


def test_timedelta_module_constants() raises:
    assert_equal(Min.days, -99999999)
    assert_equal(Min.seconds, 0)
    assert_equal(Min.microseconds, 0)
    assert_equal(Max.days, 99999999)
    assert_equal(Max.seconds, 0)
    assert_equal(Max.microseconds, 0)
    assert_true(Resolution.__eq__(TimeDelta(microseconds=1)))


def test_timedelta_division_and_scaling() raises:
    var day = TimeDelta(days=1)
    assert_equal(day / TimeDelta(hours=1), 24.0)
    assert_equal(day // TimeDelta(hours=5), 4)
    assert_equal(TimeDelta(hours=-1) // TimeDelta(hours=5), -1)
    assert_true(day / 3 == TimeDelta(hours=8))
    assert_true(TimeDelta(microseconds=3) / 2 == TimeDelta(microseconds=2))
    assert_true(TimeDelta(microseconds=5) / 2 == TimeDelta(microseconds=2))
    assert_true(TimeDelta(microseconds=-3) / 2 == TimeDelta(microseconds=-2))
    assert_true(TimeDelta(microseconds=7) // 2 == TimeDelta(microseconds=3))
    assert_true(day * 1.5 == TimeDelta(hours=36))
    assert_true(0.5 * day == TimeDelta(hours=12))
    assert_true(TimeDelta(microseconds=1) * 0.5 == TimeDelta())
    assert_true(TimeDelta(microseconds=3) * 0.5 == TimeDelta(microseconds=2))
    assert_true(day / 4.0 == TimeDelta(hours=6))
    var parts = TimeDelta(hours=25).divmod(day)
    assert_equal(parts[0], 1)
    assert_true(parts[1] == TimeDelta(hours=1))
    assert_true(TimeDelta(seconds=1) != TimeDelta(seconds=2))
    with assert_raises(contains="division by zero"):
        _ = day / TimeDelta()
    with assert_raises(contains="division by zero"):
        _ = day // 0


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
