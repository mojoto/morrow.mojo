"""Built-in locale expectations; texts match Arrow 1.4.0 unless noted in docs."""
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from morrow import Morrow, Locale


def check(
    name: String,
    formatted: String,
    short: String,
    hours_ago: String,
    in_days: String,
    month_ago: String,
    in_years: String,
    multi: String,
) raises:
    var locale = Locale(name)
    var dt = Morrow(2024, 11, 5, 15, 4)
    var base = Morrow(2024, 1, 15, 12)
    assert_equal(
        dt.format("dddd, MMMM Do YYYY hh:mm A", locale=locale), formatted
    )
    assert_equal(
        dt.format("dddd, MMMM Do YYYY hh:mm A", locale=name), formatted
    )
    assert_equal(dt.format("ddd D MMM YY", locale=locale), short)
    var round_trip = dt.format("dddd, MMMM Do YYYY HH:mm", locale=locale)
    assert_true(
        Morrow.get(round_trip, "dddd, MMMM Do YYYY HH:mm", locale=locale) == dt
    )
    assert_equal(base.shift(hours=-2).humanize(base, locale=locale), hours_ago)
    assert_equal(base.shift(days=3).humanize(base, locale=name), in_days)
    assert_equal(base.shift(months=-1).humanize(base, locale=locale), month_ago)
    assert_equal(base.shift(years=2).humanize(base, locale=locale), in_years)
    var granularity: List[String] = ["hour", "minute"]
    assert_equal(
        base.shift(hours=1, minutes=6).humanize(
            base, granularity, locale=locale
        ),
        multi,
    )
    assert_true(
        base.dehumanize(hours_ago, locale=locale) == base.shift(hours=-2)
    )
    assert_true(base.dehumanize(in_days, locale=name) == base.shift(days=3))
    assert_true(base.dehumanize(multi, locale=locale) == base.shift(minutes=66))


def test_arrow_locales_0() raises:
    check(
        "af",
        "Dinsdag, November 5 2024 03:04 ",
        "Di 5 Nov 24",
        "2 ure gelede",
        "in 3 dae",
        "een maand gelede",
        "in 2 jaar",
        "in uur 6 minute",
    )
    check(
        "sq",
        "e martë, nëntor 5 2024 03:04 ",
        "mar 5 nën 24",
        "2 orë më parë",
        "në 3 ditë",
        "muaj më parë",
        "në 2 vjet",
        "në orë dhe 6 minuta",
    )
    check(
        "ar-tn",
        "الثلاثاء, نوفمبر 5 2024 03:04 ",
        "ثلاثاء 5 نوفمبر 24",
        "منذ ساعتين",
        "خلال 3 أيام",
        "منذ شهر",
        "خلال سنتين",
        "خلال ساعة 6 دقائق",
    )
    check(
        "am",
        "ማክሰኞ, ኖቬምበር 5ኛ 2024 03:04 ",
        "ሰ 5 ኖቬም 24",
        "ከ 2 ሰዓታት በፊት",
        "በ 3 ቀናት ውስጥ",
        "ከአንድ ወር በፊት",
        "በ 2 ዓመታት ውስጥ",
        "በአንድ ሰዓት እና በ 6 ደቂቃዎች ውስጥ",
    )
    check(
        "ar",
        "الثلاثاء, نوفمبر 5 2024 03:04 ",
        "ثلاثاء 5 نوفمبر 24",
        "منذ ساعتين",
        "خلال 3 أيام",
        "منذ شهر",
        "خلال سنتين",
        "خلال ساعة 6 دقائق",
    )
    check(
        "hy",
        "երեքշաբթի, նոյեմբեր 5 2024 03:04 պ.մ.",
        "երեք. 5 նոյեմբեր 24",
        "2 ժամ առաջ",
        "3 օրից",
        "ամիս առաջ",
        "2 տարինից",
        "ժամ Եվ 6 րոպեից",
    )
    check(
        "de-at",
        "Dienstag, November 5. 2024 03:04 ",
        "Di 5 Nov 24",
        "vor 2 Stunden",
        "in 3 Tagen",
        "vor einem Monat",
        "in 2 Jahren",
        "in einer Stunde und 6 Minuten",
    )
    check(
        "az",
        "Çərşənbə axşamı, Noyabr 5 2024 03:04 ",
        "Çax 5 Noy 24",
        "2 saat əvvəl",
        "3 gün sonra",
        "bir ay əvvəl",
        "2 il sonra",
        "bir saat 6 dəqiqə sonra",
    )
    check(
        "eu",
        "asteartea, azaroak 5 2024 03:04 ",
        "ar 5 aza 24",
        "duela 2 ordu",
        "3 egun",
        "duela hilabete bat",
        "2 urte",
        "ordu bat 6 minutu",
    )
    check(
        "be",
        "аўторак, лістапада 5 2024 03:04 ",
        "ат 5 ліст 24",
        "2 гадзіны таму",
        "праз 3 дні",
        "месяц таму",
        "праз 2 гады",
        "праз гадзіну 6 хвілін",
    )


