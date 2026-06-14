from std.testing import assert_equal, assert_true, TestSuite

from morrow import TimeDelta


def test_timedelta() raises:
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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
