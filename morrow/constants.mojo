# todo: hardcode for tmp
alias _MAX_TIMESTAMP: Int = 32503737600
alias MAX_TIMESTAMP = _MAX_TIMESTAMP
alias MAX_TIMESTAMP_MS = MAX_TIMESTAMP * 1000
alias MAX_TIMESTAMP_US = MAX_TIMESTAMP * 1_000_000

alias _DAYS_IN_MONTH = VariadicList[Int](
    -1, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
)
alias _DAYS_BEFORE_MONTH = VariadicList[Int](
    -1, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334
)  # -1 is a placeholder for indexing purposes.