def test_arrow_locales_1() raises:
    check(
        "bn",
        "মঙ্গলবার, নভেম্বর 5ম 2024 03:04 বিকাল",
        "মঙ্গল 5 নভে 24",
        "2 ঘণ্টা আগে",
        "3 দিন পরে",
        "এক মাস আগে",
        "2 বছর পরে",
        "এক ঘণ্টা 6 মিনিট পরে",
    )
    check(
        "pt-br",
        "Terça-feira, Novembro 5 2024 03:04 ",
        "Ter 5 Nov 24",
        "faz 2 horas",
        "em 3 dias",
        "faz um mês",
        "em 2 anos",
        "em uma hora e 6 minutos",
    )
    check(
        "bg",
        "вторник, ноември 5 2024 03:04 ",
        "вт 5 ноем 24",
        "2 часа назад",
        "напред 3 дни",
        "месец назад",
        "напред 2 години",
        "напред час 6 минути",
    )
    check(
        "ca",
        "dimarts, novembre 5 2024 03:04 ",
        "dt. 5 nov. 24",
        "Fa 2 hores",
        "En 3 dies",
        "Fa un mes",
        "En 2 anys",
        "En una hora i 6 minuts",
    )
    check(
        "hr",
        "utorak, studeni 5 2024 03:04 ",
        "ut 5 stud 24",
        "prije 2 sata",
        "za 3 dana",
        "prije mjesec",
        "za 2 godine",
        "za sat i 6 minuta",
    )
    check(
        "cs",
        "úterý, listopad 5 2024 03:04 ",
        "út 5 lis 24",
        "Před 2 hodinami",
        "Za 3 dny",
        "Před měsícem",
        "Za 2 roky",
        "Za hodinu 6 minut",
    )
    check(
        "da",
        "tirsdag, november 5. 2024 03:04 ",
        "tir 5 nov 24",
        "for 2 timer siden",
        "om 3 dage",
        "for en måned siden",
        "om 2 år",
        "om en time og 6 minutter",
    )
    check(
        "nl",
        "dinsdag, november 5 2024 03:04 ",
        "di 5 nov 24",
        "2 uur geleden",
        "over 3 dagen",
        "een maand geleden",
        "over 2 jaar",
        "over een uur 6 minuten",
    )
    check(
        "en",
        "Tuesday, November 5th 2024 03:04 PM",
        "Tue 5 Nov 24",
        "2 hours ago",
        "in 3 days",
        "a month ago",
        "in 2 years",
        "in an hour and 6 minutes",
    )
    check(
        "eo",
        "mardo, novembro 5a 2024 03:04 PTM",
        "mar 5 nov 24",
        "antaŭ 2 horoj",
        "post 3 tagoj",
        "antaŭ unu monato",
        "post 2 jaroj",
        "post un horo 6 minutoj",
    )


