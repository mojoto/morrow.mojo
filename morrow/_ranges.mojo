"""Lazy iterators behind Morrow.range, span_range and interval."""

from std.iter import StopIteration

from ._values import MorrowSpan
from .morrow import Morrow, _UNBOUNDED_LIMIT


struct MorrowIterator(Copyable, ImplicitlyCopyable, Movable):
    """A constant-memory iterator over calendar points."""

    var frame: String
    var current: Morrow
    var end: Morrow
    var remaining: Int
    var original_day: Int
    var started: Bool

    def __init__(
        out self, frame: String, start: Morrow, end: Morrow, limit: Int
    ) raises:
        start._check_awareness(end)
        _ = start._floor_frame(frame)
        self.frame = frame
        self.current = start
        self.end = end
        self.remaining = limit
        self.original_day = start.day
        self.started = False

    def __iter__(self) -> Self:
        return self

    def __next__(mut self) raises -> Morrow:
        if self.remaining != _UNBOUNDED_LIMIT and self.remaining <= 0:
            raise StopIteration()
        if self.started:
            if self.current >= self.end:
                raise StopIteration()
            self.current = self.current._shift_frame_preserving_day(
                self.frame, 1, self.original_day
            )
        if self.current > self.end:
            raise StopIteration()
        self.started = True
        if self.remaining != _UNBOUNDED_LIMIT:
            self.remaining -= 1
        return self.current


struct MorrowSpanIterator(Copyable, ImplicitlyCopyable, Movable):
    """A constant-memory iterator over bounded calendar spans."""

    var frame: String
    var current: Morrow
    var end: Morrow
    var step: Int
    var remaining: Int
    var bounds: String
    var exact: Bool
    var week_start: Int
    var original_day: Int
    var started: Bool

    def __init__(
        out self,
        frame: String,
        start: Morrow,
        end: Morrow,
        step: Int,
        limit: Int,
        bounds: String,
        exact: Bool,
        week_start: Int,
    ) raises:
        if step < 1:
            raise Error("interval must be greater than 0")
        Morrow._validate_bounds(bounds)
        start._check_awareness(end)
        var floor = start._floor_frame(frame, week_start)
        self.frame = frame
        self.current = start if exact else floor
        self.end = end
        self.step = step
        self.remaining = 0 if start > end else limit
        self.bounds = bounds
        self.exact = exact
        self.week_start = week_start
        self.original_day = start.day
        self.started = False

    def __iter__(self) -> Self:
        return self

    def __next__(mut self) raises -> MorrowSpan:
        if self.remaining != _UNBOUNDED_LIMIT and self.remaining <= 0:
            raise StopIteration()
        if self.started:
            if self.exact:
                self.current = self.current._shift_frame_preserving_day(
                    self.frame, self.step, self.original_day
                )
            else:
                self.current = self.current._shift_frame(self.frame, self.step)
        var end_key = self.end._utc_microseconds()
        var key = self.current._utc_microseconds()
        if key > end_key or (self.exact and key == end_key):
            raise StopIteration()
        var span = self.current.span(
            self.frame,
            count=self.step,
            bounds=self.bounds,
            exact=self.exact,
            week_start=self.week_start,
        )
        if self.exact:
            var start_key = span.start._utc_microseconds()
            if start_key == end_key or start_key - 1 == end_key:
                raise StopIteration()
            if span.end._utc_microseconds() > end_key:
                span.end = self.end
                if Int(self.bounds.as_bytes()[1]) == ord(")"):
                    span.end = span.end.shift(microseconds=-1)
        self.started = True
        if self.remaining != _UNBOUNDED_LIMIT:
            self.remaining -= 1
        return span


struct MorrowIntervalIterator(Copyable, ImplicitlyCopyable, Movable):
    """Group spans without materializing the underlying range."""

    var spans: MorrowSpanIterator
    var group: Int
    var remaining: Int

    def __init__(
        out self,
        frame: String,
        start: Morrow,
        end: Morrow,
        interval: Int,
        limit: Int,
        bounds: String,
        exact: Bool,
        week_start: Int,
    ) raises:
        if interval < 1:
            raise Error("interval must be greater than 0")
        self.spans = MorrowSpanIterator(
            frame,
            start,
            end,
            1 if exact else interval,
            _UNBOUNDED_LIMIT,
            bounds,
            exact,
            week_start,
        )
        self.group = interval if exact else 1
        self.remaining = limit

    def __iter__(self) -> Self:
        return self

    def __next__(mut self) raises -> MorrowSpan:
        if self.remaining != _UNBOUNDED_LIMIT and self.remaining <= 0:
            raise StopIteration()
        var span = self.spans.__next__()
        for _ in range(1, self.group):
            try:
                span.end = self.spans.__next__().end
            except StopIteration:
                break
        if self.remaining != _UNBOUNDED_LIMIT:
            self.remaining -= 1
        return span
