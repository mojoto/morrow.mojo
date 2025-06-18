# TODO (Mikhail): Time zones are very hacky right now. Eventually, I will try adopting Martin's datetime module in `forge-tools` instead.
import small_time.c

alias UTC = "UTC"
alias DASH = "-"
alias PLUS = "+"
alias COLON = ":"


fn _is_numeric(c: Byte) -> Bool:
    """Checks if a character is numeric.
    
    Args:
        c: Character.

    Returns:
        True if the character is numeric, False otherwise.
    """
    return c >= ord("0") and c <= ord("9")


fn from_utc(timestamp: StringSlice) raises -> TimeZone:
    """Creates a timezone from a string.

    Args:
        timestamp: UTC string.

    Returns:
        Timezone.

    Raises:
        Error: If the UTC string is invalid.
    """
    if len(timestamp) == 0:
        raise Error("Received empty UTC string.")

    if timestamp == "utc" or timestamp == "UTC" or timestamp == "Z":
        return TimeZone.UTC

    var i = 0
    # Skip the UTC prefix.
    if len(timestamp) > 3 and timestamp[0:3] == UTC:
        i = 3

    var sign = -1 if timestamp[i] == DASH else 1
    if timestamp[i] == PLUS or timestamp[i] == DASH:
        i += 1

    if len(timestamp) < i + 2 or not _is_numeric(ord(timestamp[i])) or not _is_numeric(ord(timestamp[i + 1])):
        raise Error("Received invalid UTC string format.")
    var hours = atol(timestamp[i : i + 2])
    i += 2

    var minutes: Int
    if len(timestamp) <= i:
        minutes = 0
    elif len(timestamp) == i + 3 and timestamp[i] == COLON:
        minutes = atol(timestamp[i + 1 : i + 3])
    elif len(timestamp) == i + 2 and _is_numeric(ord(timestamp[i])):
        minutes = atol(timestamp[i : i + 2])
    else:
        raise Error("`timestamp` format is invalid")

    var offset = sign * (hours * 3600 + minutes * 60)
    return TimeZone.from_utc_offset(offset)