def test_arrow_locales_2() raises:
    check(
        "ee",
        "Teisipäev, November 5 2024 03:04 ",
        "Teis 5 Nov 24",
        "2 tundi tagasi",
        "3 päeva pärast",
        "üks kuu tagasi",
        "2 aasta pärast",
        "tunni aja ja 6 minuti pärast",
    )
    check(
        "fa",
        "سه شنبه, نوامبر 5 2024 03:04 بعد از ظهر",
        "سه شنبه 5 نوامبر 24",
        "2 ساعت قبل",
        "در 3 روز",
        "یک ماه قبل",
        "در 2 سال",
        "در یک ساعت 6 دقیقه",
    )
    check(
        "fi",
        "tiistai, marraskuu 5. 2024 03:04 ",
        "ti 5 marras 24",
        "2 tuntia sitten",
        "3 päivän kuluttua",
        "kuukausi sitten",
        "2 vuoden kuluttua",
        "tunnin 6 minuutin kuluttua",
    )
    check(
        "fr-ca",
        "mardi, novembre 5e 2024 03:04 ",
        "mar 5 nov 24",
        "il y a 2 heures",
        "dans 3 jours",
        "il y a un mois",
        "dans 2 ans",
        "dans une heure et 6 minutes",
    )
    check(
        "fr",
        "mardi, novembre 5e 2024 03:04 ",
        "mar 5 nov 24",
        "il y a 2 heures",
        "dans 3 jours",
        "il y a un mois",
        "dans 2 ans",
        "dans une heure et 6 minutes",
    )
    check(
        "ka",
        "სამშაბათი, ნოემბერი 5 2024 03:04 ",
        "სამშაბათი 5 ნოემბერი 24",
        "2 საათის წინ",
        "3 დღის შემდეგ",
        "თვის წინ",
        "2 წლის შემდეგ",
        "საათის და 6 წუთის შემდეგ",
    )
    check(
        "de",
        "Dienstag, November 5. 2024 03:04 ",
        "Di 5 Nov 24",
        "vor 2 Stunden",
        "in 3 Tagen",
        "vor einem Monat",
        "in 2 Jahren",
        "in einer Stunde und 6 Minuten",
    )
    check(
        "el",
        "Τρίτη, Νοεμβρίου 5 2024 03:04 ",
        "Τρι 5 Νοε 24",
        "πριν από 2 ώρες",
        "σε 3 ημέρες",
        "πριν από ένα μήνα",
        "σε 2 χρόνια",
        "σε μία ώρα και 6 λεπτά",
    )
    check(
        "he",
        "שלישי, נובמבר 5 2024 03:04 אחרי הצהריים",
        "ג׳ 5 נוב׳ 24",
        "לפני שעתיים",
        "בעוד 3 ימים",
        "לפני חודש",
        "בעוד שנתיים",
        "בעוד שעה ו־6 דקות",
    )
    check(
        "hi",
        "मंगलवार, नवंबर 5 2024 03:04 शाम",
        "मंगल 5 नवे 24",
        "2 घंटे पहले",
        "3 दिन बाद",
        "एक माह  पहले",
        "2 साल  बाद",
        "एक घंटा 6 मिनट  बाद",
    )


