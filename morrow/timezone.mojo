from .util import num2str


@value
struct Timezone:
    var offset: Int
    var name: String

    fn __init__(inout self, offset: Int, name: String = ''):
        self.offset = offset
        self.name = name

    fn __str__(self) -> String:
        return self.name
 
    fn is_none(self) -> Bool:
        return self.name == 'None'

    fn format(self) -> String:
        let sign: String
        let offset_abs: Int
        if self.offset < 0:
            sign = '-'
            offset_abs = -self.offset
        else:
            sign = '+'
            offset_abs = self.offset
        let hh = offset_abs // 3600
        let mm = offset_abs % 3600
        return sign + num2str(hh, 2) + ":" + num2str(mm, 2)