@fieldwise_init
struct TimeZone(Movable, Copyable, ExplicitlyCopyable):
    var name: String
    """Time zone name."""
    var offset: Int
    """Offset in seconds."""
    alias ASIA_JAKARTA = Self(name="Asia/Jakarta", offset=0)
    alias LIBYA = Self(name="Libya", offset=0)
    alias AMERICA_IQALUIT = Self(name="America/Iqaluit", offset=0)
    alias AMERICA_INDIANA_VEVAY = Self(name="America/Indiana/Vevay", offset=0)
    alias ATLANTIC_SOUTH_GEORGIA = Self(name="Atlantic/South_Georgia", offset=0)
    alias AMERICA_CUIABA = Self(name="America/Cuiaba", offset=0)
    alias EUROPE_TALLINN = Self(name="Europe/Tallinn", offset=0)
    alias AMERICA_ENSENADA = Self(name="America/Ensenada", offset=0)
    alias AFRICA_ABIDJAN = Self(name="Africa/Abidjan", offset=0)
    alias PACIFIC_SAIPAN = Self(name="Pacific/Saipan", offset=0)
    alias MEXICO_GENERAL = Self(name="Mexico/General", offset=0)
    alias EUROPE_ROME = Self(name="Europe/Rome", offset=0)
    alias ASIA_SEOUL = Self(name="Asia/Seoul", offset=0)
    alias US_MICHIGAN = Self(name="US/Michigan", offset=0)
    alias AMERICA_NEW_YORK = Self(name="America/New_York", offset=0)
    alias EUROPE_ATHENS = Self(name="Europe/Athens", offset=0)
    alias EUROPE_LISBON = Self(name="Europe/Lisbon", offset=0)
    alias AMERICA_ST_THOMAS = Self(name="America/St_Thomas", offset=0)
    alias EUROPE_MOSCOW = Self(name="Europe/Moscow", offset=0)
    alias PACIFIC_EASTER = Self(name="Pacific/Easter", offset=0)
    alias AMERICA_PORTO_ACRE = Self(name="America/Porto_Acre", offset=0)
    alias AMERICA_CRESTON = Self(name="America/Creston", offset=0)
    alias PACIFIC_NORFOLK = Self(name="Pacific/Norfolk", offset=0)
    alias AMERICA_ARGENTINA_CORDOBA = Self(name="America/Argentina/Cordoba", offset=0)
    alias AMERICA_ATKA = Self(name="America/Atka", offset=0)
    alias PACIFIC_NIUE = Self(name="Pacific/Niue", offset=0)
    alias ASIA_ULAN_BATOR = Self(name="Asia/Ulan_Bator", offset=0)
    alias EUROPE_SIMFEROPOL = Self(name="Europe/Simferopol", offset=0)
    alias ASIA_DILI = Self(name="Asia/Dili", offset=0)
    alias EUROPE_ZAGREB = Self(name="Europe/Zagreb", offset=0)
    alias ANTARCTICA_PALMER = Self(name="Antarctica/Palmer", offset=0)
    alias AMERICA_CAYENNE = Self(name="America/Cayenne", offset=0)
    alias ASIA_TEL_AVIV = Self(name="Asia/Tel_Aviv", offset=0)
    alias ASIA_URUMQI = Self(name="Asia/Urumqi", offset=0)
    alias ASIA_BEIRUT = Self(name="Asia/Beirut", offset=0)
    alias ASIA_KUALA_LUMPUR = Self(name="Asia/Kuala_Lumpur", offset=0)
    alias AMERICA_BELEM = Self(name="America/Belem", offset=0)
    alias PACIFIC_HONOLULU = Self(name="Pacific/Honolulu", offset=0)
    alias AMERICA_SANTA_ISABEL = Self(name="America/Santa_Isabel", offset=0)
    alias PACIFIC_KWAJALEIN = Self(name="Pacific/Kwajalein", offset=0)
    alias AFRICA_LUANDA = Self(name="Africa/Luanda", offset=0)
    alias AMERICA_CHICAGO = Self(name="America/Chicago", offset=0)
    alias ASIA_HARBIN = Self(name="Asia/Harbin", offset=0)
    alias EUROPE_PARIS = Self(name="Europe/Paris", offset=0)
    alias PACIFIC_WALLIS = Self(name="Pacific/Wallis", offset=0)
    alias AMERICA_ARGENTINA_USHUAIA = Self(name="America/Argentina/Ushuaia", offset=0)
    alias AUSTRALIA_ADelaide = Self(name="Australia/Adelaide", offset=0)
    alias ASIA_SINGAPORE = Self(name="Asia/Singapore", offset=0)
    alias AMERICA_KRALENDIJK = Self(name="America/Kralendijk", offset=0)
    alias AMERICA_MONCTON = Self(name="America/Moncton", offset=0)
    alias AMERICA_ARUBA = Self(name="America/Aruba", offset=0)
    alias AMERICA_NORONHA = Self(name="America/Noronha", offset=0)
    alias ETC_UTC = Self(name="Etc/UTC", offset=0)
    alias AFRICA_LUSAKA = Self(name="Africa/Lusaka", offset=0)
    alias ASIA_TOMSK = Self(name="Asia/Tomsk", offset=0)
    alias ASIA_PHNOM_PENH = Self(name="Asia/Phnom_Penh", offset=0)
    alias ASIA_SAMARKAND = Self(name="Asia/Samarkand", offset=0)
    alias EUROPE_LUXEMBOURG = Self(name="Europe/Luxembourg", offset=0)
    alias INDIAN_ANTANANARIVO = Self(name="Indian/Antananarivo", offset=0)
    alias ETC_GMT_PLUS_1 = Self(name="Etc/GMT+1", offset=0)
    alias AMERICA_PORTO_VELHO = Self(name="America/Porto_Velho", offset=0)
    alias GB = Self(name="GB", offset=0)
    alias AMERICA_BARbADOS = Self(name="America/Barbados", offset=0)
    alias ASIA_CHUNGKING = Self(name="Asia/Chungking", offset=0)
    alias ASIA_SHANGHAI = Self(name="Asia/Shanghai", offset=28800)
    alias ETC_GMT_13 = Self(name="Etc/GMT-13", offset=0)
    alias AMERICA_INDIANA_INDIANAPOLIS = Self(name="America/Indiana/Indianapolis", offset=0)
    alias AMERICA_ARGENTINA_MENDOZA = Self(name="America/Argentina/Mendoza", offset=0)
    alias AMERICA_JAMAICA = Self(name="America/Jamaica", offset=0)
    alias CANADA_NEWFOUNDLAND = Self(name="Canada/Newfoundland", offset=0)
    alias AMERICA_CORDOBA = Self(name="America/Cordoba", offset=0)
    alias AFRICA_NIAMEY = Self(name="Africa/Niamey", offset=0)
    alias AMERICA_HALIFAX = Self(name="America/Halifax", offset=0)
    alias ANTARCTICA_SOUTH_POLE = Self(name="Antarctica/South_Pole", offset=0)
    alias AFRICA_OUAGADOUGOU = Self(name="Africa/Ouagadougou", offset=0)
    alias CET = Self(name="CET", offset=0)
    alias AMERICA_ARGENTINA_SAN_JUAN = Self(name="America/Argentina/San_Juan", offset=0)
    alias ASIA_ALMATY = Self(name="Asia/Almaty", offset=0)
    alias ANTARCTICA_VOSTOK = Self(name="Antarctica/Vostok", offset=0)
    alias CANADA_ATLANTIC = Self(name="Canada/Atlantic", offset=0)
    alias EUROPE_AMSTERDAM = Self(name="Europe/Amsterdam", offset=0)
    alias AMERICA_COSTA_RICA = Self(name="America/Costa_Rica", offset=0)
    alias AMERICA_KNOX_IN = Self(name="America/Knox_IN", offset=0)
    alias ASIA_PONTIANAK = Self(name="Asia/Pontianak", offset=0)
    alias AMERICA_PUNTA_ARENAS = Self(name="America/Punta_Arenas", offset=0)
    alias INDIAN_MAHE = Self(name="Indian/Mahe", offset=0)
    alias AFRICA_TIMBUKTU = Self(name="Africa/Timbuktu", offset=0)
    alias ATLANTIC_MADEIRA = Self(name="Atlantic/Madeira", offset=0)
    alias CHILE_EASTERISLAND = Self(name="Chile/EasterIsland", offset=0)
    alias ATLANTIC_STANLEY = Self(name="Atlantic/Stanley", offset=0)
    alias AMERICA_CANCUN = Self(name="America/Cancun", offset=0)
    alias EUROPE_MINSK = Self(name="Europe/Minsk", offset=0)
    alias US_EASTERN = Self(name="US/Eastern", offset=0)
    alias HST = Self(name="HST", offset=0)
    alias AMERICA_BOISE = Self(name="America/Boise", offset=0)
    alias BRAZIL_WEST = Self(name="Brazil/West", offset=0)
    alias AMERICA_CATAMARCA = Self(name="America/Catamarca", offset=0)
    alias AMERICA_PORT_OF_SPAIN = Self(name="America/Port_of_Spain", offset=0)
    alias ASIA_KATMANDU = Self(name="Asia/Katmandu", offset=0)
    alias ETC_GMT_MINUS_14 = Self(name="Etc/GMT-14", offset=0)
    alias AMERICA_GUAYAQUIL = Self(name="America/Guayaquil", offset=0)
    alias AUSTRALIA_CANBERRA = Self(name="Australia/Canberra", offset=0)
    alias AMERICA_OJINAGA = Self(name="America/Ojinaga", offset=0)
    alias EUROPE_KYIV = Self(name="Europe/Kyiv", offset=0)
    alias AFRICA_KINSHASA = Self(name="Africa/Kinshasa", offset=0)
    alias PACIFIC_POHNPEI = Self(name="Pacific/Pohnpei", offset=0)
    alias AMERICA_INDIANA_WINAMAC = Self(name="America/Indiana/Winamac", offset=0)
    alias ETC_GMT_MINUS_11 = Self(name="Etc/GMT-11", offset=0)
    alias ASIA_DHAKA = Self(name="Asia/Dhaka", offset=0)
    alias AUSTRALIA_PERTH = Self(name="Australia/Perth", offset=0)
    alias AMERICA_WHITEHORSE = Self(name="America/Whitehorse", offset=0)
    alias INDIAN_REUNION = Self(name="Indian/Reunion", offset=0)
    alias EUROPE_LONDON = Self(name="Europe/London", offset=0)
    alias NAVAJO = Self(name="Navajo", offset=0)
    alias AMERICA_MANAUS = Self(name="America/Manaus", offset=0)
    alias ASIA_CHITA = Self(name="Asia/Chita", offset=0)
    alias HONGKONG = Self(name="Hongkong", offset=0)
    alias AFRICA_BISSAU = Self(name="Africa/Bissau", offset=0)
    alias AMERICA_TORTOLA = Self(name="America/Tortola", offset=0)
    alias AMERICA_JUNEAU = Self(name="America/Juneau", offset=0)
    alias EUROPE_MALTA = Self(name="Europe/Malta", offset=0)
    alias PACIFIC_PONAPE = Self(name="Pacific/Ponape", offset=0)
    alias AFRICA_ASMARA = Self(name="Africa/Asmara", offset=0)
    alias ASIA_KAMCHATKA = Self(name="Asia/Kamchatka", offset=0)
    alias EUROPE_HELSINKI = Self(name="Europe/Helsinki", offset=0)
    alias AMERICA_LOS_ANGELES = Self(name="America/Los_Angeles", offset=0)
    alias ETC_GMT_MINUS_4 = Self(name="Etc/GMT-4", offset=0)
    alias AMERICA_BAHIA = Self(name="America/Bahia", offset=0)
    alias AMERICA_PORT_AU_PRINCE = Self(name="America/Port-au-Prince", offset=0)
    alias EUROPE_VILNIUS = Self(name="Europe/Vilnius", offset=0)
    alias ETC_GMT_MINUS_1 = Self(name="Etc/GMT-1", offset=0)
    alias EUROPE_JERSEY = Self(name="Europe/Jersey", offset=0)
    alias AFRICA_TUNIS = Self(name="Africa/Tunis", offset=0)
    alias MEXICO_BAJASUR = Self(name="Mexico/BajaSur", offset=0)
    alias PACIFIC_TARAWA = Self(name="Pacific/Tarawa", offset=0)
    alias CANADA_YUKON = Self(name="Canada/Yukon", offset=0)
    alias AMERICA_VIRGIN = Self(name="America/Virgin", offset=0)
    alias EUROPE_BUDAPEST = Self(name="Europe/Budapest", offset=0)
    alias AMERICA_JUJUY = Self(name="America/Jujuy", offset=0)
    alias AFRICA_JUBA = Self(name="Africa/Juba", offset=0)
    alias AMERICA_INDiana_TELL_CITY = Self(name="America/Indiana/Tell_City", offset=0)
    alias PACIFIC_KANTON = Self(name="Pacific/Kanton", offset=0)
    alias AMERICA_NASSAU = Self(name="America/Nassau", offset=0)
    alias AMERICA_RIO_BRANCO = Self(name="America/Rio_Branco", offset=0)
    alias GMT_MINUS_0 = Self(name="GMT-0", offset=0)
    alias AUSTRALIA_TASMANIA = Self(name="Australia/Tasmania", offset=0)
    alias PACIFIC_KOSRAE = Self(name="Pacific/Kosrae", offset=0)
    alias US_HAWAII = Self(name="US/Hawaii", offset=0)
    alias ASIA_TBILISI = Self(name="Asia/Tbilisi", offset=0)
    alias PACIFIC_BOUGAINVILLE = Self(name="Pacific/Bougainville", offset=0)
    alias EUROPE_VADUZ = Self(name="Europe/Vaduz", offset=0)
    alias ETC_GMT_PLUS_11 = Self(name="Etc/GMT+11", offset=0)
    alias AFRICA_WINDHOEK = Self(name="Africa/Windhoek", offset=0)
    alias ATLANTIC_JAN_MAYEN = Self(name="Atlantic/Jan_Mayen", offset=0)
    alias AFRICA_NDJAMENA = Self(name="Africa/Ndjamena", offset=0)
    alias AMERICA_ADAK = Self(name="America/Adak", offset=0)
    alias ISRAEL = Self(name="Israel", offset=0)
    alias US_INDiana_STARKE = Self(name="US/Indiana-Starke", offset=0)
    alias AMERICA_NORTH_DAKOTA_NEW_SALEM = Self(name="America/North_Dakota/New_Salem", offset=0)
    alias PACIFIC_PALAU = Self(name="Pacific/Palau", offset=0)
    alias GMT_PLUS_0 = Self(name="GMT+0", offset=0)
    alias AMERICA_RAINY_RIVER = Self(name="America/Rainy_River", offset=0)
    alias AMERICA_WINNIPEG = Self(name="America/Winnipeg", offset=0)
    alias ETC_GREENWICH = Self(name="Etc/Greenwich", offset=0)
    alias AMERICA_PANGNIRTUNG = Self(name="America/Pangnirtung", offset=0)
    alias AFRICA_TRIPOLI = Self(name="Africa/Tripoli", offset=0)
    alias AMERICA_GUATEMALA = Self(name="America/Guatemala", offset=0)
    alias ASIA_NICOSIA = Self(name="Asia/Nicosia", offset=0)
    alias AMERICA_BELIZE = Self(name="America/Belize", offset=0)
    alias AMERICA_RESOLUTE = Self(name="America/Resolute", offset=0)
    alias ASIA_HEBRON = Self(name="Asia/Hebron", offset=0)
    alias AMERICA_CARACAS = Self(name="America/Caracas", offset=0)
    alias ASIA_NOVOSIBIRSK = Self(name="Asia/Novosibirsk", offset=0)
    alias EUROPE_PODGORICA = Self(name="Europe/Podgorica", offset=0)
    alias PRC = Self(name="PRC", offset=0)
    alias EUROPE_KALININGRAD = Self(name="Europe/Kaliningrad", offset=0)
    alias EUROPE_ZURICH = Self(name="Europe/Zurich", offset=0)
    alias AMERICA_ST_BARTHELEMY = Self(name="America/St_Barthelemy", offset=0)
    alias AMERICA_NUUK = Self(name="America/Nuuk", offset=0)
    alias ETC_GMT_PLUS_12 = Self(name="Etc/GMT+12", offset=0)
    alias ASIA_HONG_KONG = Self(name="Asia/Hong_Kong", offset=0)
    alias ETC_GMT_MINUS_3 = Self(name="Etc/GMT-3", offset=0)
    alias AMERICA_MIQUELON = Self(name="America/Miquelon", offset=0)
    alias EUROPE_VOLGOGRAD = Self(name="Europe/Volgograd", offset=0)
    alias EUROPE_MADRID = Self(name="Europe/Madrid", offset=0)
    alias AMERICA_MONTERREY = Self(name="America/Monterrey", offset=0)
    alias AMERICA_ANCHORAGE = Self(name="America/Anchorage", offset=0)
    alias AMERICA_ARGENTINA_SAN_LUIS = Self(name="America/Argentina/San_Luis", offset=0)
    alias AMERICA_EIRUNEPE = Self(name="America/Eirunepe", offset=0)
    alias AMERICA_ST_KITTS = Self(name="America/St_Kitts", offset=0)
    alias AMERICA_BAHIA_BANDERAS = Self(name="America/Bahia_Banderas", offset=0)
    alias ETC_GMT_PLUS_2 = Self(name="Etc/GMT+2", offset=0)
    alias ZULU = Self(name="Zulu", offset=0)
    alias AFRICA_GABORONE = Self(name="Africa/Gaborone", offset=0)
    alias ANTARCTICA_MCMURDO = Self(name="Antarctica/McMurdo", offset=0)
    alias EUROPE_GUERNSEY = Self(name="Europe/Guernsey", offset=0)
    alias EUROPE_ANDORRA = Self(name="Europe/Andorra", offset=0)
    alias AMERICA_PARAMARIBO = Self(name="America/Paramaribo", offset=0)
    alias AMERICA_FORT_NELSON = Self(name="America/Fort_Nelson", offset=0)
    alias ANTARCTICA_TROLL = Self(name="Antarctica/Troll", offset=0)
    alias EUROPE_UZHGOROD = Self(name="Europe/Uzhgorod", offset=0)
    alias ATLANTIC_CAPE_VERDE = Self(name="Atlantic/Cape_Verde", offset=0)
    alias UCT = Self(name="UCT", offset=0)
    alias ETC_GMT_MINUS_6 = Self(name="Etc/GMT-6", offset=0)
    alias ASIA_SREDNEKOLYMSK = Self(name="Asia/Srednekolymsk", offset=0)
    alias ASIA_UJUNG_PANDANG = Self(name="Asia/Ujung_Pandang", offset=0)
    alias AMERICA_THUNDER_BAY = Self(name="America/Thunder_Bay", offset=0)
    alias AFRICA_KHARTOUM = Self(name="Africa/Khartoum", offset=0)
    alias AFRICA_DOUALA = Self(name="Africa/Douala", offset=0)
    alias AMERICA_CAYMAN = Self(name="America/Cayman", offset=0)
    alias BRAZIL_ACRE = Self(name="Brazil/Acre", offset=0)
    alias AMERICA_INDIANA_KNOX = Self(name="America/Indiana/Knox", offset=0)
    alias AUSTRALIA_YANCOWINNA = Self(name="Australia/Yancowinna", offset=0)
    alias AMERICA_CHIHUAHUA = Self(name="America/Chihuahua", offset=0)
    alias AMERICA_RECIFE = Self(name="America/Recife", offset=0)
    alias AMERICA_INDIANA_MARENGO = Self(name="America/Indiana/Marengo", offset=0)
    alias ASIA_YANGON = Self(name="Asia/Yangon", offset=0)
    alias EUROPE_ASTRAKHAN = Self(name="Europe/Astrakhan", offset=0)
    alias ASIA_RANGOON = Self(name="Asia/Rangoon", offset=0)
    alias AMERICA_VANCOUVER = Self(name="America/Vancouver", offset=0)
    alias NZ_CHAT = Self(name="NZ-CHAT", offset=0)
    alias AMERICA_MONTERRAT = Self(name="America/Montserrat", offset=0)
    alias AMERICA_MERIDA = Self(name="America/Merida", offset=0)
    alias AMERICA_PUERTO_RICO = Self(name="America/Puerto_Rico", offset=0)
    alias AMERICA_MACEIO = Self(name="America/Maceio", offset=0)
    alias AMERICA_PANAMA = Self(name="America/Panama", offset=0)
    alias BRAZIL_EAST = Self(name="Brazil/East", offset=0)
    alias JAPAN = Self(name="Japan", offset=0)
    alias AUSTRALIA_VICTORIA = Self(name="Australia/Victoria", offset=0)
    alias AMERICA_INDIANA_PETERSBURG = Self(name="America/Indiana/Petersburg", offset=0)
    alias ASIA_DUSHANBE = Self(name="Asia/Dushanbe", offset=0)
    alias AFRICA_ASMERA = Self(name="Africa/Asmera", offset=0)
    alias ETC_ZULU = Self(name="Etc/Zulu", offset=0)
    alias EUROPE_MONACO = Self(name="Europe/Monaco", offset=0)
    alias ASIA_AMMAN = Self(name="Asia/Amman", offset=0)
    alias ASIA_KUWAIT = Self(name="Asia/Kuwait", offset=0)
    alias ASIA_SAKHALIN = Self(name="Asia/Sakhalin", offset=0)
    alias EUROPE_GIBRALTAR = Self(name="Europe/Gibraltar", offset=0)
    alias AMERICA_HAVANA = Self(name="America/Havana", offset=0)
    alias ETC_GMT_PLUS_0 = Self(name="Etc/GMT+0", offset=0)
    alias ASIA_CHOIBALSAN = Self(name="Asia/Choibalsan", offset=0)
    alias ASIA_VIENTIANE = Self(name="Asia/Vientiane", offset=0)
    alias AFRICA_MONROVIA = Self(name="Africa/Monrovia", offset=0)
    alias AFRICA_LAGOS = Self(name="Africa/Lagos", offset=0)
    alias AMERICA_ARGENTINA_BUENOS_AIRES = Self(name="America/Argentina/Buenos_Aires", offset=0)
    alias AUSTRALIA_MELBOURNE = Self(name="Australia/Melbourne", offset=0)
    alias ETC_GMT_PLUS_6 = Self(name="Etc/GMT+6", offset=0)
    alias PST8PDT = Self(name="PST8PDT", offset=0)
    alias AMERICA_SCORESBYSUND = Self(name="America/Scoresbysund", offset=0)
    alias AUSTRALIA_ACT = Self(name="Australia/ACT", offset=0)
    alias AFRICA_BLANTYRE = Self(name="Africa/Blantyre", offset=0)
    alias ASIA_SAIGON = Self(name="Asia/Saigon", offset=0)
    alias ASIA_CHONGQING = Self(name="Asia/Chongqing", offset=0)
    alias GB_EIRE = Self(name="GB-Eire", offset=0)
    alias US_SAMOA = Self(name="US/Samoa", offset=0)
    alias ARCTIC_LONGYEARBYEN = Self(name="Arctic/Longyearbyen", offset=0)
    alias AMERICA_CURACAO = Self(name="America/Curacao", offset=0)
    alias AMERICA_MEXICO_CITY = Self(name="America/Mexico_City", offset=0)
    alias ASIA_KABUL = Self(name="Asia/Kabul", offset=0)
    alias AMERICA_INDIANAPOLIS = Self(name="America/Indianapolis", offset=0)
    alias ASIA_MACAO = Self(name="Asia/Macao", offset=0)
    alias CANADA_CENTRAL = Self(name="Canada/Central", offset=0)
    alias ASIA_FAMAGUSTA = Self(name="Asia/Famagusta", offset=0)
    alias AMERICA_ATIKOKAN = Self(name="America/Atikokan", offset=0)
    alias ASIA_BRUNEI = Self(name="Asia/Brunei", offset=0)
    alias ASIA_UST_NERA = Self(name="Asia/Ust-Nera", offset=0)
    alias BRAZIL_DE_NORONHA = Self(name="Brazil/DeNoronha", offset=0)
    alias INDIAN_CHAGOS = Self(name="Indian/Chagos", offset=0)
    alias ASIA_KATHMANDU = Self(name="Asia/Kathmandu", offset=0)
    alias ASIA_TEHRAN = Self(name="Asia/Tehran", offset=0)
    alias AFRICA_DAR_ES_SALAAM = Self(name="Africa/Dar_es_Salaam", offset=0)
    alias AMERICA_MANAGUA = Self(name="America/Managua", offset=0)
    alias AFRICA_CAIRO = Self(name="Africa/Cairo", offset=0)
    alias PACIFIC_NAURU = Self(name="Pacific/Nauru", offset=0)
    alias EUROPE_SARATOV = Self(name="Europe/Saratov", offset=0)
    alias INDIAN_MALDIVES = Self(name="Indian/Maldives", offset=0)
    alias ASIA_MAKASSAR = Self(name="Asia/Makassar", offset=0)
    alias AMERICA_SAO_PAULO = Self(name="America/Sao_Paulo", offset=0)
    alias AMERICA_ST_JOHNS = Self(name="America/St_Johns", offset=0)
    alias ETC_GMT_PLUS_9 = Self(name="Etc/GMT+9", offset=0)
    alias ASIA_QYZYLORDA = Self(name="Asia/Qyzylorda", offset=0)
    alias AUSTRALIA_NORTH = Self(name="Australia/North", offset=0)
    alias AMERICA_MONTEVIDEO = Self(name="America/Montevideo", offset=0)
    alias AUSTRALIA_WEST = Self(name="Australia/West", offset=0)
    alias EUROPE_OSLO = Self(name="Europe/Oslo", offset=0)
    alias TURKEY = Self(name="Turkey", offset=0)
    alias US_CENTRAL = Self(name="US/Central", offset=0)
    alias EUROPE_BERLIN = Self(name="Europe/Berlin", offset=0)
    alias EUROPE_BRATISLAVA = Self(name="Europe/Bratislava", offset=0)
    alias AMERICA_EL_SALVADOR = Self(name="America/El_Salvador", offset=0)
    alias AFRICA_KAMPALA = Self(name="Africa/Kampala", offset=0)
    alias AMERICA_DAWSON = Self(name="America/Dawson", offset=0)
    alias AMERICA_LA_PAZ = Self(name="America/La_Paz", offset=0)
    alias US_ALEUTIAN = Self(name="US/Aleutian", offset=0)
    alias ASIA_KOLKATA = Self(name="Asia/Kolkata", offset=0)
    alias ASIA_ORAL = Self(name="Asia/Oral", offset=0)
    alias ASIA_OMSK = Self(name="Asia/Omsk", offset=0)
    alias AMERICA_SANTIAGO = Self(name="America/Santiago", offset=0)
    alias AMERICA_DETROIT = Self(name="America/Detroit", offset=0)
    alias AMERICA_ANGUILLA = Self(name="America/Anguilla", offset=0)
    alias AMERICA_NOME = Self(name="America/Nome", offset=0)
    alias SINGAPORE = Self(name="Singapore", offset=0)
    alias AFRICA_CONAKRY = Self(name="Africa/Conakry", offset=0)
    alias AFRICA_MAPUTO = Self(name="Africa/Maputo", offset=0)
    alias ANTARCTICA_DAVIS = Self(name="Antarctica/Davis", offset=0)
    alias ASIA_MANILA = Self(name="Asia/Manila", offset=0)
    alias PACIFIC_MAJURO = Self(name="Pacific/Majuro", offset=0)
    alias AFRICA_LUBUMBASHI = Self(name="Africa/Lubumbashi", offset=0)
    alias PORTUGAL = Self(name="Portugal", offset=0)
    alias PACIFIC_PORT_MORESBY = Self(name="Pacific/Port_Moresby", offset=0)
    alias ETC_GMT_PLUS_3 = Self(name="Etc/GMT+3", offset=0)
    alias CHILE_CONTINENTAL = Self(name="Chile/Continental", offset=0)
    alias GMT = Self(name="GMT", offset=0)
    alias AMERICA_MARTINIQUE = Self(name="America/Martinique", offset=0)
    alias AFRICA_SAO_TOME = Self(name="Africa/Sao_Tome", offset=0)
    alias AMERICA_SITKA = Self(name="America/Sitka", offset=0)
    alias ASIA_TAIPEI = Self(name="Asia/Taipei", offset=0)
    alias INDIAN_MAYOTTE = Self(name="Indian/Mayotte", offset=0)
    alias AMERICA_ARGENTINA_RIO_GALLEGOS = Self(name="America/Argentina/Rio_Gallegos", offset=0)
    alias AMERICA_MENOMINEE = Self(name="America/Menominee", offset=0)
    alias CANADA_PACIFIC = Self(name="Canada/Pacific", offset=0)
    alias MET = Self(name="MET", offset=0)
    alias ASIA_THIMBU = Self(name="Asia/Thimbu", offset=0)
    alias AMERICA_CAMPO_GRANDE = Self(name="America/Campo_Grande", offset=0)
    alias ASIA_MAGADAN = Self(name="Asia/Magadan", offset=0)
    alias AFRICA_CASABLANCA = Self(name="Africa/Casablanca", offset=0)
    alias AMERICA_GUADELOUPE = Self(name="America/Guadeloupe", offset=0)
    alias ATLANTIC_FAROE = Self(name="Atlantic/Faroe", offset=0)
    alias ASIA_ANADYR = Self(name="Asia/Anadyr", offset=0)
    alias AFRICA_PORTO_NOVO = Self(name="Africa/Porto-Novo", offset=0)
    alias AFRICA_BANJUL = Self(name="Africa/Banjul", offset=0)
    alias INDIAN_COMORO = Self(name="Indian/Comoro", offset=0)
    alias AMERICA_YAKUTAT = Self(name="America/Yakutat", offset=0)
    alias PACIFIC_GAMBIER = Self(name="Pacific/Gambier", offset=0)
    alias ASIA_ASHGABAT = Self(name="Asia/Ashgabat", offset=0)
    alias ANTARCTICA_DUMONT_DURVILLE = Self(name="Antarctica/DumontDUrville", offset=0)
    alias US_EAST_IND = Self(name="US/East-Indiana", offset=0)
    alias ASIA_IRKUTSK = Self(name="Asia/Irkutsk", offset=0)
    alias AMERICA_MAZATLAN = Self(name="America/Mazatlan", offset=0)
    alias PACIFIC_APIA = Self(name="Pacific/Apia", offset=0)
    alias AMERICA_BOA_VISTA = Self(name="America/Boa_Vista", offset=0)
    alias ETC_GMT = Self(name="Etc/GMT", offset=0)
    alias AMERICA_GUYANA = Self(name="America/Guyana", offset=0)
    alias AUSTRALIA_CURRIE = Self(name="Australia/Currie", offset=0)
    alias EUROPE_ULYANOVSK = Self(name="Europe/Ulyanovsk", offset=0)
    alias PACIFIC_FAKAOFO = Self(name="Pacific/Fakaofo", offset=0)
    alias AMERICA_NORTH_DAKOTA_BEULAH = Self(name="America/North_Dakota/Beulah", offset=0)
    alias EUROPE_PRAGUE = Self(name="Europe/Prague", offset=0)
    alias ASIA_QATAR = Self(name="Asia/Qatar", offset=0)
    alias PACIFIC_FUNAFUTI = Self(name="Pacific/Funafuti", offset=0)
    alias JAMAICA = Self(name="Jamaica", offset=0)
    alias CANADA_EASTERN = Self(name="Canada/Eastern", offset=0)
    alias PACIFIC_GUAM = Self(name="Pacific/Guam", offset=0)
    alias PACIFIC_FIJI = Self(name="Pacific/Fiji", offset=0)
    alias AFRICA_KIGALI = Self(name="Africa/Kigali", offset=0)
    alias PACIFIC_TONGATAPU = Self(name="Pacific/Tongatapu", offset=0)
    alias AMERICA_LIMA = Self(name="America/Lima", offset=0)
    alias ASIA_MUSCAT = Self(name="Asia/Muscat", offset=0)
    alias ANTARCTICA_MACQUARIE = Self(name="Antarctica/Macquarie", offset=0)
    alias ETC_GMT_MINUS_2 = Self(name="Etc/GMT-2", offset=0)
    alias PACIFIC_PITCAIRN = Self(name="Pacific/Pitcairn", offset=0)
    alias CANADA_MOUNTAIN = Self(name="Canada/Mountain", offset=0)
    alias ASIA_YEKATERINBURG = Self(name="Asia/Yekaterinburg", offset=0)
    alias PACIFIC_JOHNSTON = Self(name="Pacific/Johnston", offset=0)
    alias EUROPE_VATICAN = Self(name="Europe/Vatican", offset=0)
    alias ATLANTIC_BERMUDA = Self(name="Atlantic/Bermuda", offset=0)
    alias ASIA_JERUSALEM = Self(name="Asia/Jerusalem", offset=0)
    alias AMERICA_CIUDAD_JUAREZ = Self(name="America/Ciudad_Juarez", offset=0)
    alias PACIFIC_GALAPAGOS = Self(name="Pacific/Galapagos", offset=0)
    alias AMERICA_MONTREAL = Self(name="America/Montreal", offset=0)
    alias AFRICA_NOUAKCHOTT = Self(name="Africa/Nouakchott", offset=0)
    alias US_ARIZONA = Self(name="US/Arizona", offset=0)
    alias ASIA_KUCHING = Self(name="Asia/Kuching", offset=0)
    alias ETC_GMT_PLUS_4 = Self(name="Etc/GMT+4", offset=0)
    alias AUSTRALIA_BRISBANE = Self(name="Australia/Brisbane", offset=0)
    alias CANADA_SASKATCHEWAN = Self(name="Canada/Saskatchewan", offset=0)
    alias EUROPE_DUBLIN = Self(name="Europe/Dublin", offset=0)
    alias ASIA_QOSTANAY = Self(name="Asia/Qostanay", offset=0)
    alias AMERICA_EDMONTON = Self(name="America/Edmonton", offset=0)
    alias ATLANTIC_REYKJAVIK = Self(name="Atlantic/Reykjavik", offset=0)
    alias AMERICA_FORTALEZA = Self(name="America/Fortaleza", offset=0)
    alias PACIFIC_KIRITIMATI = Self(name="Pacific/Kiritimati", offset=0)
    alias ETC_UNIVERSAL = Self(name="Etc/Universal", offset=0)
    alias GMT0 = Self(name="GMT0", offset=0)
    alias EUROPE_BELFAST = Self(name="Europe/Belfast", offset=0)
    alias PACIFIC_YAP = Self(name="Pacific/Yap", offset=0)
    alias AMERICA_SANTO_DOMINGO = Self(name="America/Santo_Domingo", offset=0)
    alias ICELAND = Self(name="Iceland", offset=0)
    alias AMERICA_ARAGUAINA = Self(name="America/Araguaina", offset=0)
    alias ASIA_KARACHI = Self(name="Asia/Karachi", offset=0)
    alias ETC_GMT_PLUS_7 = Self(name="Etc/GMT+7", offset=0)
    alias AFRICA_BUJUMBURA = Self(name="Africa/Bujumbura", offset=0)
    alias AMERICA_DAWSON_CREEK = Self(name="America/Dawson_Creek", offset=0)
    alias EUROPE_ZAPOROZHYE = Self(name="Europe/Zaporozhye", offset=0)
    alias ASIA_ULAANBAATAR = Self(name="Asia/Ulaanbaatar", offset=0)
    alias PACIFIC_SAMOA = Self(name="Pacific/Samoa", offset=0)
    alias AUSTRALIA_DARWIN = Self(name="Australia/Darwin", offset=0)
    alias ETC_GMT0 = Self(name="Etc/GMT0", offset=0)
    alias PACIFIC_TAHITI = Self(name="Pacific/Tahiti", offset=0)
    alias ETC_GMT_MINUS_8 = Self(name="Etc/GMT-8", offset=0)
    alias ATLANTIC_FAEROE = Self(name="Atlantic/Faeroe", offset=0)
    alias AFRICA_LIBREVILLE = Self(name="Africa/Libreville", offset=0)
    alias ASIA_BARNAUL = Self(name="Asia/Barnaul", offset=0)
    alias AMERICA_CORAL_HARBOUR = Self(name="America/Coral_Harbour", offset=0)
    alias ANTARCTICA_SYOWA = Self(name="Antarctica/Syowa", offset=0)
    alias AMERICA_BUENOS_AIRES = Self(name="America/Buenos_Aires", offset=0)
    alias EUROPE_VIENNA = Self(name="Europe/Vienna", offset=0)
    alias AMERICA_FORT_WAYNE = Self(name="America/Fort_Wayne", offset=0)
    alias NZ = Self(name="NZ", offset=0)
    alias ATLANTIC_AZORES = Self(name="Atlantic/Azores", offset=0)
    alias AMERICA_COYHAIQUE = Self(name="America/Coyhaique", offset=0)
    alias ASIA_PYONGYANG = Self(name="Asia/Pyongyang", offset=0)
    alias ETC_GMT_MINUS_10 = Self(name="Etc/GMT-10", offset=0)
    alias MST = Self(name="MST", offset=0)
    alias AMERICA_ARGENTINA_JUJUY = Self(name="America/Argentina/Jujuy", offset=0)
    alias AMERICA_TIJUANA = Self(name="America/Tijuana", offset=0)
    alias PACIFIC_GUADALCANAL = Self(name="Pacific/Guadalcanal", offset=0)
    alias EUROPE_STOCKHOLM = Self(name="Europe/Stockholm", offset=0)
    alias US_ALASKA = Self(name="US/Alaska", offset=0)
    alias EUROPE_TIRASPOL = Self(name="Europe/Tiraspol", offset=0)
    alias EUROPE_SAMARA = Self(name="Europe/Samara", offset=0)
    alias ETC_GMT_MINUS_12 = Self(name="Etc/GMT-12", offset=0)
    alias KWAJALEIN = Self(name="Kwajalein", offset=0)
    alias ASIA_MACAU = Self(name="Asia/Macau", offset=0)
    alias PACIFIC_TRUK = Self(name="Pacific/Truk", offset=0)
    alias ASIA_BANGKOK = Self(name="Asia/Bangkok", offset=0)
    alias AMERICA_ANTIGUA = Self(name="America/Antigua", offset=0)
    alias AFRICA_EL_AAIUN = Self(name="Africa/El_Aaiun", offset=0)
    alias EUROPE_MARIEHAMN = Self(name="Europe/Mariehamn", offset=0)
    alias ASIA_JAYAPURA = Self(name="Asia/Jayapura", offset=0)
    alias EUROPE_SAN_MARINO = Self(name="Europe/San_Marino", offset=0)
    alias US_PACIFIC = Self(name="US/Pacific", offset=0)
    alias AFRICA_JOHANNESBURG = Self(name="Africa/Johannesburg", offset=0)
    alias AUSTRALIA_EUCLA = Self(name="Australia/Eucla", offset=0)
    alias AFRICA_NAIROBI = Self(name="Africa/Nairobi", offset=0)
    alias ETC_GMT_MINUS_7 = Self(name="Etc/GMT-7", offset=0)
    alias AMERICA_INUVIK = Self(name="America/Inuvik", offset=0)
    alias ASIA_TOKYO = Self(name="Asia/Tokyo", offset=0)
    alias ASIA_ATYRAU = Self(name="Asia/Atyrau", offset=0)
    alias ASIA_KASHGAR = Self(name="Asia/Kashgar", offset=0)
    alias W_SU = Self(name="W-SU", offset=0)
    alias ASIA_TASHKENT = Self(name="Asia/Tashkent", offset=0)
    alias AFRICA_FREETOWN = Self(name="Africa/Freetown", offset=0)
    alias PACIFIC_PAGO_PAGO = Self(name="Pacific/Pago_Pago", offset=0)
    alias AMERICA_DENVER = Self(name="America/Denver", offset=0)
    alias AUSTRALIA_LHI = Self(name="Australia/LHI", offset=0)
    alias PACIFIC_RAROTONGA = Self(name="Pacific/Rarotonga", offset=0)
    alias MST7MDT = Self(name="MST7MDT", offset=0)
    alias PACIFIC_NOUMEA = Self(name="Pacific/Noumea", offset=0)
    alias ETC_UCT = Self(name="Etc/UCT", offset=0)
    alias ETC_GMT_PLUS_10 = Self(name="Etc/GMT+10", offset=0)
    alias ROK = Self(name="ROK", offset=0)
    alias PACIFIC_AUCKLAND = Self(name="Pacific/Auckland", offset=0)
    alias ASIA_NOVOKUZNETSK = Self(name="Asia/Novokuznetsk", offset=0)
    alias AMERICA_HERMOSILLO = Self(name="America/Hermosillo", offset=0)
    alias AMERICA_LOUISVILLE = Self(name="America/Louisville", offset=0)
    alias ASIA_HO_CHI_MINH = Self(name="Asia/Ho_Chi_Minh", offset=0)
    alias ASIA_YEREVAN = Self(name="Asia/Yerevan", offset=0)
    alias ASIA_YAKUTSK = Self(name="Asia/Yakutsk", offset=0)
    alias UNIVERSAL = Self(name="Universal", offset=0)
    alias AMERICA_TEGUCIGALPA = Self(name="America/Tegucigalpa", offset=0)
    alias MEXICO_BAJANORTE = Self(name="Mexico/BajaNorte", offset=0)
    alias EUROPE_SARAJEVO = Self(name="Europe/Sarajevo", offset=0)
    alias AMERICA_ARGENTINA_CATAMARCA = Self(name="America/Argentina/Catamarca", offset=0)
    alias CUBA = Self(name="Cuba", offset=0)
    alias ASIA_KHANDYGA = Self(name="Asia/Khandyga", offset=0)
    alias AMERICA_LOWER_PRINCES = Self(name="America/Lower_Princes", offset=0)
    alias AMERICA_BLANC_SABLON = Self(name="America/Blanc-Sablon", offset=0)
    alias AMERICA_BOGOTA = Self(name="America/Bogota", offset=0)
    alias AFRICA_LOME = Self(name="Africa/Lome", offset=0)
    alias AMERICA_TORONTO = Self(name="America/Toronto", offset=0)
    alias EUROPE_WARSAW = Self(name="Europe/Warsaw", offset=0)
    alias AMERICA_YELLOWKNIFE = Self(name="America/Yellowknife", offset=0)
    alias AMERICA_SWIFT_CURRENT = Self(name="America/Swift_Current", offset=0)
    alias EST = Self(name="EST", offset=0)
    alias EUROPE_SOFIA = Self(name="Europe/Sofia", offset=0)
    alias AFRICA_CEUTA = Self(name="Africa/Ceuta", offset=0)
    alias AMERICA_MARIGOT = Self(name="America/Marigot", offset=0)
    alias AMERICA_DANMARKSHAVN = Self(name="America/Danmarkshavn", offset=0)
    alias AFRICA_HARARE = Self(name="Africa/Harare", offset=0)
    alias UTC = Self(name="UTC", offset=0)
    alias UTC_PLUS_1 = Self(name="UTC+1", offset=3600)
    alias UTC_PLUS_2 = Self(name="UTC+2", offset=7200)
    alias UTC_PLUS_3 = Self(name="UTC+3", offset=10800)
    alias UTC_PLUS_4 = Self(name="UTC+4", offset=14400)
    alias UTC_PLUS_5 = Self(name="UTC+5", offset=18000)
    alias UTC_PLUS_6 = Self(name="UTC+6", offset=21600)
    alias UTC_PLUS_7 = Self(name="UTC+7", offset=25200)
    alias UTC_PLUS_8 = Self(name="UTC+8", offset=28800)
    alias UTC_PLUS_9 = Self(name="UTC+9", offset=32400)
    alias UTC_PLUS_10 = Self(name="UTC+10", offset=36000)
    alias UTC_PLUS_11 = Self(name="UTC+11", offset=39600)
    alias UTC_PLUS_12 = Self(name="UTC+12", offset=43200)
    alias UTC_MINUS_1 = Self(name="UTC-1", offset=-3600)
    alias UTC_MINUS_2 = Self(name="UTC-2", offset=-7200)
    alias UTC_MINUS_3 = Self(name="UTC-3", offset=-10800)
    alias UTC_MINUS_4 = Self(name="UTC-4", offset=-14400)
    alias UTC_MINUS_5 = Self(name="UTC-5", offset=-18000)
    alias UTC_MINUS_6 = Self(name="UTC-6", offset=-21600)
    alias UTC_MINUS_7 = Self(name="UTC-7", offset=-25200)
    alias UTC_MINUS_8 = Self(name="UTC-8", offset=-28800)
    alias UTC_MINUS_9 = Self(name="UTC-9", offset=-32400)
    alias UTC_MINUS_10 = Self(name="UTC-10", offset=-36000)
    alias UTC_MINUS_11 = Self(name="UTC-11", offset=-39600)
    alias UTC_MINUS_12 = Self(name="UTC-12", offset=-43200)
    alias EST5EDT = Self(name="EST5EDT", offset=0)
    alias PACIFIC_MIDWAY = Self(name="Pacific/Midway", offset=0)
    alias ASIA_ISTANBUL = Self(name="Asia/Istanbul", offset=0)
    alias AMERICA_ARGENTINA_COMODRIVADAVIA = Self(name="America/Argentina/ComodRivadavia", offset=0)
    alias ASIA_BAKU = Self(name="Asia/Baku", offset=0)
    alias AUSTRALIA_NSW = Self(name="Australia/NSW", offset=0)
    alias EUROPE_BUSINGEN = Self(name="Europe/Busingen", offset=0)
    alias AMERICA_REGINA = Self(name="America/Regina", offset=0)
    alias AFRICA_BANGUI = Self(name="Africa/Bangui", offset=0)
    alias POLAND = Self(name="Poland", offset=0)
    alias INDIAN_CHRISTMAS = Self(name="Indian/Christmas", offset=0)
    alias AUSTRALIA_QUEENSLAND = Self(name="Australia/Queensland", offset=0)
    alias ASIA_BISHKEK = Self(name="Asia/Bishkek", offset=0)
    alias ASIA_DUBAI = Self(name="Asia/Dubai", offset=0)
    alias AFRICA_MBABANE = Self(name="Africa/Mbabane", offset=0)
    alias AMERICA_GRAND_TURK = Self(name="America/Grand_Turk", offset=0)
    alias AMERICA_GLACE_BAY = Self(name="America/Glace_Bay", offset=0)
    alias PACIFIC_ENDERBURY = Self(name="Pacific/Enderbury", offset=0)
    alias AFRICA_DAKAR = Self(name="Africa/Dakar", offset=0)
    alias AFRICA_ALGIERS = Self(name="Africa/Algiers", offset=0)
    alias ASIA_DAMASCUS = Self(name="Asia/Damascus", offset=0)
    alias AMERICA_RANKIN_INLET = Self(name="America/Rankin_Inlet", offset=0)
    alias EUROPE_BRUSSELS = Self(name="Europe/Brussels", offset=0)
    alias ASIA_HOVD = Self(name="Asia/Hovd", offset=0)
    alias AUSTRALIA_HOBART = Self(name="Australia/Hobart", offset=0)
    alias EUROPE_BUCHAREST = Self(name="Europe/Bucharest", offset=0)
    alias ASIA_GAZA = Self(name="Asia/Gaza", offset=0)
    alias IRAN = Self(name="Iran", offset=0)
    alias AFRICA_DJIBOUTI = Self(name="Africa/Djibouti", offset=0)
    alias AMERICA_ROSARIO = Self(name="America/Rosario", offset=0)
    alias EUROPE_BELGRADE = Self(name="Europe/Belgrade", offset=0)
    alias ANTARCTICA_ROTHERA = Self(name="Antarctica/Rothera", offset=0)
    alias AFRICA_ADDIS_ABABA = Self(name="Africa/Addis_Ababa", offset=0)
    alias ASIA_DACCA = Self(name="Asia/Dacca", offset=0)
    alias ASIA_KRASNOYARSK = Self(name="Asia/Krasnoyarsk", offset=0)
    alias EUROPE_CHISINAU = Self(name="Europe/Chisinau", offset=0)
    alias INDIAN_COCOS = Self(name="Indian/Cocos", offset=0)
    alias AMERICA_INDiana_VINCENNES = Self(name="America/Indiana/Vincennes", offset=0)
    alias AMERICA_CAMBRIDGE_BAY = Self(name="America/Cambridge_Bay", offset=0)
    alias ASIA_THIMPHU = Self(name="Asia/Thimphu", offset=0)
    alias EUROPE_RIGA = Self(name="Europe/Riga", offset=0)
    alias US_MOUNTAIN = Self(name="US/Mountain", offset=0)
    alias EGYPT = Self(name="Egypt", offset=0)
    alias AMERICA_ARGENTINA_TUCUMAN = Self(name="America/Argentina/Tucuman", offset=0)
    alias ATLANTIC_ST_HELENA = Self(name="Atlantic/St_Helena", offset=0)
    alias GREENWICH = Self(name="Greenwich", offset=0)
    alias ASIA_ASHKHABAD = Self(name="Asia/Ashkhabad", offset=0)
    alias EUROPE_NICOSIA = Self(name="Europe/Nicosia", offset=0)
    alias ASIA_AQTAU = Self(name="Asia/Aqtau", offset=0)
    alias ANTARCTICA_MAWSON = Self(name="Antarctica/Mawson", offset=0)
    alias AMERICA_NORTH_DAKOTA_CENTER = Self(name="America/North_Dakota/Center", offset=0)
    alias EET = Self(name="EET", offset=0)
    alias ROC = Self(name="ROC", offset=0)
    alias AMERICA_MENDOZA = Self(name="America/Mendoza", offset=0)
    alias AMERICA_ST_VINCENT = Self(name="America/St_Vincent", offset=0)
    alias CST6CDT = Self(name="CST6CDT", offset=0)
    alias ASIA_BAHRAIN = Self(name="Asia/Bahrain", offset=0)
    alias ASIA_RIYADH = Self(name="Asia/Riyadh", offset=0)
    alias PACIFIC_EFATE = Self(name="Pacific/Efate", offset=0)
    alias INDIAN_MAURITIUS = Self(name="Indian/Mauritius", offset=0)
    alias INDIAN_KERGULEN = Self(name="Indian/Kerguelen", offset=0)
    alias ASIA_COLOMBO = Self(name="Asia/Colombo", offset=0)
    alias AFRICA_MASERU = Self(name="Africa/Maseru", offset=0)
    alias AMERICA_ASUNCION = Self(name="America/Asuncion", offset=0)
    alias EUROPE_COPENHAGEN = Self(name="Europe/Copenhagen", offset=0)
    alias AMERICA_ARGENTINA_SALTA = Self(name="America/Argentina/Salta", offset=0)
    alias AFRICA_MALABO = Self(name="Africa/Malabo", offset=0)
    alias AMERICA_MATAMOROS = Self(name="America/Matamoros", offset=0)
    alias AMERICA_ARGENTINA_LA_RIOJA = Self(name="America/Argentina/La_Rioja", offset=0)
    alias AFRICA_ACCRA = Self(name="Africa/Accra", offset=0)
    alias EIRE = Self(name="Eire", offset=0)
    alias AMERICA_KENTUCKY_LOUISVILLE = Self(name="America/Kentucky/Louisville", offset=0)
    alias AFRICA_BAMAKO = Self(name="Africa/Bamako", offset=0)
    alias ETC_GMT_5 = Self(name="Etc/GMT-5", offset=0)
    alias PACIFIC_CHATHAM = Self(name="Pacific/Chatham", offset=0)
    alias WET = Self(name="WET", offset=0)
    alias ETC_GMT_PLUS_5 = Self(name="Etc/GMT+5", offset=0)
    alias AFRICA_MOGADISHU = Self(name="Africa/Mogadishu", offset=0)
    alias AMERICA_THULE = Self(name="America/Thule", offset=0)
    alias AMERICA_PHOENIX = Self(name="America/Phoenix", offset=0)
    alias AUSTRALIA_LORD_HOWE = Self(name="Australia/Lord_Howe", offset=0)
    alias PACIFIC_CHUUK = Self(name="Pacific/Chuuk", offset=0)
    alias PACIFIC_MARQUESAS = Self(name="Pacific/Marquesas", offset=0)
    alias PACIFIC_WAKE = Self(name="Pacific/Wake", offset=0)
    alias AFRICA_BRAZZAVILLE = Self(name="Africa/Brazzaville", offset=0)
    alias AUSTRALIA_BROKEN_HILL = Self(name="Australia/Broken_Hill", offset=0)
    alias AUSTRALIA_SOUTH = Self(name="Australia/South", offset=0)
    alias AMERICA_KENTUCKY_MONTICELLO = Self(name="America/Kentucky/Monticello", offset=0)
    alias EUROPE_KIEV = Self(name="Europe/Kiev", offset=0)
    alias ETC_GMT_9 = Self(name="Etc/GMT-9", offset=0)
    alias AUSTRALIA_LINDEMAN = Self(name="Australia/Lindeman", offset=0)
    alias AMERICA_METLAKATLA = Self(name="America/Metlakatla", offset=0)
    alias AMERICA_GOOSE_BAY = Self(name="America/Goose_Bay", offset=0)
    alias AMERICA_ST_LUCIA = Self(name="America/St_Lucia", offset=0)
    alias EUROPE_LJUBLJANA = Self(name="Europe/Ljubljana", offset=0)
    alias EUROPE_TIRANE = Self(name="Europe/Tirane", offset=0)
    alias AMERICA_SANTAREM = Self(name="America/Santarem", offset=0)
    alias ATLANTIC_CANARY = Self(name="Atlantic/Canary", offset=0)
    alias AMERICA_GRENADA = Self(name="America/Grenada", offset=0)
    alias AMERICA_SHIPROCK = Self(name="America/Shiprock", offset=0)
    alias EUROPE_SKOPJE = Self(name="Europe/Skopje", offset=0)
    alias ETC_GMT_PLUS_8 = Self(name="Etc/GMT+8", offset=0)
    alias ASIA_BAGHDAD = Self(name="Asia/Baghdad", offset=0)
    alias AUSTRALIA_SYDNEY = Self(name="Australia/Sydney", offset=0)
    alias EUROPE_ISTANBUL = Self(name="Europe/Istanbul", offset=0)
    alias AMERICA_DOMINICA = Self(name="America/Dominica", offset=0)
    alias AMERICA_NIPIGON = Self(name="America/Nipigon", offset=0)
    alias ASIA_CALCUTTA = Self(name="Asia/Calcutta", offset=0)
    alias ETC_GMT_0 = Self(name="Etc/GMT-0", offset=0)
    alias ANTARCTICA_CASEY = Self(name="Antarctica/Casey", offset=0)
    alias ASIA_VLADIVOSTOK = Self(name="Asia/Vladivostok", offset=0)
    alias AMERICA_GODTHAB = Self(name="America/Godthab", offset=0)
    alias ASIA_AQTUBE = Self(name="Asia/Aqtube", offset=0)
    alias EUROPE_KIROV = Self(name="Europe/Kirov", offset=0)
    alias ASIA_ADEN = Self(name="Asia/Aden", offset=0)
    alias EUROPE_ISLE_OF_MAN = Self(name="Europe/Isle_of_Man", offset=0)

    @implicit
    fn __init__(out self, name: StringLiteral):
        """Initializes a new timezone.

        Args:
            name: Time zone name.
        """
        self.name = String(name)
    
    fn format(self, separator: String = ":") -> String:
        """Formats the timezone.

        Args:
            separator: Separator between hours and minutes.

        Returns:
            Formatted timezone.
        """
        var sign: String
        var offset_abs: Int
        if self.offset < 0:
            sign = "-"
            offset_abs = -self.offset
        else:
            sign = "+"
            offset_abs = self.offset
        var hours = String(offset_abs // 3600).rjust(2, "0")
        var minutes = String(offset_abs % 3600).rjust(2, "0")
        return String(sign, hours, separator, minutes)
    
    @staticmethod
    fn from_utc_offset(offset: Int) raises -> Self:
        """Creates a new timezone from its UTC offset.

        Args:
            offset: UTC offset in seconds.

        Returns:
            A new timezone instance.
        """
        if offset == 0:
            return Self.UTC
        elif offset == 3600:
            return Self.UTC_PLUS_1
        elif offset == 7200:
            return Self.UTC_PLUS_2
        elif offset == 10800:
            return Self.UTC_PLUS_3
        elif offset == 14400:
            return Self.UTC_PLUS_4
        elif offset == 18000:
            return Self.UTC_PLUS_5
        elif offset == 21600:
            return Self.UTC_PLUS_6
        elif offset == 25200:
            return Self.UTC_PLUS_7
        elif offset == 28800:
            return Self.UTC_PLUS_8
        elif offset == 32400:
            return Self.UTC_PLUS_9
        elif offset == 36000:
            return Self.UTC_PLUS_10
        elif offset == 39600:
            return Self.UTC_PLUS_11
        elif offset == 43200:
            return Self.UTC_PLUS_12
        elif offset == -3600:
            return Self.UTC_MINUS_1
        elif offset == -7200:
            return Self.UTC_MINUS_2
        elif offset == -10800:
            return Self.UTC_MINUS_3
        elif offset == -14400:
            return Self.UTC_MINUS_4
        elif offset == -18000:
            return Self.UTC_MINUS_5
        elif offset == -21600:
            return Self.UTC_MINUS_6
        elif offset == -25200:
            return Self.UTC_MINUS_7
        elif offset == -28800:
            return Self.UTC_MINUS_8
        elif offset == -32400:
            return Self.UTC_MINUS_9
        elif offset == -36000:
            return Self.UTC_MINUS_10
        elif offset == -39600:
            return Self.UTC_MINUS_11
        elif offset == -43200:
            return Self.UTC_MINUS_12
        
        raise Error("Unsupported UTC offset, must be a multiple of 3600 seconds. +-12 hours are supported.")

    @staticmethod
    fn from_name(name: String) raises -> Self:
        """Creates a new timezone from its name.

        Args:
            name: Time zone name.

        Returns:
            A new timezone instance.
        """
        # TODO (Mikhail): Incoming big if statement of doom. We don't have
        # proper enums with pattern matching yet. So this is just going to be
        # a big if statement for now.
        if name == "Asia/Jakarta":
            return Self.ASIA_JAKARTA
        elif name == "Libya":
            return Self.LIBYA
        elif name == "America/Iqaluit":
            return Self.AMERICA_IQALUIT
        elif name == "America/Indiana/Vevay":
            return Self.AMERICA_INDIANA_VEVAY
        elif name == "Atlantic/South_Georgia":
            return Self.ATLANTIC_SOUTH_GEORGIA
        elif name == "America/Cuiaba":
            return Self.AMERICA_CUIABA
        elif name == "Europe/Tallinn":
            return Self.EUROPE_TALLINN
        elif name == "America/Ensenada":
            return Self.AMERICA_ENSENADA
        elif name == "Africa/Abidjan":
            return Self.AFRICA_ABIDJAN
        elif name == "Pacific/Saipan":
            return Self.PACIFIC_SAIPAN
        elif name == "Mexico/General":
            return Self.MEXICO_GENERAL
        elif name == "Europe/Rome":
            return Self.EUROPE_ROME
        elif name == "Asia/Seoul":
            return Self.ASIA_SEOUL
        elif name == "US/Michigan":
            return Self.US_MICHIGAN
        elif name == "America/New_York":
            return Self.AMERICA_NEW_YORK
        elif name == "Europe/Athens":
            return Self.EUROPE_ATHENS
        elif name == "Europe/Lisbon":
            return Self.EUROPE_LISBON
        elif name == "America/St_Thomas":
            return Self.AMERICA_ST_THOMAS
        elif name == "Europe/Moscow":
            return Self.EUROPE_MOSCOW
        elif name == "Pacific/Easter":
            return Self.PACIFIC_EASTER
        elif name == "America/Porto_Acre":
            return Self.AMERICA_PORTO_ACRE
        elif name == "America/Creston":
            return Self.AMERICA_CRESTON
        elif name == "Pacific/Norfolk":
            return Self.PACIFIC_NORFOLK
        elif name == "America/Argentina/Cordoba":
            return Self.AMERICA_ARGENTINA_CORDOBA
        elif name == "America/Atka":
            return Self.AMERICA_ATKA
        elif name == "Pacific/Niue":
            return Self.PACIFIC_NIUE
        elif name == "Asia/Ulan_Bator":
            return Self.ASIA_ULAN_BATOR
        elif name == "Europe/Simferopol":
            return Self.EUROPE_SIMFEROPOL
        elif name == "Asia/Dili":
            return Self.ASIA_DILI
        elif name == "Europe/Zagreb":
            return Self.EUROPE_ZAGREB
        elif name == "Antarctica/Palmer":
            return Self.ANTARCTICA_PALMER
        elif name == "America/Cayenne":
            return Self.AMERICA_CAYENNE
        elif name == "Asia/Tel_Aviv":
            return Self.ASIA_TEL_AVIV
        elif name == "Asia/Urumqi":
            return Self.ASIA_URUMQI
        elif name == "Asia/Beirut":
            return Self.ASIA_BEIRUT
        elif name == "Asia/Kuala_Lumpur":
            return Self.ASIA_KUALA_LUMPUR
        elif name == "America/Belem":
            return Self.AMERICA_BELEM
        elif name == "Pacific/Honolulu":
            return Self.PACIFIC_HONOLULU
        elif name == "America/Santa_Isabel":
            return Self.AMERICA_SANTA_ISABEL
        elif name == "Pacific/Kwajalein":
            return Self.PACIFIC_KWAJALEIN
        elif name == "Africa/Luanda":
            return Self.AFRICA_LUANDA
        elif name == "America/Chicago":
            return Self.AMERICA_CHICAGO
        elif name == "Asia/Harbin":
            return Self.ASIA_HARBIN
        elif name == "Europe/Paris":
            return Self.EUROPE_PARIS
        elif name == "Pacific/Wallis":
            return Self.PACIFIC_WALLIS
        elif name == "America/Argentina/Ushuaia":
            return Self.AMERICA_ARGENTINA_USHUAIA
        elif name == "Australia/Adelaide":
            return Self.AUSTRALIA_ADelaide
        elif name == "Asia/Singapore":
            return Self.ASIA_SINGAPORE
        elif name == "America/Kralendijk":
            return Self.AMERICA_KRALENDIJK
        elif name == "America/Moncton":
            return Self.AMERICA_MONCTON
        elif name == "America/Aruba":
            return Self.AMERICA_ARUBA
        elif name == "America/Noronha":
            return Self.AMERICA_NORONHA
        elif name == "Etc/UTC":
            return Self.ETC_UTC
        elif name == "Africa/Lusaka":
            return Self.AFRICA_LUSAKA
        elif name == "Asia/Tomsk":
            return Self.ASIA_TOMSK
        elif name == "Asia/Phnom_Penh":
            return Self.ASIA_PHNOM_PENH
        elif name == "Asia/Samarkand":
            return Self.ASIA_SAMARKAND
        elif name == "Europe/Luxembourg":
            return Self.EUROPE_LUXEMBOURG
        elif name == "Indian/Antananarivo":
            return Self.INDIAN_ANTANANARIVO
        elif name == "Etc/GMT+1":
            return Self.ETC_GMT_PLUS_1
        elif name == "America/Porto_Velho":
            return Self.AMERICA_PORTO_VELHO
        elif name == "GB":
            return Self.GB
        elif name == "America/Barbados":
            return Self.AMERICA_BARbADOS
        elif name == "Asia/Chungking":
            return Self.ASIA_CHUNGKING
        elif name == "Asia/Shanghai":
            return Self.ASIA_SHANGHAI
        elif name == "Etc/GMT-13":
            return Self.ETC_GMT_13
        elif name == "America/Indiana/Indianapolis":
            return Self.AMERICA_INDIANA_INDIANAPOLIS
        elif name == "America/Argentina/Mendoza":
            return Self.AMERICA_ARGENTINA_MENDOZA
        elif name == "America/Jamaica":
            return Self.AMERICA_JAMAICA
        elif name == "Canada/Newfoundland":
            return Self.CANADA_NEWFOUNDLAND
        elif name == "America/Cordoba":
            return Self.AMERICA_CORDOBA
        elif name == "Africa/Niamey":
            return Self.AFRICA_NIAMEY
        elif name == "America/Halifax":
            return Self.AMERICA_HALIFAX
        elif name == "Antarctica/South_Pole":
            return Self.ANTARCTICA_SOUTH_POLE
        elif name == "Africa/Ouagadougou":
            return Self.AFRICA_OUAGADOUGOU
        elif name == "CET":
            return Self.CET
        elif name == "America/Argentina/San_Juan":
            return Self.AMERICA_ARGENTINA_SAN_JUAN
        elif name == "Asia/Almaty":
            return Self.ASIA_ALMATY
        elif name == "Antarctica/Vostok":
            return Self.ANTARCTICA_VOSTOK
        elif name == "Canada/Atlantic":
            return Self.CANADA_ATLANTIC
        elif name == "Europe/Amsterdam":
            return Self.EUROPE_AMSTERDAM
        elif name == "America/Costa_Rica":
            return Self.AMERICA_COSTA_RICA
        elif name == "America/Knox_IN":
            return Self.AMERICA_KNOX_IN
        elif name == "Asia/Pontianak":
            return Self.ASIA_PONTIANAK
        elif name == "America/Punta_Arenas":
            return Self.AMERICA_PUNTA_ARENAS
        elif name == "Indian/Mahe":
            return Self.INDIAN_MAHE
        elif name == "Africa/Timbuktu":
            return Self.AFRICA_TIMBUKTU
        elif name == "Atlantic/Madeira":
            return Self.ATLANTIC_MADEIRA
        elif name == "Chile/EasterIsland":
            return Self.CHILE_EASTERISLAND
        elif name == "Atlantic/Stanley":
            return Self.ATLANTIC_STANLEY
        elif name == "America/Cancun":
            return Self.AMERICA_CANCUN
        elif name == "Europe/Minsk":
            return Self.EUROPE_MINSK
        elif name == "US/Eastern":
            return Self.US_EASTERN
        elif name == "HST":
            return Self.HST
        elif name == "America/Boise":
            return Self.AMERICA_BOISE
        elif name == "Brazil/West":
            return Self.BRAZIL_WEST
        elif name == "America/Catamarca":
            return Self.AMERICA_CATAMARCA
        elif name == "America/Port_of_Spain":
            return Self.AMERICA_PORT_OF_SPAIN
        elif name == "Asia/Katmandu":
            return Self.ASIA_KATMANDU
        elif name == "Etc/GMT-14":
            return Self.ETC_GMT_MINUS_14
        elif name == "America/Guayaquil":
            return Self.AMERICA_GUAYAQUIL
        elif name == "Australia/Canberra":
            return Self.AUSTRALIA_CANBERRA
        elif name == "America/Ojinaga":
            return Self.AMERICA_OJINAGA
        elif name == "Europe/Kyiv":
            return Self.EUROPE_KYIV
        elif name == "Africa/Kinshasa":
            return Self.AFRICA_KINSHASA
        elif name == "Pacific/Pohnpei":
            return Self.PACIFIC_POHNPEI
        elif name == "America/Indiana/Winamac":
            return Self.AMERICA_INDIANA_WINAMAC
        elif name == "Etc/GMT-11":
            return Self.ETC_GMT_MINUS_11
        elif name == "Asia/Dhaka":
            return Self.ASIA_DHAKA
        elif name == "Australia/Perth":
            return Self.AUSTRALIA_PERTH
        elif name == "America/Whitehorse":
            return Self.AMERICA_WHITEHORSE
        elif name == "Indian/Reunion":
            return Self.INDIAN_REUNION
        elif name == "Europe/London":
            return Self.EUROPE_LONDON
        elif name == "Navajo":
            return Self.NAVAJO
        elif name == "America/Manaus":
            return Self.AMERICA_MANAUS
        elif name == "Asia/Chita":
            return Self.ASIA_CHITA
        elif name == "Hongkong":
            return Self.HONGKONG
        elif name == "Africa/Bissau":
            return Self.AFRICA_BISSAU
        elif name == "America/Tortola":
            return Self.AMERICA_TORTOLA
        elif name == "America/Juneau":
            return Self.AMERICA_JUNEAU
        elif name == "Europe/Malta":
            return Self.EUROPE_MALTA
        elif name == "Pacific/Ponape":
            return Self.PACIFIC_PONAPE
        elif name == "Africa/Asmara":
            return Self.AFRICA_ASMARA
        elif name == "Asia/Kamchatka":
            return Self.ASIA_KAMCHATKA
        elif name == "Europe/Helsinki":
            return Self.EUROPE_HELSINKI
        elif name == "America/Los_Angeles":
            return Self.AMERICA_LOS_ANGELES
        elif name == "Etc/GMT-4":
            return Self.ETC_GMT_MINUS_4
        elif name == "America/Bahia":
            return Self.AMERICA_BAHIA
        elif name == "America/Port-au-Prince":
            return Self.AMERICA_PORT_AU_PRINCE
        elif name == "Europe/Vilnius":
            return Self.EUROPE_VILNIUS
        elif name == "Etc/GMT-1":
            return Self.ETC_GMT_MINUS_1
        elif name == "Europe/Jersey":
            return Self.EUROPE_JERSEY
        elif name == "Africa/Tunis":
            return Self.AFRICA_TUNIS
        elif name == "Mexico/BajaSur":
            return Self.MEXICO_BAJASUR
        elif name == "Pacific/Tarawa":
            return Self.PACIFIC_TARAWA
        elif name == "Canada/Yukon":
            return Self.CANADA_YUKON
        elif name == "America/Virgin":
            return Self.AMERICA_VIRGIN
        elif name == "Europe/Budapest":
            return Self.EUROPE_BUDAPEST
        elif name == "America/Jujuy":
            return Self.AMERICA_JUJUY
        elif name == "Africa/Juba":
            return Self.AFRICA_JUBA
        elif name == "America/Indiana/Tell_City":
            return Self.AMERICA_INDiana_TELL_CITY
        elif name == "Pacific/Kanton":
            return Self.PACIFIC_KANTON
        elif name == "America/Nassau":
            return Self.AMERICA_NASSAU
        elif name == "America/Rio_Branco":
            return Self.AMERICA_RIO_BRANCO
        elif name == "GMT-0":
            return Self.GMT_MINUS_0
        elif name == "Australia/Tasmania":
            return Self.AUSTRALIA_TASMANIA
        elif name == "Pacific/Kosrae":
            return Self.PACIFIC_KOSRAE
        elif name == "US/Hawaii":
            return Self.US_HAWAII
        elif name == "Asia/Tbilisi":
            return Self.ASIA_TBILISI
        elif name == "Pacific/Bougainville":
            return Self.PACIFIC_BOUGAINVILLE
        elif name == "Europe/Vaduz":
            return Self.EUROPE_VADUZ
        elif name == "Etc/GMT+11":
            return Self.ETC_GMT_PLUS_11
        elif name == "Africa/Windhoek":
            return Self.AFRICA_WINDHOEK
        elif name == "Atlantic/Jan_Mayen":
            return Self.ATLANTIC_JAN_MAYEN
        elif name == "Africa/Ndjamena":
            return Self.AFRICA_NDJAMENA
        elif name == "America/Adak":
            return Self.AMERICA_ADAK
        elif name == "Israel":
            return Self.ISRAEL
        elif name == "US/Indiana-Starke":
            return Self.US_INDiana_STARKE
        elif name == "America/North_Dakota/New_Salem":
            return Self.AMERICA_NORTH_DAKOTA_NEW_SALEM
        elif name == "Pacific/Palau":
            return Self.PACIFIC_PALAU
        elif name == "GMT+0":
            return Self.GMT_PLUS_0
        elif name == "America/Rainy_River":
            return Self.AMERICA_RAINY_RIVER
        elif name == "America/Winnipeg":
            return Self.AMERICA_WINNIPEG
        elif name == "Etc/Greenwich":
            return Self.ETC_GREENWICH
        elif name == "America/Pangnirtung":
            return Self.AMERICA_PANGNIRTUNG
        elif name == "Africa/Tripoli":
            return Self.AFRICA_TRIPOLI
        elif name == "America/Guatemala":
            return Self.AMERICA_GUATEMALA
        elif name == "Asia/Nicosia":
            return Self.ASIA_NICOSIA
        elif name == "America/Belize":
            return Self.AMERICA_BELIZE
        elif name == "America/Resolute":
            return Self.AMERICA_RESOLUTE
        elif name == "Asia/Hebron":
            return Self.ASIA_HEBRON
        elif name == "America/Caracas":
            return Self.AMERICA_CARACAS
        elif name == "Asia/Novosibirsk":
            return Self.ASIA_NOVOSIBIRSK
        elif name == "Europe/Podgorica":
            return Self.EUROPE_PODGORICA
        elif name == "PRC":
            return Self.PRC
        elif name == "Europe/Kaliningrad":
            return Self.EUROPE_KALININGRAD
        elif name == "Europe/Zurich":
            return Self.EUROPE_ZURICH
        elif name == "America/St_Barthelemy":
            return Self.AMERICA_ST_BARTHELEMY
        elif name == "America/Nuuk":
            return Self.AMERICA_NUUK
        elif name == "Etc/GMT+12":
            return Self.ETC_GMT_PLUS_12
        elif name == "Asia/Hong_Kong":
            return Self.ASIA_HONG_KONG
        elif name == "Etc/GMT-3":
            return Self.ETC_GMT_MINUS_3
        elif name == "America/Miquelon":
            return Self.AMERICA_MIQUELON
        elif name == "Europe/Volgograd":
            return Self.EUROPE_VOLGOGRAD
        elif name == "Europe/Madrid":
            return Self.EUROPE_MADRID
        elif name == "America/Monterrey":
            return Self.AMERICA_MONTERREY
        elif name == "America/Anchorage":
            return Self.AMERICA_ANCHORAGE
        elif name == "America/Argentina/San_Luis":
            return Self.AMERICA_ARGENTINA_SAN_LUIS
        elif name == "America/Eirunepe":
            return Self.AMERICA_EIRUNEPE
        elif name == "America/St_Kitts":
            return Self.AMERICA_ST_KITTS
        elif name == "America/Bahia_Banderas":
            return Self.AMERICA_BAHIA_BANDERAS
        elif name == "Etc/GMT+2":
            return Self.ETC_GMT_PLUS_2
        elif name == "Zulu":
            return Self.ZULU
        elif name == "Africa/Gaborone":
            return Self.AFRICA_GABORONE
        elif name == "Antarctica/McMurdo":
            return Self.ANTARCTICA_MCMURDO
        elif name == "Europe/Guernsey":
            return Self.EUROPE_GUERNSEY
        elif name == "Europe/Andorra":
            return Self.EUROPE_ANDORRA
        elif name == "America/Paramaribo":
            return Self.AMERICA_PARAMARIBO
        elif name == "America/Fort_Nelson":
            return Self.AMERICA_FORT_NELSON
        elif name == "Antarctica/Troll":
            return Self.ANTARCTICA_TROLL
        elif name == "Europe/Uzhgorod":
            return Self.EUROPE_UZHGOROD
        elif name == "Atlantic/Cape_Verde":
            return Self.ATLANTIC_CAPE_VERDE
        elif name == "UCT":
            return Self.UCT
        elif name == "Etc/GMT-6":
            return Self.ETC_GMT_MINUS_6
        elif name == "Asia/Srednekolymsk":
            return Self.ASIA_SREDNEKOLYMSK
        elif name == "Asia/Ujung_Pandang":
            return Self.ASIA_UJUNG_PANDANG
        elif name == "America/Thunder_Bay":
            return Self.AMERICA_THUNDER_BAY
        elif name == "Africa/Khartoum":
            return Self.AFRICA_KHARTOUM
        elif name == "Africa/Douala":
            return Self.AFRICA_DOUALA
        elif name == "America/Cayman":
            return Self.AMERICA_CAYMAN
        elif name == "Brazil/Acre":
            return Self.BRAZIL_ACRE
        elif name == "America/Indiana/Knox":
            return Self.AMERICA_INDIANA_KNOX
        elif name == "Australia/Yancowinna":
            return Self.AUSTRALIA_YANCOWINNA
        elif name == "America/Chihuahua":
            return Self.AMERICA_CHIHUAHUA
        elif name == "America/Recife":
            return Self.AMERICA_RECIFE
        elif name == "America/Indiana/Marengo":
            return Self.AMERICA_INDIANA_MARENGO
        elif name == "Asia/Yangon":
            return Self.ASIA_YANGON
        elif name == "Europe/Astrakhan":
            return Self.EUROPE_ASTRAKHAN
        elif name == "Asia/Rangoon":
            return Self.ASIA_RANGOON
        elif name == "America/Vancouver":
            return Self.AMERICA_VANCOUVER
        elif name == "NZ-CHAT":
            return Self.NZ_CHAT
        elif name == "America/Montserrat":
            return Self.AMERICA_MONTERRAT
        elif name == "America/Merida":
            return Self.AMERICA_MERIDA
        elif name == "America/Puerto_Rico":
            return Self.AMERICA_PUERTO_RICO
        elif name == "America/Maceio":
            return Self.AMERICA_MACEIO
        elif name == "America/Panama":
            return Self.AMERICA_PANAMA
        elif name == "Brazil/East":
            return Self.BRAZIL_EAST
        elif name == "Japan":
            return Self.JAPAN
        elif name == "Australia/Victoria":
            return Self.AUSTRALIA_VICTORIA
        elif name == "America/Indiana/Petersburg":
            return Self.AMERICA_INDIANA_PETERSBURG
        elif name == "Asia/Dushanbe":
            return Self.ASIA_DUSHANBE
        elif name == "Africa/Asmera":
            return Self.AFRICA_ASMERA
        elif name == "Etc/Zulu":
            return Self.ETC_ZULU
        elif name == "Europe/Monaco":
            return Self.EUROPE_MONACO
        elif name == "Asia/Amman":
            return Self.ASIA_AMMAN
        elif name == "Asia/Kuwait":
            return Self.ASIA_KUWAIT
        elif name == "Asia/Sakhalin":
            return Self.ASIA_SAKHALIN
        elif name == "Europe/Gibraltar":
            return Self.EUROPE_GIBRALTAR
        elif name == "America/Havana":
            return Self.AMERICA_HAVANA
        elif name == "Etc/GMT+0":
            return Self.ETC_GMT_PLUS_0
        elif name == "Asia/Choibalsan":
            return Self.ASIA_CHOIBALSAN
        elif name == "Asia/Vientiane":
            return Self.ASIA_VIENTIANE
        elif name == "Africa/Monrovia":
            return Self.AFRICA_MONROVIA
        elif name == "Africa/Lagos":
            return Self.AFRICA_LAGOS
        elif name == "America/Argentina/Buenos_Aires":
            return Self.AMERICA_ARGENTINA_BUENOS_AIRES
        elif name == "Australia/Melbourne":
            return Self.AUSTRALIA_MELBOURNE
        elif name == "Etc/GMT+6":
            return Self.ETC_GMT_PLUS_6
        elif name == "PST8PDT":
            return Self.PST8PDT
        elif name == "America/Scoresbysund":
            return Self.AMERICA_SCORESBYSUND
        elif name == "Australia/ACT":
            return Self.AUSTRALIA_ACT
        elif name == "Africa/Blantyre":
            return Self.AFRICA_BLANTYRE
        elif name == "Asia/Saigon":
            return Self.ASIA_SAIGON
        elif name == "Asia/Chongqing":
            return Self.ASIA_CHONGQING
        elif name == "GB-Eire":
            return Self.GB_EIRE
        elif name == "US/Samoa":
            return Self.US_SAMOA
        elif name == "Arctic/Longyearbyen":
            return Self.ARCTIC_LONGYEARBYEN
        elif name == "America/Curacao":
            return Self.AMERICA_CURACAO
        elif name == "America/Mexico_City":
            return Self.AMERICA_MEXICO_CITY
        elif name == "Asia/Kabul":
            return Self.ASIA_KABUL
        elif name == "America/Indianapolis":
            return Self.AMERICA_INDIANAPOLIS
        elif name == "Asia/Macao":
            return Self.ASIA_MACAO
        elif name == "Canada/Central":
            return Self.CANADA_CENTRAL
        elif name == "Asia/Famagusta":
            return Self.ASIA_FAMAGUSTA
        elif name == "America/Atikokan":
            return Self.AMERICA_ATIKOKAN
        elif name == "Asia/Brunei":
            return Self.ASIA_BRUNEI
        elif name == "Asia/Ust-Nera":
            return Self.ASIA_UST_NERA
        elif name == "Brazil/DeNoronha":
            return Self.BRAZIL_DE_NORONHA
        elif name == "Indian/Chagos":
            return Self.INDIAN_CHAGOS
        elif name == "Asia/Kathmandu":
            return Self.ASIA_KATHMANDU
        elif name == "Asia/Tehran":
            return Self.ASIA_TEHRAN
        elif name == "Africa/Dar_es_Salaam":
            return Self.AFRICA_DAR_ES_SALAAM
        elif name == "America/Managua":
            return Self.AMERICA_MANAGUA
        elif name == "Africa/Cairo":
            return Self.AFRICA_CAIRO
        elif name == "Pacific/Nauru":
            return Self.PACIFIC_NAURU
        elif name == "Europe/Saratov":
            return Self.EUROPE_SARATOV
        elif name == "Indian/Maldives":
            return Self.INDIAN_MALDIVES
        elif name == "Asia/Makassar":
            return Self.ASIA_MAKASSAR
        elif name == "America/Sao_Paulo":
            return Self.AMERICA_SAO_PAULO
        elif name == "America/St_Johns":
            return Self.AMERICA_ST_JOHNS
        elif name == "Etc/GMT+9":
            return Self.ETC_GMT_PLUS_9
        elif name == "Asia/Qyzylorda":
            return Self.ASIA_QYZYLORDA
        elif name == "Australia/North":
            return Self.AUSTRALIA_NORTH
        elif name == "America/Montevideo":
            return Self.AMERICA_MONTEVIDEO
        elif name == "Australia/West":
            return Self.AUSTRALIA_WEST
        elif name == "Europe/Oslo":
            return Self.EUROPE_OSLO
        elif name == "Turkey":
            return Self.TURKEY
        elif name == "US/Central":
            return Self.US_CENTRAL
        elif name == "Europe/Berlin":
            return Self.EUROPE_BERLIN
        elif name == "Europe/Bratislava":
            return Self.EUROPE_BRATISLAVA
        elif name == "America/El_Salvador":
            return Self.AMERICA_EL_SALVADOR
        elif name == "Africa/Kampala":
            return Self.AFRICA_KAMPALA
        elif name == "America/Dawson":
            return Self.AMERICA_DAWSON
        elif name == "America/La_Paz":
            return Self.AMERICA_LA_PAZ
        elif name == "US/Aleutian":
            return Self.US_ALEUTIAN
        elif name == "Asia/Kolkata":
            return Self.ASIA_KOLKATA
        elif name == "Asia/Oral":
            return Self.ASIA_ORAL
        elif name == "Asia/Omsk":
            return Self.ASIA_OMSK
        elif name == "America/Santiago":
            return Self.AMERICA_SANTIAGO
        elif name == "America/Detroit":
            return Self.AMERICA_DETROIT
        elif name == "America/Anguilla":
            return Self.AMERICA_ANGUILLA
        elif name == "America/Nome":
            return Self.AMERICA_NOME
        elif name == "Singapore":
            return Self.SINGAPORE
        elif name == "Africa/Conakry":
            return Self.AFRICA_CONAKRY
        elif name == "Africa/Maputo":
            return Self.AFRICA_MAPUTO
        elif name == "Antarctica/Davis":
            return Self.ANTARCTICA_DAVIS
        elif name == "Asia/Manila":
            return Self.ASIA_MANILA
        elif name == "Pacific/Majuro":
            return Self.PACIFIC_MAJURO
        elif name == "Africa/Lubumbashi":
            return Self.AFRICA_LUBUMBASHI
        elif name == "Portugal":
            return Self.PORTUGAL
        elif name == "Pacific/Port_Moresby":
            return Self.PACIFIC_PORT_MORESBY
        elif name == "Etc/GMT+3":
            return Self.ETC_GMT_PLUS_3
        elif name == "Chile/Continental":
            return Self.CHILE_CONTINENTAL
        elif name == "GMT":
            return Self.GMT
        elif name == "America/Martinique":
            return Self.AMERICA_MARTINIQUE
        elif name == "Africa/Sao_Tome":
            return Self.AFRICA_SAO_TOME
        elif name == "America/Sitka":
            return Self.AMERICA_SITKA
        elif name == "Asia/Taipei":
            return Self.ASIA_TAIPEI
        elif name == "Indian/Mayotte":
            return Self.INDIAN_MAYOTTE
        elif name == "America/Argentina/Rio_Gallegos":
            return Self.AMERICA_ARGENTINA_RIO_GALLEGOS
        elif name == "America/Menominee":
            return Self.AMERICA_MENOMINEE
        elif name == "Canada/Pacific":
            return Self.CANADA_PACIFIC
        elif name == "MET":
            return Self.MET
        elif name == "Asia/Thimbu":
            return Self.ASIA_THIMBU
        elif name == "America/Campo_Grande":
            return Self.AMERICA_CAMPO_GRANDE
        elif name == "Asia/Magadan":
            return Self.ASIA_MAGADAN
        elif name == "Africa/Casablanca":
            return Self.AFRICA_CASABLANCA
        elif name == "America/Guadeloupe":
            return Self.AMERICA_GUADELOUPE
        elif name == "Atlantic/Faroe":
            return Self.ATLANTIC_FAROE
        elif name == "Asia/Anadyr":
            return Self.ASIA_ANADYR
        elif name == "Africa/Porto-Novo":
            return Self.AFRICA_PORTO_NOVO
        elif name == "Africa/Banjul":
            return Self.AFRICA_BANJUL
        elif name == "Indian/Comoro":
            return Self.INDIAN_COMORO
        elif name == "America/Yakutat":
            return Self.AMERICA_YAKUTAT
        elif name == "Pacific/Gambier":
            return Self.PACIFIC_GAMBIER
        elif name == "Asia/Ashgabat":
            return Self.ASIA_ASHGABAT
        elif name == "Antarctica/DumontDUrville":
            return Self.ANTARCTICA_DUMONT_DURVILLE
        elif name == "US/East-Indiana":
            return Self.US_EAST_IND
        elif name == "Asia/Irkutsk":
            return Self.ASIA_IRKUTSK
        elif name == "America/Mazatlan":
            return Self.AMERICA_MAZATLAN
        elif name == "Pacific/Apia":
            return Self.PACIFIC_APIA
        elif name == "America/Boa_Vista":
            return Self.AMERICA_BOA_VISTA
        elif name == "Etc/GMT":
            return Self.ETC_GMT
        elif name == "America/Guyana":
            return Self.AMERICA_GUYANA
        elif name == "Australia/Currie":
            return Self.AUSTRALIA_CURRIE
        elif name == "Europe/Ulyanovsk":
            return Self.EUROPE_ULYANOVSK
        elif name == "Pacific/Fakaofo":
            return Self.PACIFIC_FAKAOFO
        elif name == "America/North_Dakota/Beulah":
            return Self.AMERICA_NORTH_DAKOTA_BEULAH
        elif name == "Europe/Prague":
            return Self.EUROPE_PRAGUE
        elif name == "Asia/Qatar":
            return Self.ASIA_QATAR
        elif name == "Pacific/Funafuti":
            return Self.PACIFIC_FUNAFUTI
        elif name == "Jamaica":
            return Self.JAMAICA
        elif name == "Canada/Eastern":
            return Self.CANADA_EASTERN
        elif name == "Pacific/Guam":
            return Self.PACIFIC_GUAM
        elif name == "Pacific/Fiji":
            return Self.PACIFIC_FIJI
        elif name == "Africa/Kigali":
            return Self.AFRICA_KIGALI
        elif name == "Pacific/Tongatapu":
            return Self.PACIFIC_TONGATAPU
        elif name == "America/Lima":
            return Self.AMERICA_LIMA
        elif name == "Asia/Muscat":
            return Self.ASIA_MUSCAT
        elif name == "Antarctica/Macquarie":
            return Self.ANTARCTICA_MACQUARIE
        elif name == "Etc/GMT-2":
            return Self.ETC_GMT_MINUS_2
        elif name == "Pacific/Pitcairn":
            return Self.PACIFIC_PITCAIRN
        elif name == "Canada/Mountain":
            return Self.CANADA_MOUNTAIN
        elif name == "Asia/Yekaterinburg":
            return Self.ASIA_YEKATERINBURG
        elif name == "Pacific/Johnston":
            return Self.PACIFIC_JOHNSTON
        elif name == "Europe/Vatican":
            return Self.EUROPE_VATICAN
        elif name == "Atlantic/Bermuda":
            return Self.ATLANTIC_BERMUDA
        elif name == "Asia/Jerusalem":
            return Self.ASIA_JERUSALEM
        elif name == "America/Ciudad_Juarez":
            return Self.AMERICA_CIUDAD_JUAREZ
        elif name == "Pacific/Galapagos":
            return Self.PACIFIC_GALAPAGOS
        elif name == "America/Montreal":
            return Self.AMERICA_MONTREAL
        elif name == "Africa/Nouakchott":
            return Self.AFRICA_NOUAKCHOTT
        elif name == "US/Arizona":
            return Self.US_ARIZONA
        elif name == "Asia/Kuching":
            return Self.ASIA_KUCHING
        elif name == "Etc/GMT+4":
            return Self.ETC_GMT_PLUS_4
        elif name == "Australia/Brisbane":
            return Self.AUSTRALIA_BRISBANE
        elif name == "Canada/Saskatchewan":
            return Self.CANADA_SASKATCHEWAN
        elif name == "Europe/Dublin":
            return Self.EUROPE_DUBLIN
        elif name == "Asia/Qostanay":
            return Self.ASIA_QOSTANAY
        elif name == "America/Edmonton":
            return Self.AMERICA_EDMONTON
        elif name == "Atlantic/Reykjavik":
            return Self.ATLANTIC_REYKJAVIK
        elif name == "America/Fortaleza":
            return Self.AMERICA_FORTALEZA
        elif name == "Pacific/Kiritimati":
            return Self.PACIFIC_KIRITIMATI
        elif name == "Etc/Universal":
            return Self.ETC_UNIVERSAL
        elif name == "GMT0":
            return Self.GMT0
        elif name == "Europe/Belfast":
            return Self.EUROPE_BELFAST
        elif name == "Pacific/Yap":
            return Self.PACIFIC_YAP
        elif name == "America/Santo_Domingo":
            return Self.AMERICA_SANTO_DOMINGO
        elif name == "Iceland":
            return Self.ICELAND
        elif name == "America/Araguaina":
            return Self.AMERICA_ARAGUAINA
        elif name == "Asia/Karachi":
            return Self.ASIA_KARACHI
        elif name == "Etc/GMT+7":
            return Self.ETC_GMT_PLUS_7
        elif name == "Africa/Bujumbura":
            return Self.AFRICA_BUJUMBURA
        elif name == "America/Dawson_Creek":
            return Self.AMERICA_DAWSON_CREEK
        elif name == "Europe/Zaporozhye":
            return Self.EUROPE_ZAPOROZHYE
        elif name == "Asia/Ulaanbaatar":
            return Self.ASIA_ULAANBAATAR
        elif name == "Pacific/Samoa":
            return Self.PACIFIC_SAMOA
        elif name == "Australia/Darwin":
            return Self.AUSTRALIA_DARWIN
        elif name == "Etc/GMT0":
            return Self.ETC_GMT0
        elif name == "Pacific/Tahiti":
            return Self.PACIFIC_TAHITI
        elif name == "Etc/GMT-8":
            return Self.ETC_GMT_MINUS_8
        elif name == "Atlantic/Faeroe":
            return Self.ATLANTIC_FAEROE
        elif name == "Africa/Libreville":
            return Self.AFRICA_LIBREVILLE
        elif name == "Asia/Barnaul":
            return Self.ASIA_BARNAUL
        elif name == "America/Coral_Harbour":
            return Self.AMERICA_CORAL_HARBOUR
        elif name == "Antarctica/Syowa":
            return Self.ANTARCTICA_SYOWA
        elif name == "America/Buenos_Aires":
            return Self.AMERICA_BUENOS_AIRES
        elif name == "Europe/Vienna":
            return Self.EUROPE_VIENNA
        elif name == "America/Fort_Wayne":
            return Self.AMERICA_FORT_WAYNE
        elif name == "NZ":
            return Self.NZ
        elif name == "Atlantic/Azores":
            return Self.ATLANTIC_AZORES
        elif name == "America/Coyhaique":
            return Self.AMERICA_COYHAIQUE
        elif name == "Asia/Pyongyang":
            return Self.ASIA_PYONGYANG
        elif name == "Etc/GMT-10":
            return Self.ETC_GMT_MINUS_10
        elif name == "MST":
            return Self.MST
        elif name == "America/Argentina/Jujuy":
            return Self.AMERICA_ARGENTINA_JUJUY
        elif name == "America/Tijuana":
            return Self.AMERICA_TIJUANA
        elif name == "Pacific/Guadalcanal":
            return Self.PACIFIC_GUADALCANAL
        elif name == "Europe/Stockholm":
            return Self.EUROPE_STOCKHOLM
        elif name == "US/Alaska":
            return Self.US_ALASKA
        elif name == "Europe/Tiraspol":
            return Self.EUROPE_TIRASPOL
        elif name == "Europe/Samara":
            return Self.EUROPE_SAMARA
        elif name == "Etc/GMT-12":
            return Self.ETC_GMT_MINUS_12
        elif name == "Kwajalein":
            return Self.KWAJALEIN
        elif name == "Asia/Macau":
            return Self.ASIA_MACAU
        elif name == "Pacific/Truk":
            return Self.PACIFIC_TRUK
        elif name == "Asia/Bangkok":
            return Self.ASIA_BANGKOK
        elif name == "America/Antigua":
            return Self.AMERICA_ANTIGUA
        elif name == "Africa/El_Aaiun":
            return Self.AFRICA_EL_AAIUN
        elif name == "Europe/Mariehamn":
            return Self.EUROPE_MARIEHAMN
        elif name == "Asia/Jayapura":
            return Self.ASIA_JAYAPURA
        elif name == "Europe/San_Marino":
            return Self.EUROPE_SAN_MARINO
        elif name == "US/Pacific":
            return Self.US_PACIFIC
        elif name == "Africa/Johannesburg":
            return Self.AFRICA_JOHANNESBURG
        elif name == "Australia/Eucla":
            return Self.AUSTRALIA_EUCLA
        elif name == "Africa/Nairobi":
            return Self.AFRICA_NAIROBI
        elif name == "Etc/GMT-7":
            return Self.ETC_GMT_MINUS_7
        elif name == "America/Inuvik":
            return Self.AMERICA_INUVIK
        elif name == "Asia/Tokyo":
            return Self.ASIA_TOKYO
        elif name == "Asia/Atyrau":
            return Self.ASIA_ATYRAU
        elif name == "Asia/Kashgar":
            return Self.ASIA_KASHGAR
        elif name == "W-SU":
            return Self.W_SU
        elif name == "Asia/Tashkent":
            return Self.ASIA_TASHKENT
        elif name == "Africa/Freetown":
            return Self.AFRICA_FREETOWN
        elif name == "Pacific/Pago_Pago":
            return Self.PACIFIC_PAGO_PAGO
        elif name == "America/Denver":
            return Self.AMERICA_DENVER
        elif name == "Australia/LHI":
            return Self.AUSTRALIA_LHI
        elif name == "Pacific/Rarotonga":
            return Self.PACIFIC_RAROTONGA
        elif name == "MST7MDT":
            return Self.MST7MDT
        elif name == "Pacific/Noumea":
            return Self.PACIFIC_NOUMEA
        elif name == "Etc/UCT":
            return Self.ETC_UCT
        elif name == "Etc/GMT+10":
            return Self.ETC_GMT_PLUS_10
        elif name == "ROK":
            return Self.ROK
        elif name == "Pacific/Auckland":
            return Self.PACIFIC_AUCKLAND
        elif name == "Asia/Novokuznetsk":
            return Self.ASIA_NOVOKUZNETSK
        elif name == "America/Hermosillo":
            return Self.AMERICA_HERMOSILLO
        elif name == "America/Louisville":
            return Self.AMERICA_LOUISVILLE
        elif name == "Asia/Ho_Chi_Minh":
            return Self.ASIA_HO_CHI_MINH
        elif name == "Asia/Yerevan":
            return Self.ASIA_YEREVAN
        elif name == "Asia/Yakutsk":
            return Self.ASIA_YAKUTSK
        elif name == "Universal":
            return Self.UNIVERSAL
        elif name == "America/Tegucigalpa":
            return Self.AMERICA_TEGUCIGALPA
        elif name == "Mexico/BajaNorte":
            return Self.MEXICO_BAJANORTE
        elif name == "Europe/Sarajevo":
            return Self.EUROPE_SARAJEVO
        elif name == "America/Argentina/Catamarca":
            return Self.AMERICA_ARGENTINA_CATAMARCA
        elif name == "Cuba":
            return Self.CUBA
        elif name == "Asia/Khandyga":
            return Self.ASIA_KHANDYGA
        elif name == "America/Lower_Princes":
            return Self.AMERICA_LOWER_PRINCES
        elif name == "America/Blanc-Sablon":
            return Self.AMERICA_BLANC_SABLON
        elif name == "America/Bogota":
            return Self.AMERICA_BOGOTA
        elif name == "Africa/Lome":
            return Self.AFRICA_LOME
        elif name == "America/Toronto":
            return Self.AMERICA_TORONTO
        elif name == "Europe/Warsaw":
            return Self.EUROPE_WARSAW
        elif name == "America/Yellowknife":
            return Self.AMERICA_YELLOWKNIFE
        elif name == "America/Swift_Current":
            return Self.AMERICA_SWIFT_CURRENT
        elif name == "EST":
            return Self.EST
        elif name == "Europe/Sofia":
            return Self.EUROPE_SOFIA
        elif name == "Africa/Ceuta":
            return Self.AFRICA_CEUTA
        elif name == "America/Marigot":
            return Self.AMERICA_MARIGOT
        elif name == "America/Danmarkshavn":
            return Self.AMERICA_DANMARKSHAVN
        elif name == "Africa/Harare":
            return Self.AFRICA_HARARE
        elif name == "UTC":
            return Self.UTC
        elif name == "UTC+1":
            return Self.UTC_PLUS_1
        elif name == "UTC+2":
            return Self.UTC_PLUS_2
        elif name == "UTC+3":
            return Self.UTC_PLUS_3
        elif name == "UTC+4":
            return Self.UTC_PLUS_4
        elif name == "UTC+5":
            return Self.UTC_PLUS_5
        elif name == "UTC+6":
            return Self.UTC_PLUS_6
        elif name == "UTC+7":
            return Self.UTC_PLUS_7
        elif name == "UTC+8":
            return Self.UTC_PLUS_8
        elif name == "UTC+9":
            return Self.UTC_PLUS_9
        elif name == "UTC+10":
            return Self.UTC_PLUS_10
        elif name == "UTC+11":
            return Self.UTC_PLUS_11
        elif name == "UTC+12":
            return Self.UTC_PLUS_12
        elif name == "UTC-1":
            return Self.UTC_MINUS_1
        elif name == "UTC-2":
            return Self.UTC_MINUS_2
        elif name == "UTC-3":
            return Self.UTC_MINUS_3
        elif name == "UTC-4":
            return Self.UTC_MINUS_4
        elif name == "UTC-5":
            return Self.UTC_MINUS_5
        elif name == "UTC-6":
            return Self.UTC_MINUS_6
        elif name == "UTC-7":
            return Self.UTC_MINUS_7
        elif name == "UTC-8":
            return Self.UTC_MINUS_8
        elif name == "UTC-9":
            return Self.UTC_MINUS_9
        elif name == "UTC-10":
            return Self.UTC_MINUS_10
        elif name == "UTC-11":
            return Self.UTC_MINUS_11
        elif name == "UTC-12":
            return Self.UTC_MINUS_12
        elif name == "EST5EDT":
            return Self.EST5EDT
        elif name == "Pacific/Midway":
            return Self.PACIFIC_MIDWAY
        elif name == "Asia/Istanbul":
            return Self.ASIA_ISTANBUL
        elif name == "America/Argentina/ComodRivadavia":
            return Self.AMERICA_ARGENTINA_COMODRIVADAVIA
        elif name == "Asia/Baku":
            return Self.ASIA_BAKU
        elif name == "Australia/NSW":
            return Self.AUSTRALIA_NSW
        elif name == "Europe/Busingen":
            return Self.EUROPE_BUSINGEN
        elif name == "America/Regina":
            return Self.AMERICA_REGINA
        elif name == "Africa/Bangui":
            return Self.AFRICA_BANGUI
        elif name == "Poland":
            return Self.POLAND
        elif name == "Indian/Christmas":
            return Self.INDIAN_CHRISTMAS
        elif name == "Australia/Queensland":
            return Self.AUSTRALIA_QUEENSLAND
        elif name == "Asia/Bishkek":
            return Self.ASIA_BISHKEK
        elif name == "Asia/Dubai":
            return Self.ASIA_DUBAI
        elif name == "Africa/Mbabane":
            return Self.AFRICA_MBABANE
        elif name == "America/Grand_Turk":
            return Self.AMERICA_GRAND_TURK
        elif name == "America/Glace_Bay":
            return Self.AMERICA_GLACE_BAY
        elif name == "Pacific/Enderbury":
            return Self.PACIFIC_ENDERBURY
        elif name == "Africa/Dakar":
            return Self.AFRICA_DAKAR
        elif name == "Africa/Algiers":
            return Self.AFRICA_ALGIERS
        elif name == "Asia/Damascus":
            return Self.ASIA_DAMASCUS
        elif name == "America/Rankin_Inlet":
            return Self.AMERICA_RANKIN_INLET
        elif name == "Europe/Brussels":
            return Self.EUROPE_BRUSSELS
        elif name == "Asia/Hovd":
            return Self.ASIA_HOVD
        elif name == "Australia/Hobart":
            return Self.AUSTRALIA_HOBART
        elif name == "Europe/Bucharest":
            return Self.EUROPE_BUCHAREST
        elif name == "Asia/Gaza":
            return Self.ASIA_GAZA
        elif name == "Iran":
            return Self.IRAN
        elif name == "Africa/Djibouti":
            return Self.AFRICA_DJIBOUTI
        elif name == "America/Rosario":
            return Self.AMERICA_ROSARIO
        elif name == "Europe/Belgrade":
            return Self.EUROPE_BELGRADE
        elif name == "Antarctica/Rothera":
            return Self.ANTARCTICA_ROTHERA
        elif name == "Africa/Addis_Ababa":
            return Self.AFRICA_ADDIS_ABABA
        elif name == "Asia/Dacca":
            return Self.ASIA_DACCA
        elif name == "Asia/Krasnoyarsk":
            return Self.ASIA_KRASNOYARSK
        elif name == "Europe/Chisinau":
            return Self.EUROPE_CHISINAU
        elif name == "Indian/Cocos":
            return Self.INDIAN_COCOS
        elif name == "America/Indiana/Vincennes":
            return Self.AMERICA_INDiana_VINCENNES
        elif name == "America/Cambridge_Bay":
            return Self.AMERICA_CAMBRIDGE_BAY
        elif name == "Asia/Thimphu":
            return Self.ASIA_THIMPHU
        elif name == "Europe/Riga":
            return Self.EUROPE_RIGA
        elif name == "US/Mountain":
            return Self.US_MOUNTAIN
        elif name == "Egypt":
            return Self.EGYPT
        elif name == "America/Argentina/Tucuman":
            return Self.AMERICA_ARGENTINA_TUCUMAN
        elif name == "Atlantic/St_Helena":
            return Self.ATLANTIC_ST_HELENA
        elif name == "Greenwich":
            return Self.GREENWICH
        elif name == "Asia/Ashkhabad":
            return Self.ASIA_ASHKHABAD
        elif name == "Europe/Nicosia":
            return Self.EUROPE_NICOSIA
        elif name == "Asia/Aqtau":
            return Self.ASIA_AQTAU
        elif name == "Antarctica/Mawson":
            return Self.ANTARCTICA_MAWSON
        elif name == "America/North_Dakota/Center":
            return Self.AMERICA_NORTH_DAKOTA_CENTER
        elif name == "EET":
            return Self.EET
        elif name == "ROC":
            return Self.ROC
        elif name == "America/Mendoza":
            return Self.AMERICA_MENDOZA
        elif name == "America/St_Vincent":
            return Self.AMERICA_ST_VINCENT
        elif name == "CST6CDT":
            return Self.CST6CDT
        elif name == "Asia/Bahrain":
            return Self.ASIA_BAHRAIN
        elif name == "Asia/Riyadh":
            return Self.ASIA_RIYADH
        elif name == "Pacific/Efate":
            return Self.PACIFIC_EFATE
        elif name == "Indian/Mauritius":
            return Self.INDIAN_MAURITIUS
        elif name == "Indian/Kerguelen":
            return Self.INDIAN_KERGULEN
        elif name == "Asia/Colombo":
            return Self.ASIA_COLOMBO
        elif name == "Africa/Maseru":
            return Self.AFRICA_MASERU
        elif name == "America/Asuncion":
            return Self.AMERICA_ASUNCION
        elif name == "Europe/Copenhagen":
            return Self.EUROPE_COPENHAGEN
        elif name == "America/Argentina/Salta":
            return Self.AMERICA_ARGENTINA_SALTA
        elif name == "Africa/Malabo":
            return Self.AFRICA_MALABO
        elif name == "America/Matamoros":
            return Self.AMERICA_MATAMOROS
        elif name == "America/Argentina/La_Rioja":
            return Self.AMERICA_ARGENTINA_LA_RIOJA
        elif name == "Africa/Accra":
            return Self.AFRICA_ACCRA
        elif name == "Eire":
            return Self.EIRE
        elif name == "America/Kentucky/Louisville":
            return Self.AMERICA_KENTUCKY_LOUISVILLE
        elif name == "Africa/Bamako":
            return Self.AFRICA_BAMAKO
        elif name == "Etc/GMT-5":
            return Self.ETC_GMT_5
        elif name == "Pacific/Chatham":
            return Self.PACIFIC_CHATHAM
        elif name == "WET":
            return Self.WET
        elif name == "Etc/GMT+5":
            return Self.ETC_GMT_PLUS_5
        elif name == "Africa/Mogadishu":
            return Self.AFRICA_MOGADISHU
        elif name == "America/Thule":
            return Self.AMERICA_THULE
        elif name == "America/Phoenix":
            return Self.AMERICA_PHOENIX
        elif name == "Australia/Lord_Howe":
            return Self.AUSTRALIA_LORD_HOWE
        elif name == "Pacific/Chuuk":
            return Self.PACIFIC_CHUUK
        elif name == "Pacific/Marquesas":
            return Self.PACIFIC_MARQUESAS
        elif name == "Pacific/Wake":
            return Self.PACIFIC_WAKE
        elif name == "Africa/Brazzaville":
            return Self.AFRICA_BRAZZAVILLE
        elif name == "Australia/Broken_Hill":
            return Self.AUSTRALIA_BROKEN_HILL
        elif name == "Australia/South":
            return Self.AUSTRALIA_SOUTH
        elif name == "America/Kentucky/Monticello":
            return Self.AMERICA_KENTUCKY_MONTICELLO
        elif name == "Europe/Kiev":
            return Self.EUROPE_KIEV
        elif name == "Etc/GMT-9":
            return Self.ETC_GMT_9
        elif name == "Australia/Lindeman":
            return Self.AUSTRALIA_LINDEMAN
        elif name == "America/Metlakatla":
            return Self.AMERICA_METLAKATLA
        elif name == "America/Goose_Bay":
            return Self.AMERICA_GOOSE_BAY
        elif name == "America/St_Lucia":
            return Self.AMERICA_ST_LUCIA
        elif name == "Europe/Ljubljana":
            return Self.EUROPE_LJUBLJANA
        elif name == "Europe/Tirane":
            return Self.EUROPE_TIRANE
        elif name == "America/Santarem":
            return Self.AMERICA_SANTAREM
        elif name == "Atlantic/Canary":
            return Self.ATLANTIC_CANARY
        elif name == "America/Grenada":
            return Self.AMERICA_GRENADA
        elif name == "America/Shiprock":
            return Self.AMERICA_SHIPROCK
        elif name == "Europe/Skopje":
            return Self.EUROPE_SKOPJE
        elif name == "Etc/GMT+8":
            return Self.ETC_GMT_PLUS_8
        elif name == "Asia/Baghdad":
            return Self.ASIA_BAGHDAD
        elif name == "Australia/Sydney":
            return Self.AUSTRALIA_SYDNEY
        elif name == "Europe/Istanbul":
            return Self.EUROPE_ISTANBUL
        elif name == "America/Dominica":
            return Self.AMERICA_DOMINICA
        elif name == "America/Nipigon":
            return Self.AMERICA_NIPIGON
        elif name == "Asia/Calcutta":
            return Self.ASIA_CALCUTTA
        elif name == "Etc/GMT-0":
            return Self.ETC_GMT_0
        elif name == "Antarctica/Casey":
            return Self.ANTARCTICA_CASEY
        elif name == "Asia/Vladivostok":
            return Self.ASIA_VLADIVOSTOK
        elif name == "America/Godthab":
            return Self.AMERICA_GODTHAB
        elif name == "Asia/Aqtube":
            return Self.ASIA_AQTUBE
        elif name == "Europe/Kirov":
            return Self.EUROPE_KIROV
        elif name == "Asia/Aden":
            return Self.ASIA_ADEN
        elif name == "Europe/Isle_of_Man":
            return Self.EUROPE_ISLE_OF_MAN

        # If no match is found, raise an error.
        raise Error("Unknown time zone: ", name)