def test_arrow_locales_3() raises:
    check(
        "zh-hk",
        "星期二, 11月 5 2024 03:04 ",
        "二 5 11 24",
        "2小時前",
        "3天後",
        "1個月前",
        "2年後",
        "1小時 6分鐘後",
    )
    check(
        "hu",
        "kedd, november 5 2024 03:04 DU",
        "kedd 5 nov 24",
        "2 órával ezelőtt",
        "3 nap múlva",
        "egy hónappal ezelőtt",
        "2 év múlva",
        "egy óra 6 perc múlva",
    )
    check(
        "is",
        "þriðjudagur, nóvember 5 2024 03:04 e.h.",
        "þri 5 nóv 24",
        "fyrir 2 tímum síðan",
        "eftir 3 daga",
        "fyrir einum mánuði síðan",
        "eftir 2 ár",
        "eftir einn tíma 6 mínútur",
    )
    check(
        "id",
        "Selasa, November 5 2024 03:04 ",
        "Selasa 5 Nov 24",
        "2 jam yang lalu",
        "dalam 3 hari",
        "1 bulan yang lalu",
        "dalam 2 tahun",
        "dalam 1 jam dan 6 menit",
    )
    check(
        "it",
        "martedì, novembre 5º 2024 03:04 ",
        "mar 5 nov 24",
        "2 ore fa",
        "tra 3 giorni",
        "un mese fa",
        "tra 2 anni",
        "tra un'ora e 6 minuti",
    )
    check(
        "ja",
        "火曜日, 11月 5 2024 03:04 ",
        "火 5 11 24",
        "2時間前",
        "3日後",
        "1ヶ月前",
        "2年後",
        "1時間 6分後",
    )
    check(
        "kk",
        "Сейсенбі, Қараша 5 2024 03:04 ",
        "Сс 5 Қар 24",
        "2 сағат бұрын",
        "3 күн кейін",
        "бір ай бұрын",
        "2 жыл кейін",
        "бір сағат 6 минут кейін",
    )
    check(
        "ko",
        "화요일, 11월 다섯번째 2024 03:04 ",
        "화 5 11 24",
        "2시간 전",
        "글피",
        "한달 전",
        "내후년",
        "한시간 6분 후",
    )
    check(
        "lo",
        "ວັນອັງຄານ, ພະຈິກ 5 2567 03:04 ",
        "ວັນອັງຄານ 5 ພະຈິກ 67",
        "2 ຊົ່ວໂມງ ກ່ອນຫນ້ານີ້",
        "ໃນ 3 ມື້",
        "ເດືອນ ກ່ອນຫນ້ານີ້",
        "ໃນ 2 ປີ",
        "ໃນຊົ່ວໂມງ6ນາທີ",
    )
    check(
        "la",
        "dies Martis, November 5 2024 03:04 ",
        "dies Martis 5 Nov 24",
        "ante 2 horas",
        "in 3 dies",
        "ante mensem",
        "in 2 annos",
        "in horam et 6 minutis",
    )


def test_arrow_locales_4() raises:
    check(
        "lv",
        "otrdiena, novembris 5 2024 03:04 ",
        "ot 5 nov 24",
        "pirms 2 stundām",
        "pēc 3 dienām",
        "pirms mēneša",
        "pēc 2 gadiem",
        "pēc stundas un 6 minūtēm",
    )
    check(
        "ar-iq",
        "الثلاثاء, تشرين الثاني 5 2024 03:04 ",
        "ثلاثاء 5 تشرين الثاني 24",
        "منذ ساعتين",
        "خلال 3 أيام",
        "منذ شهر",
        "خلال سنتين",
        "خلال ساعة 6 دقائق",
    )
    check(
        "lt",
        "antradienis, lapkritis 5 2024 03:04 ",
        "an 5 lapkr 24",
        "prieš 2 valandų",
        "po 3 dienų",
        "prieš mėnesio",
        "po 2 metų",
        "po valandos ir 6 minučių",
    )
    check(
        "lb",
        "Dënschdeg, November 5. 2024 03:04 ",
        "Dën 5 Nov 24",
        "virun 2 Stonnen",
        "an 3 Deeg",
        "virun engem Mount",
        "an 2 Jahren",
        "an enger Stonn an 6 Minutten",
    )
    check(
        "mk-latn",
        "Vtornik, Noemvri 5 2024 03:04 popladne",
        "Vt 5 Noe 24",
        "pred 2 saati",
        "za 3 dena",
        "pred eden mesec",
        "za 2 godini",
        "za eden saat 6 minuti",
    )
    check(
        "mk",
        "Вторник, Ноември 5 2024 03:04 попладне",
        "Вт 5 Ноем 24",
        "пред 2 саати",
        "за 3 дена",
        "пред еден месец",
        "за 2 години",
        "за еден саат 6 минути",
    )
    check(
        "ms",
        "Selasa, November 5 2024 03:04 ",
        "Selasa 5 Nov. 24",
        "2 jam yang lalu",
        "dalam 3 hari",
        "bulan yang lalu",
        "dalam 2 tahun",
        "dalam jam dan 6 minit",
    )
    check(
        "ml",
        "ചൊവ്വ, നവംബർ 5 2024 03:04 ഉച്ചക്ക് ശേഷം",
        "ചൊവ്വ 5 നവം 24",
        "2 മണിക്കൂർ മുമ്പ്",
        "3 ദിവസം  ശേഷം",
        "ഒരു മാസം  മുമ്പ്",
        "2 വർഷം  ശേഷം",
        "ഒരു മണിക്കൂർ 6 മിനിറ്റ് ശേഷം",
    )
    check(
        "mt",
        "It-Tlieta, Novembru 5 2024 03:04 ",
        "TL 5 Nov 24",
        "2 sagħtejn ilu",
        "fi 3 ijiem",
        "xahar ilu",
        "fi 2 sentejn",
        "fi siegħa u 6 minuti",
    )
    check(
        "mr",
        "मंगळवार, नोव्हेंबर 5 2024 03:04 संध्याकाळ",
        "मंगळ 5 नोव्हें 24",
        "2 तास आधी",
        "3 दिवस नंतर",
        "एक महिना  आधी",
        "2 वर्ष  नंतर",
        "एक तास 6 मिनिट  नंतर",
    )


