from std.python import Python, PythonObject


fn py_dt_datetime() raises -> PythonObject:
    """
    Import and return the datetime class from Python's datetime module.
    """
    var _datetime = Python.import_module("datetime")
    return _datetime.datetime


fn py_time() raises -> PythonObject:
    """
    Import and return the time module from Python.
    """
    var _time = Python.import_module("time")
    return _time
