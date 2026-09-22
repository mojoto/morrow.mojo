"""Five reproducible samples; timings are informational, not a CI threshold."""
from std.time import perf_counter_ns
from morrow import Morrow, TimeZone


def report(name: String, sample: Int, started: Int, checksum: Int):
    print(name, sample, 1000, perf_counter_ns() - started, checksum, sep=",")


def main() raises:
    var base = Morrow(2024, 1, 1)
    var ny = TimeZone.from_name("America/New_York")
    print("case,sample,iterations,elapsed_ns,checksum")
    for sample in range(5):
        var checksum = 0
        var started = perf_counter_ns()
        for i in range(1000):
            checksum += base.shift(seconds=i).second
        report("utc_shift", sample, started, checksum)
        checksum = 0
        started = perf_counter_ns()
        for i in range(1000):
            var date = base.shift(days=i)
            checksum += Morrow.fromisoformat(date.isoformat()).day
        report("iso_round_trip", sample, started, checksum)
        checksum = 0
        started = perf_counter_ns()
        for i in range(1000):
            checksum += base.shift(days=i).to(ny).hour
        report("iana_conversion", sample, started, checksum)
        checksum = 0
        started = perf_counter_ns()
        for point in Morrow.iter_range("second", base, limit=1000):
            checksum += point.second
        report("lazy_range", sample, started, checksum)