def test_arrow_locales_5() raises:
    check(
        "ar-mr",
        "الثلاثاء, نوفمبر 5 2024 03:04 ",
        "ثلاثاء 5 نوفمبر 24",
        "منذ ساعتين",
        "خلال 3 أيام",
        "منذ شهر",
        "خلال سنتين",
        "خلال ساعة 6 دقائق",
    )
    check(
        "ar-ma",
        "الثلاثاء, نونبر 5 2024 03:04 ",
        "ثلاثاء 5 نونبر 24",
        "منذ ساعتين",
        "خلال 3 أيام",
        "منذ شهر",
        "خلال سنتين",
        "خلال ساعة 6 دقائق",
    )
    check(
        "ne",
        "मंगलवार, नोवेम्बर 5 2024 03:04 अपरान्ह",
        "मंगल 5 नोव 24",
        "2 घण्टा पहिले",
        "3 दिन पछी",
        "एक महिना पहिले",
        "2 बर्ष पछी",
        "एक घण्टा 6 मिनेट पछी",
    )
    check(
        "nn",
        "tysdag, november 5. 2024 03:04 ",
        "ty 5 nov 24",
        "for 2 timar sidan",
        "om 3 dagar",
        "for ein månad sidan",
        "om 2 år",
        "om ein time 6 minutt",
    )
    check(
        "nb",
        "tirsdag, november 5. 2024 03:04 ",
        "ti 5 nov 24",
        "for 2 timer siden",
        "om 3 dager",
        "for en måned siden",
        "om 2 år",
        "om en time 6 minutter",
    )
    check(
        "or",
        "ମଙ୍ଗଳବାର, ନଭେମ୍ବର୍ 5ମ 2024 03:04 ଅପରାହ୍ନ",
        "ମଙ୍ଗଳ 5 ନଭେ 24",
        "2 ଘଣ୍ଟା ପୂର୍ବେ",
        "3 ଦିନ ପରେ",
        "ଏକ ମାସ ପୂର୍ବେ",
        "2 ବର୍ଷ ପରେ",
        "ଏକ ଘଣ୍ଟା 6 ମିନଟ ପରେ",
    )
    check(
        "pl",
        "wtorek, listopad 5 2024 03:04 ",
        "Wt 5 lis 24",
        "2 godziny temu",
        "za 3 dni",
        "miesiąc temu",
        "za 2 lata",
        "za godzinę 6 minut",
    )
    check(
        "pt",
        "Terça-feira, Novembro 5 2024 03:04 ",
        "Ter 5 Nov 24",
        "há 2 horas",
        "em 3 dias",
        "há um mês",
        "em 2 anos",
        "em uma hora e 6 minutos",
    )
    check(
        "ro",
        "marți, noiembrie 5 2024 03:04 ",
        "Mar 5 nov 24",
        "2 ore în urmă",
        "peste 3 zile",
        "o lună în urmă",
        "peste 2 ani",
        "peste o oră și 6 minute",
    )
    check(
        "rm",
        "mardi, november 5 2024 03:04 ",
        "ma 5 nov 24",
        "avant 2 ura",
        "en 3 dis",
        "avant in mais",
        "en 2 onns",
        "en in'ura 6 minutas",
    )


