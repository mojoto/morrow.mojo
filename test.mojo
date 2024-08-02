from testing import assert_equal, assert_true

from morrow._libc import c_gettimeofday
from morrow._py import py_dt_datetime, py_time
from morrow import Morrow
from morrow import TimeZone
from morrow import TimeDelta


def assert_datetime_equal(dt: Morrow, py_dt: PythonObject):
    assert_true(
        dt.year == int(py_dt.year)
        and dt.month == int(py_dt.month)
        and dt.hour == int(py_dt.hour)
        and dt.minute == int(py_dt.minute)
        and dt.second == int(py_dt.second),
        "dt: " + str(dt) + " is not equal to py_dt: " + str(py_dt),
    )


def test_now():
    print("Running test_now()")
    var result = Morrow.now()
    assert_datetime_equal(result, py_dt_datetime().now())


def test_utcnow():
    print("Running test_utcnow()")
    var result = Morrow.utcnow()
    assert_datetime_equal(result, py_dt_datetime().utcnow())


def test_fromtimestamp():
    print("Running test_fromtimestamp()")
    var t = c_gettimeofday()
    var result = Morrow.fromtimestamp(t.tv_sec)
    assert_datetime_equal(result, py_dt_datetime().now())


def test_utcfromtimestamp():
    print("Running test_utcfromtimestamp()")
    var t = c_gettimeofday()
    var result = Morrow.utcfromtimestamp(t.tv_sec)
    assert_datetime_equal(result, py_dt_datetime().utcnow())


def test_iso_format():
    print("Running test_iso_format()")
    var d0 = Morrow(2023, 10, 1, 0, 0, 0, 1234)
    assert_equal(d0.isoformat(), "2023-10-01T00:00:00.001234")
    assert_equal(d0.isoformat(timespec="seconds"), "2023-10-01T00:00:00")
    assert_equal(d0.isoformat(timespec="milliseconds"), "2023-10-01T00:00:00.001")

    # with TimeZone
    var d1 = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, "Beijing"))
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
    m = Morrow.strptime("20-01-2023 15:49:10", "%d-%m-%Y %H:%M:%S", TimeZone.none())
    assert_equal(str(m), "2023-01-20T15:49:10.000000+00:00")

    m = Morrow.strptime("2023-10-18 15:49:10 +0800", "%Y-%m-%d %H:%M:%S %z")
    assert_equal(str(m), "2023-10-18T15:49:10.000000+08:00")

    m = Morrow.strptime("2023-10-18 15:49:10", "%Y-%m-%d %H:%M:%S", "+09:00")
    assert_equal(str(m), "2023-10-18T15:49:10.000000+09:00")


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
    assert_equal(str(result), "0:00:00000001")

    result = Morrow(2023, 10, 1, 10, 0, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 1)
    assert_equal(str(result), "0:00:01")

    result = Morrow(2023, 10, 1, 10, 1, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 60)
    assert_equal(str(result), "0:01:00")

    result = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 1)
    assert_equal(str(result), "1 day, 0:00:00")

    result = Morrow(2023, 10, 3, 10, 1, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 2)
    assert_equal(str(result), "2 days, 0:01:01")


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
        str(
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


def test_from_to_py():
    print("Running test_from_to_py()")
    m = Morrow.now()
    dt = m.to_py()
    assert_datetime_equal(m, dt)

    m2 = Morrow.from_py(dt)
    assert_datetime_equal(m2, dt)


def test_format():
    print("Running test_format()")
    var m = Morrow(2024, 2, 1, 3, 4, 5, 123456)
    assert_equal(
        m.format("YYYY-MM-DD HH:mm:ss.SSS ZZ"), "2024-02-01 03:04:05.123 +00:00"
    )
    assert_equal(m.format("Y-YY-YYY-YYYY M-MM D-DD"), "Y-24--2024 2-02 1-01")
    assert_equal(m.format("H-HH-h-hh m-mm s-ss"), "3-03-3-03 4-04 5-05")
    assert_equal(m.format("S-SS-SSS-SSSS-SSSSS-SSSSSS"), "1-12-123-1234-12345-123456")
    assert_equal(m.format("d-dd-ddd-dddd"), "4--Thu-Thursday")
    assert_equal(m.format("YYYY[Y] [[]MM[]][M]"), "2024Y [02]M")


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
    test_from_to_py()
    test_format()
