from testing import assert_equal, assert_true

from morrow._libc import c_gettimeofday
from morrow._py import py_dt_datetime, py_time
from morrow import Morrow
from morrow import TimeZone
from morrow import TimeDelta


def assert_datetime_equal(dt: Morrow, py_dt: PythonObject):
    assert_true(
        dt.year == py_dt.year.to_float64().to_int()
        and dt.month == py_dt.month.to_float64().to_int()
        and dt.hour == py_dt.hour.to_float64().to_int()
        and dt.minute == py_dt.minute.to_float64().to_int()
        and dt.second == py_dt.second.to_float64().to_int(),
        "dt: " + dt.__str__() + " is not equal to py_dt: " + py_dt.to_string(),
    )


def test_now():
    print("Running test_now()")
    let result = Morrow.now()
    assert_datetime_equal(result, py_dt_datetime().now())


def test_utcnow():
    print("Running test_utcnow()")
    let result = Morrow.utcnow()
    assert_datetime_equal(result, py_dt_datetime().utcnow())


def test_fromtimestamp():
    print("Running test_fromtimestamp()")
    let t = c_gettimeofday()
    let result = Morrow.fromtimestamp(t.tv_sec)
    assert_datetime_equal(result, py_dt_datetime().now())


def test_utcfromtimestamp():
    print("Running test_utcfromtimestamp()")
    let t = c_gettimeofday()
    let result = Morrow.utcfromtimestamp(t.tv_sec)
    assert_datetime_equal(result, py_dt_datetime().utcnow())


def test_iso_format():
    print("Running test_iso_format()")
    let d0 = Morrow(2023, 10, 1, 0, 0, 0, 1234)
    assert_equal(d0.isoformat(), "2023-10-01T00:00:00.001234")
    assert_equal(d0.isoformat(timespec="seconds"), "2023-10-01T00:00:00")
    assert_equal(d0.isoformat(timespec="milliseconds"), "2023-10-01T00:00:00.001")

    # with TimeZone
    let d1 = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, "Beijing"))
    assert_equal(d1.isoformat(timespec="seconds"), "2023-10-01T00:00:00+08:00")


def test_time_zone():
    print("Running test_time_zone()")
    assert_equal(TimeZone.from_utc("UTC+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC0800").offset, 28800)
    assert_equal(TimeZone.from_utc("+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("08").offset, 28800)


def test_strptime():
    print("Running test_strptime()")
    m = Morrow.strptime("20-01-2023 15:49:10", "%d-%m-%Y %H:%M:%S", TimeZone.local())
    assert_equal(m.__str__(), "2023-01-20T15:49:10.000000+08:00")

    m = Morrow.strptime("2023-10-18 15:49:10 +08:00", "%Y-%m-%d %H:%M:%S %z")
    assert_equal(m.__str__(), "2023-10-18T15:49:10.000000+08:00")

    m = Morrow.strptime("2023-10-18 15:49:10", "%Y-%m-%d %H:%M:%S", "+09:00")
    assert_equal(m.__str__(), "2023-10-18T15:49:10.000000+09:00")

def test_ordinal():
    print("Running test_ordinal()")
    m = Morrow(2023, 10, 1)
    o = m.toordinal()
    assert_equal(o, 738794)

    m2 = Morrow.fromordinal(o)
    assert_equal(m2.year, 2023)
    assert_equal(m.month, 10)
    assert_equal(m.day, 1)


def test_sub():
    print("Running test_sub()")
    var result = Morrow(2023, 10, 1, 10, 0, 0, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.microseconds, 1)
    assert_equal(result.__str__(), "0:00:00000001")

    result = Morrow(2023, 10, 1, 10, 0, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 1)
    assert_equal(result.__str__(), "0:00:01")

    result = Morrow(2023, 10, 1, 10, 1, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 60)
    assert_equal(result.__str__(), "0:01:00")

    result = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 1)
    assert_equal(result.__str__(), "1 day, 0:00:00")

    result = Morrow(2023, 10, 3, 10, 1, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 2)
    assert_equal(result.__str__(), "2 days, 0:01:01")


def test_timedelta():
    print("Running test_timedelta()")
    assert_equal(TimeDelta(3, 2, 100).total_seconds(), 259202.0001)
    assert_true(
        TimeDelta(2, 1, 50).__add__(TimeDelta(1, 1, 50)).__eq__(TimeDelta(3, 2, 100))
    )
    assert_true(
        TimeDelta(3, 2, 100).__sub__(TimeDelta(2, 1, 50)).__eq__(TimeDelta(1, 1, 50))
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
        TimeDelta(
            weeks=100,
            days=100,
            hours=100,
            minutes=100,
            seconds=100,
            microseconds=10000000,
            milliseconds=10000000000,
        ).__str__(),
        "919 days, 23:28:30",
    )


def main():
    test_now()
    test_utcnow()
    test_fromtimestamp()
    test_utcfromtimestamp()
    test_iso_format()
    test_sub()
    test_time_zone()
    test_strptime()
    test_timedelta()