def test_arrow_locales_6() raises:
    check(
        "ru",
        "вторник, ноября 5 2024 03:04 ",
        "вт 5 ноя 24",
        "2 часа назад",
        "через 3 дня",
        "месяц назад",
        "через 2 года",
        "через час 6 минут",
    )
    check(
        "se",
        "Disdat, Skábmamánnu 5 2024 03:04 ",
        "Disdat 5 Skábmamánnu 24",
        "2 diimmu dassái",
        "3 beaivvi ",
        "mánu dassái",
        "2 jagi ",
        "diimmu 6 minuhta ",
    )
    check(
        "sr",
        "utorak, novembar 5 2024 03:04 ",
        "ut 5 nov 24",
        "pre 2 sata",
        "za 3 dana",
        "pre mesec",
        "za 2 godine",
        "za sat i 6 minuta",
    )
    check(
        "si",
        "අඟහරැවදා, නොවැම්බර් 5 2024 03:04 ",
        "බදා 5 නොවැ 24",
        "පැය 2 කට පෙර",
        "දින 3 කින්",
        "මාසයකට පෙර",
        "අවුරුදු 2 තුළ",
        "පැයකින් සහ මිනිත්තු 6 කින්",
    )
    check(
        "sk",
        "utorok, november 5 2024 03:04 ",
        "ut 5 nov 24",
        "Pred 2 hodinami",
        "O 3 dni",
        "Pred mesiacom",
        "O 2 roky",
        "O hodinu a 6 minút",
    )
    check(
        "sl",
        "Torek, November 5 2024 03:04 ",
        "Tor 5 Nov 24",
        "pred 2 ur",
        "čez 3 dni",
        "pred mesec",
        "čez 2 let",
        "čez uro in 6 minutami",
    )
    check(
        "es",
        "martes, noviembre 5º 2024 03:04 PM",
        "mar 5 nov 24",
        "hace 2 horas",
        "en 3 días",
        "hace un mes",
        "en 2 años",
        "en una hora y 6 minutos",
    )
    check(
        "sw",
        "Jumanne, Novemba 5 2024 03:04 MCH",
        "Jumanne 5 Nov 24",
        "saa 2 iliyopita",
        "muda wa siku 3",
        "mwezi moja iliyopita",
        "muda wa miaka 2",
        "muda wa saa moja na dakika 6",
    )
    check(
        "sv",
        "tisdag, november 5 2024 03:04 ",
        "tis 5 nov 24",
        "för 2 timmar sen",
        "om 3 dagar",
        "för en månad sen",
        "om 2 år",
        "om en timme och 6 minuter",
    )
    check(
        "de-ch",
        "Dienstag, November 5. 2024 03:04 ",
        "Di 5 Nov 24",
        "vor 2 Stunden",
        "in 3 Tagen",
        "vor einem Monat",
        "in 2 Jahren",
        "in einer Stunde und 6 Minuten",
    )


def test_arrow_locales_7() raises:
    check(
        "tl",
        "Martes, Nobyembre ika-5 2024 03:04 ng hapon",
        "Mar 5 Nob 24",
        "nakaraang 2 oras",
        "3 araw mula ngayon",
        "nakaraang isang buwan",
        "2 taon mula ngayon",
        "isang oras 6 minuto mula ngayon",
    )
    check(
        "ta",
        "செவ்வாய்க்கிழமை, மாசி 5ஆம் 2024 03:04 ",
        "செவ்வாய் 5 நவ 24",
        "2 மணிநேரம் நேரத்திற்கு முன்பு",
        "இல் 3 நாட்கள்",
        "ஒரு மாதம் நேரத்திற்கு முன்பு",
        "இல் 2 ஆண்டுகள்",
        "இல் ஒரு மணி 6 நிமிடங்கள்",
    )
    check(
        "th",
        "วันอังคาร, พฤศจิกายน 5 2567 03:04 PM",
        "อ. 5 พ.ย. 67",
        "2 ชั่วโมง ที่ผ่านมา",
        "ในอีก 3 วัน",
        "เดือน ที่ผ่านมา",
        "ในอีก 2 ปี",
        "ในอีกชั่วโมง6นาที",
    )
    check(
        "tr",
        "Salı, Kasım 5 2024 03:04 ÖS",
        "Sal 5 Kas 24",
        "2 saat önce",
        "3 gün sonra",
        "bir ay önce",
        "2 yıl sonra",
        "bir saat ve 6 dakika sonra",
    )
    check(
        "ua",
        "вівторок, листопада 5 2024 03:04 ",
        "вт 5 лист 24",
        "2 години тому",
        "за 3 дні",
        "місяць тому",
        "за 2 роки",
        "за годину 6 хвилин",
    )
    check(
        "ur",
        "منگل, نومبر 5 2024 03:04 ",
        "منگل 5 نومبر 24",
        "پہلے 2 گھنٹے",
        "میں 3 دن",
        "پہلے ایک مہینہ",
        "میں 2 سال",
        "میں ایک گھنٹے اور 6 منٹ",
    )
    check(
        "uz",
        "Seshanba, Noyabr 5 2024 03:04 ",
        "Sesh 5 Noy 24",
        "2 soatdan avval",
        "3 kundan keyin",
        "bir oydan avval",
        "2 yildan keyin",
        "bir soat 6 daqiqadan keyin",
    )
    check(
        "vi",
        "Thứ Ba, Tháng Mười Một 5 2024 03:04 ",
        "Thứ 3 5 Tháng 11 24",
        "2 giờ trước",
        "3 ngày nữa",
        "một tháng trước",
        "2 năm nữa",
        "một giờ 6 phút nữa",
    )
    check(
        "zu",
        "uLwesibili, uLwezi 5 2024 03:04 ",
        "uLwesibili 5 uLwezi 24",
        "2 amahora edlule",
        "3 ezinsukwini ",
        "inyanga edlule",
        "2 eminyakeni ",
        "ngehora futhi 6 ngemizuzu ",
    )


def unit_shift(base: Morrow, unit: String, n: Int) raises -> Morrow:
    if unit == "second":
        return base.shift(seconds=n)
    if unit == "minute":
        return base.shift(minutes=n)
    if unit == "hour":
        return base.shift(hours=n)
    if unit == "day":
        return base.shift(days=n)
    if unit == "week":
        return base.shift(weeks=n)
    if unit == "month":
        return base.shift(months=n)
    if unit == "quarter":
        return base.shift(quarters=n)
    return base.shift(years=n)


def test_every_locale_dehumanizes_its_own_text() raises:
    var base = Morrow(2024, 1, 15, 12)
    var units: List[String] = [
        "second",
        "minute",
        "hour",
        "day",
        "week",
        "month",
        "quarter",
        "year",
    ]
    var counts: List[Int] = [1, 2, 3, 4, 5, 10, 11, 12, 21, 22, 25, 111]
    var checked = 0
    for name in Locale.available():
        var locale = Locale(name)
        assert_true(
            base.dehumanize(locale.describe("now"), locale=locale) == base
        )
        for unit in units:
            for count in counts:
                var frame = unit if count == 1 else unit + "s"
                # Icelandic says "a few seconds" in the future, without a count.
                if not locale.has_timeframe(frame) or (
                    name == "is" and frame == "seconds"
                ):
                    continue
                for sign in [1, -1]:
                    var text = locale.describe(frame, count * sign)
                    var shifted = base.dehumanize(text, locale=locale)
                    if not (shifted == unit_shift(base, unit, count * sign)):
                        raise Error(
                            name + ": " + text + " -> " + String(shifted)
                        )
                    checked += 1
    assert_true(checked > 10000)


def test_locale_names_and_errors() raises:
    var names = Locale.available()
    assert_equal(len(names), 81)
    assert_equal(Locale("FR_ca").name, "fr-ca")
    assert_equal(Locale("EN-gb").name, "en")
    assert_equal(Locale("zh-Hant").name, "zh-tw")
    assert_equal(Locale("zh_HK").name, "zh-hk")
    assert_true(len(Locale.aliases("ar")) > 10)
    with assert_raises(contains="unsupported locale"):
        _ = Locale("xx")
    var base = Morrow(2024, 1, 15, 12)
    with assert_raises(contains="not translated"):
        _ = base.shift(months=4).humanize(
            base, granularity="quarter", locale="fr"
        )
    with assert_raises(contains="zero delta"):
        _ = Locale("is").describe("minutes", 0)


def test_missing_week_text_falls_back_to_days() raises:
    var base = Morrow(2024, 1, 15, 12)
    var locale = Locale("ro")
    assert_true(not locale.has_timeframe("weeks"))
    var text = base.shift(days=10).humanize(base, locale=locale)
    assert_equal(text, locale.describe("days", 10))
    assert_true(base.dehumanize(text, locale=locale) == base.shift(days=10))


def test_custom_locale() raises:
    var locale = Locale("en")
    locale.name = "en-pirate"
    locale.month_names[0] = "Janarrr"
    locale.day_abbreviations[0] = "Mun"
    locale.meridians = ["ay", "pee", "AY", "PEE"]
    locale.set_timeframe("hours", "{0} bells")
    locale.past = "{0} back"
    var dt = Morrow(2024, 1, 1, 15)
    assert_equal(dt.format("ddd MMMM D A", locale=locale), "Mun Janarrr 1 PEE")
    assert_true(
        Morrow.get("Janarrr 1 2024 03 PEE", "MMMM D YYYY hh A", locale=locale)
        == dt
    )
    assert_equal(dt.shift(hours=-3).humanize(dt, locale=locale), "3 bells back")
    assert_true(
        dt.dehumanize("3 bells back", locale=locale) == dt.shift(hours=-3)
    )
    var keys: List[String] = ["singular", "dual", "plural"]
    var forms: List[String] = ["{0} dzień", "{0} dni", "{0} dni"]
    locale.plural_rule = "slavic"
    locale.set_timeframe("days", keys, forms)
    assert_equal(locale.describe("days", 21, only_distance=True), "21 dzień")


def test_buddhist_era_years_round_trip() raises:
    var dt = Morrow(2024, 3, 9)
    assert_equal(dt.format("YYYY YY", locale="th"), "2567 67")
    assert_true(Morrow.get("9 มีนาคม 2567", "D MMMM YYYY", locale="th") == dt)
    assert_true(Morrow.get("9 มีนาคม 67", "D MMMM YY", locale="th") == dt)


def test_special_relative_words() raises:
    var base = Morrow(2024, 1, 15, 12)
    assert_equal(base.shift(days=-1).humanize(base, locale="ko"), "어제")
    assert_true(base.dehumanize("어제", locale="ko") == base.shift(days=-1))
    assert_equal(base.shift(years=1).humanize(base, locale="ko"), "내년")
    assert_equal(
        base.shift(seconds=30).humanize(base, locale="th"), "ในอีก30วินาที"
    )
    assert_true(
        base.dehumanize("ในอีก30วินาที", locale="th") == base.shift(seconds=30)
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
