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

    fn __init__(out self, name: StringLiteral, offset: Int):
        """Initializes a new timezone.

        Args:
            name: Time zone name.
            offset: UTC offset in seconds.
        """
        self.name = String(name)
        self.offset = offset
    
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


alias TIMEZONE_MAP: Dict[String, TimeZone] = {
    "Asia/Jakarta": TimeZone.ASIA_JAKARTA,
    "Libya": TimeZone.LIBYA,
    "America/Iqaluit": TimeZone.AMERICA_IQALUIT,
    "America/Indiana/Vevay": TimeZone.AMERICA_INDIANA_VEVAY,
    "Atlantic/South_Georgia": TimeZone.ATLANTIC_SOUTH_GEORGIA,
    "America/Cuiaba": TimeZone.AMERICA_CUIABA,
    "Europe/Tallinn": TimeZone.EUROPE_TALLINN,
    "America/Ensenada": TimeZone.AMERICA_ENSENADA,
    "Africa/Abidjan": TimeZone.AFRICA_ABIDJAN,
    "Pacific/Saipan": TimeZone.PACIFIC_SAIPAN,
    "Mexico/General": TimeZone.MEXICO_GENERAL,
    "Europe/Rome": TimeZone.EUROPE_ROME,
    "Asia/Seoul": TimeZone.ASIA_SEOUL,
    "US/Michigan": TimeZone.US_MICHIGAN,
    "America/New_York": TimeZone.AMERICA_NEW_YORK,
    "Europe/Athens": TimeZone.EUROPE_ATHENS,
    "Europe/Lisbon": TimeZone.EUROPE_LISBON,
    "America/St_Thomas": TimeZone.AMERICA_ST_THOMAS,
    "Europe/Moscow": TimeZone.EUROPE_MOSCOW,
    "Pacific/Easter": TimeZone.PACIFIC_EASTER,
    "America/Porto_Acre": TimeZone.AMERICA_PORTO_ACRE,
    "America/Creston": TimeZone.AMERICA_CRESTON,
    "Pacific/Norfolk": TimeZone.PACIFIC_NORFOLK,
    "America/Argentina/Cordoba": TimeZone.AMERICA_ARGENTINA_CORDOBA,
    "America/Atka": TimeZone.AMERICA_ATKA,
    "Pacific/Niue": TimeZone.PACIFIC_NIUE,
    "Asia/Ulan_Bator": TimeZone.ASIA_ULAN_BATOR,
    "Europe/Simferopol": TimeZone.EUROPE_SIMFEROPOL,
    "Asia/Dili": TimeZone.ASIA_DILI,
    "Europe/Zagreb": TimeZone.EUROPE_ZAGREB,
    "Antarctica/Palmer": TimeZone.ANTARCTICA_PALMER,
    "America/Cayenne": TimeZone.AMERICA_CAYENNE,
    "Asia/Tel_Aviv": TimeZone.ASIA_TEL_AVIV,
    "Asia/Urumqi": TimeZone.ASIA_URUMQI,
    "Asia/Beirut": TimeZone.ASIA_BEIRUT,
    "Asia/Kuala_Lumpur": TimeZone.ASIA_KUALA_LUMPUR,
    "America/Belem": TimeZone.AMERICA_BELEM,
    "Pacific/Honolulu": TimeZone.PACIFIC_HONOLULU,
    "America/Santa_Isabel": TimeZone.AMERICA_SANTA_ISABEL,
    "Pacific/Kwajalein": TimeZone.PACIFIC_KWAJALEIN,
    "Africa/Luanda": TimeZone.AFRICA_LUANDA,
    "America/Chicago": TimeZone.AMERICA_CHICAGO,
    "Asia/Harbin": TimeZone.ASIA_HARBIN,
    "Europe/Paris": TimeZone.EUROPE_PARIS,
    "Pacific/Wallis": TimeZone.PACIFIC_WALLIS,
    "America/Argentina/Ushuaia": TimeZone.AMERICA_ARGENTINA_USHUAIA,
    "Australia/Adelaide": TimeZone.AUSTRALIA_ADelaide,
    "Asia/Singapore": TimeZone.ASIA_SINGAPORE,
    "America/Kralendijk": TimeZone.AMERICA_KRALENDIJK,
    "America/Moncton": TimeZone.AMERICA_MONCTON,
    "America/Aruba": TimeZone.AMERICA_ARUBA,
    "America/Noronha": TimeZone.AMERICA_NORONHA,
    "Etc/UTC": TimeZone.ETC_UTC,
    "Africa/Lusaka": TimeZone.AFRICA_LUSAKA,
    "Asia/Tomsk": TimeZone.ASIA_TOMSK,
    "Asia/Phnom_Penh": TimeZone.ASIA_PHNOM_PENH,
    "Asia/Samarkand": TimeZone.ASIA_SAMARKAND,
    "Europe/Luxembourg": TimeZone.EUROPE_LUXEMBOURG,
    "Indian/Antananarivo": TimeZone.INDIAN_ANTANANARIVO,
    "Etc/GMT+1": TimeZone.ETC_GMT_PLUS_1,
    "America/Porto_Velho": TimeZone.AMERICA_PORTO_VELHO,
    "GB": TimeZone.GB,
    "America/Barbados": TimeZone.AMERICA_BARbADOS,
    "Asia/Chungking": TimeZone.ASIA_CHUNGKING,
    "Asia/Shanghai": TimeZone.ASIA_SHANGHAI,
    "Etc/GMT-13": TimeZone.ETC_GMT_13,
    "America/Indiana/Indianapolis": TimeZone.AMERICA_INDIANA_INDIANAPOLIS,
    "America/Argentina/Mendoza": TimeZone.AMERICA_ARGENTINA_MENDOZA,
    "America/Jamaica": TimeZone.AMERICA_JAMAICA,
    "Canada/Newfoundland": TimeZone.CANADA_NEWFOUNDLAND,
    "America/Cordoba": TimeZone.AMERICA_CORDOBA,
    "Africa/Niamey": TimeZone.AFRICA_NIAMEY,
    "America/Halifax": TimeZone.AMERICA_HALIFAX,
    "Antarctica/South_Pole": TimeZone.ANTARCTICA_SOUTH_POLE,
    "Africa/Ouagadougou": TimeZone.AFRICA_OUAGADOUGOU,
    "CET": TimeZone.CET,
    "America/Argentina/San_Juan": TimeZone.AMERICA_ARGENTINA_SAN_JUAN,
    "Asia/Almaty": TimeZone.ASIA_ALMATY,
    "Antarctica/Vostok": TimeZone.ANTARCTICA_VOSTOK,
    "Canada/Atlantic": TimeZone.CANADA_ATLANTIC,
    "Europe/Amsterdam": TimeZone.EUROPE_AMSTERDAM,
    "America/Costa_Rica": TimeZone.AMERICA_COSTA_RICA,
    "America/Knox_IN": TimeZone.AMERICA_KNOX_IN,
    "Asia/Pontianak": TimeZone.ASIA_PONTIANAK,
    "America/Punta_Arenas": TimeZone.AMERICA_PUNTA_ARENAS,
    "Indian/Mahe": TimeZone.INDIAN_MAHE,
    "Africa/Timbuktu": TimeZone.AFRICA_TIMBUKTU,
    "Atlantic/Madeira": TimeZone.ATLANTIC_MADEIRA,
    "Chile/EasterIsland": TimeZone.CHILE_EASTERISLAND,
    "Atlantic/Stanley": TimeZone.ATLANTIC_STANLEY,
    "America/Cancun": TimeZone.AMERICA_CANCUN,
    "Europe/Minsk": TimeZone.EUROPE_MINSK,
    "US/Eastern": TimeZone.US_EASTERN,
    "HST": TimeZone.HST,
    "America/Boise": TimeZone.AMERICA_BOISE,
    "Brazil/West": TimeZone.BRAZIL_WEST,
    "America/Catamarca": TimeZone.AMERICA_CATAMARCA,
    "America/Port_of_Spain": TimeZone.AMERICA_PORT_OF_SPAIN,
    "Asia/Katmandu": TimeZone.ASIA_KATMANDU,
    "Etc/GMT-14": TimeZone.ETC_GMT_MINUS_14,
    "America/Guayaquil": TimeZone.AMERICA_GUAYAQUIL,
    "Australia/Canberra": TimeZone.AUSTRALIA_CANBERRA,
    "America/Ojinaga": TimeZone.AMERICA_OJINAGA,
    "Europe/Kyiv": TimeZone.EUROPE_KYIV,
    "Africa/Kinshasa": TimeZone.AFRICA_KINSHASA,
    "Pacific/Pohnpei": TimeZone.PACIFIC_POHNPEI,
    "America/Indiana/Winamac": TimeZone.AMERICA_INDIANA_WINAMAC,
    "Etc/GMT-11": TimeZone.ETC_GMT_MINUS_11,
    "Asia/Dhaka": TimeZone.ASIA_DHAKA,
    "Australia/Perth": TimeZone.AUSTRALIA_PERTH,
    "America/Whitehorse": TimeZone.AMERICA_WHITEHORSE,
    "Indian/Reunion": TimeZone.INDIAN_REUNION,
    "Europe/London": TimeZone.EUROPE_LONDON,
    "Navajo": TimeZone.NAVAJO,
    "America/Manaus": TimeZone.AMERICA_MANAUS,
    "Asia/Chita": TimeZone.ASIA_CHITA,
    "Hongkong": TimeZone.HONGKONG,
    "Africa/Bissau": TimeZone.AFRICA_BISSAU,
    "America/Tortola": TimeZone.AMERICA_TORTOLA,
    "America/Juneau": TimeZone.AMERICA_JUNEAU,
    "Europe/Malta": TimeZone.EUROPE_MALTA,
    "Pacific/Ponape": TimeZone.PACIFIC_PONAPE,
    "Africa/Asmara": TimeZone.AFRICA_ASMARA,
    "Asia/Kamchatka": TimeZone.ASIA_KAMCHATKA,
    "Europe/Helsinki": TimeZone.EUROPE_HELSINKI,
    "America/Los_Angeles": TimeZone.AMERICA_LOS_ANGELES,
    "Etc/GMT-4": TimeZone.ETC_GMT_MINUS_4,
    "America/Bahia": TimeZone.AMERICA_BAHIA,
    "America/Port-au-Prince": TimeZone.AMERICA_PORT_AU_PRINCE,
    "Europe/Vilnius": TimeZone.EUROPE_VILNIUS,
    "Etc/GMT-1": TimeZone.ETC_GMT_MINUS_1,
    "Europe/Jersey": TimeZone.EUROPE_JERSEY,
    "Africa/Tunis": TimeZone.AFRICA_TUNIS,
    "Mexico/BajaSur": TimeZone.MEXICO_BAJASUR,
    "Pacific/Tarawa": TimeZone.PACIFIC_TARAWA,
    "Canada/Yukon": TimeZone.CANADA_YUKON,
    "America/Virgin": TimeZone.AMERICA_VIRGIN,
    "Europe/Budapest": TimeZone.EUROPE_BUDAPEST,
    "America/Jujuy": TimeZone.AMERICA_JUJUY,
    "Africa/Juba": TimeZone.AFRICA_JUBA,
    "America/Indiana/Tell_City": TimeZone.AMERICA_INDiana_TELL_CITY,
    "Pacific/Kanton": TimeZone.PACIFIC_KANTON,
    "America/Nassau": TimeZone.AMERICA_NASSAU,
    "America/Rio_Branco": TimeZone.AMERICA_RIO_BRANCO,
    "GMT-0": TimeZone.GMT_MINUS_0,
    "Australia/Tasmania": TimeZone.AUSTRALIA_TASMANIA,
    "Pacific/Kosrae": TimeZone.PACIFIC_KOSRAE,
    "US/Hawaii": TimeZone.US_HAWAII,
    "Asia/Tbilisi": TimeZone.ASIA_TBILISI,
    "Pacific/Bougainville": TimeZone.PACIFIC_BOUGAINVILLE,
    "Europe/Vaduz": TimeZone.EUROPE_VADUZ,
    "Etc/GMT+11": TimeZone.ETC_GMT_PLUS_11,
    "Africa/Windhoek": TimeZone.AFRICA_WINDHOEK,
    "Atlantic/Jan_Mayen": TimeZone.ATLANTIC_JAN_MAYEN,
    "Africa/Ndjamena": TimeZone.AFRICA_NDJAMENA,
    "America/Adak": TimeZone.AMERICA_ADAK,
    "Israel": TimeZone.ISRAEL,
    "US/Indiana-Starke": TimeZone.US_INDiana_STARKE,
    "America/North_Dakota/New_Salem": TimeZone.AMERICA_NORTH_DAKOTA_NEW_SALEM,
    "Pacific/Palau": TimeZone.PACIFIC_PALAU,
    "GMT+0": TimeZone.GMT_PLUS_0,
    "America/Rainy_River": TimeZone.AMERICA_RAINY_RIVER,
    "America/Winnipeg": TimeZone.AMERICA_WINNIPEG,
    "Etc/Greenwich": TimeZone.ETC_GREENWICH,
    "America/Pangnirtung": TimeZone.AMERICA_PANGNIRTUNG,
    "Africa/Tripoli": TimeZone.AFRICA_TRIPOLI,
    "America/Guatemala": TimeZone.AMERICA_GUATEMALA,
    "Asia/Nicosia": TimeZone.ASIA_NICOSIA,
    "America/Belize": TimeZone.AMERICA_BELIZE,
    "America/Resolute": TimeZone.AMERICA_RESOLUTE,
    "Asia/Hebron": TimeZone.ASIA_HEBRON,
    "America/Caracas": TimeZone.AMERICA_CARACAS,
    "Asia/Novosibirsk": TimeZone.ASIA_NOVOSIBIRSK,
    "Europe/Podgorica": TimeZone.EUROPE_PODGORICA,
    "PRC": TimeZone.PRC,
    "Europe/Kaliningrad": TimeZone.EUROPE_KALININGRAD,
    "Europe/Zurich": TimeZone.EUROPE_ZURICH,
    "America/St_Barthelemy": TimeZone.AMERICA_ST_BARTHELEMY,
    "America/Nuuk": TimeZone.AMERICA_NUUK,
    "Etc/GMT+12": TimeZone.ETC_GMT_PLUS_12,
    "Asia/Hong_Kong": TimeZone.ASIA_HONG_KONG,
    "Etc/GMT-3": TimeZone.ETC_GMT_MINUS_3,
    "America/Miquelon": TimeZone.AMERICA_MIQUELON,
    "Europe/Volgograd": TimeZone.EUROPE_VOLGOGRAD,
    "Europe/Madrid": TimeZone.EUROPE_MADRID,
    "America/Monterrey": TimeZone.AMERICA_MONTERREY,
    "America/Anchorage": TimeZone.AMERICA_ANCHORAGE,
    "America/Argentina/San_Luis": TimeZone.AMERICA_ARGENTINA_SAN_LUIS,
    "America/Eirunepe": TimeZone.AMERICA_EIRUNEPE,
    "America/St_Kitts": TimeZone.AMERICA_ST_KITTS,
    "America/Bahia_Banderas": TimeZone.AMERICA_BAHIA_BANDERAS,
    "Etc/GMT+2": TimeZone.ETC_GMT_PLUS_2,
    "Zulu": TimeZone.ZULU,
    "Africa/Gaborone": TimeZone.AFRICA_GABORONE,
    "Antarctica/McMurdo": TimeZone.ANTARCTICA_MCMURDO,
    "Europe/Guernsey": TimeZone.EUROPE_GUERNSEY,
    "Europe/Andorra": TimeZone.EUROPE_ANDORRA,
    "America/Paramaribo": TimeZone.AMERICA_PARAMARIBO,
    "America/Fort_Nelson": TimeZone.AMERICA_FORT_NELSON,
    "Antarctica/Troll": TimeZone.ANTARCTICA_TROLL,
    "Europe/Uzhgorod": TimeZone.EUROPE_UZHGOROD,
    "Atlantic/Cape_Verde": TimeZone.ATLANTIC_CAPE_VERDE,
    "UCT": TimeZone.UCT,
    "Etc/GMT-6": TimeZone.ETC_GMT_MINUS_6,
    "Asia/Srednekolymsk": TimeZone.ASIA_SREDNEKOLYMSK,
    "Asia/Ujung_Pandang": TimeZone.ASIA_UJUNG_PANDANG,
    "America/Thunder_Bay": TimeZone.AMERICA_THUNDER_BAY,
    "Africa/Khartoum": TimeZone.AFRICA_KHARTOUM,
    "Africa/Douala": TimeZone.AFRICA_DOUALA,
    "America/Cayman": TimeZone.AMERICA_CAYMAN,
    "Brazil/Acre": TimeZone.BRAZIL_ACRE,
    "America/Indiana/Knox": TimeZone.AMERICA_INDIANA_KNOX,
    "Australia/Yancowinna": TimeZone.AUSTRALIA_YANCOWINNA,
    "America/Chihuahua": TimeZone.AMERICA_CHIHUAHUA,
    "America/Recife": TimeZone.AMERICA_RECIFE,
    "America/Indiana/Marengo": TimeZone.AMERICA_INDIANA_MARENGO,
    "Asia/Yangon": TimeZone.ASIA_YANGON,
    "Europe/Astrakhan": TimeZone.EUROPE_ASTRAKHAN,
    "Asia/Rangoon": TimeZone.ASIA_RANGOON,
    "America/Vancouver": TimeZone.AMERICA_VANCOUVER,
    "NZ-CHAT": TimeZone.NZ_CHAT,
    "America/Montserrat": TimeZone.AMERICA_MONTERRAT,
    "America/Merida": TimeZone.AMERICA_MERIDA,
    "America/Puerto_Rico": TimeZone.AMERICA_PUERTO_RICO,
    "America/Maceio": TimeZone.AMERICA_MACEIO,
    "America/Panama": TimeZone.AMERICA_PANAMA,
    "Brazil/East": TimeZone.BRAZIL_EAST,
    "Japan": TimeZone.JAPAN,
    "Australia/Victoria": TimeZone.AUSTRALIA_VICTORIA,
    "America/Indiana/Petersburg": TimeZone.AMERICA_INDIANA_PETERSBURG,
    "Asia/Dushanbe": TimeZone.ASIA_DUSHANBE,
    "Africa/Asmera": TimeZone.AFRICA_ASMERA,
    "Etc/Zulu": TimeZone.ETC_ZULU,
    "Europe/Monaco": TimeZone.EUROPE_MONACO,
    "Asia/Amman": TimeZone.ASIA_AMMAN,
    "Asia/Kuwait": TimeZone.ASIA_KUWAIT,
    "Asia/Sakhalin": TimeZone.ASIA_SAKHALIN,
    "Europe/Gibraltar": TimeZone.EUROPE_GIBRALTAR,
    "America/Havana": TimeZone.AMERICA_HAVANA,
    "Etc/GMT+0": TimeZone.ETC_GMT_PLUS_0,
    "Asia/Choibalsan": TimeZone.ASIA_CHOIBALSAN,
    "Asia/Vientiane": TimeZone.ASIA_VIENTIANE,
    "Africa/Monrovia": TimeZone.AFRICA_MONROVIA,
    "Africa/Lagos": TimeZone.AFRICA_LAGOS,
    "America/Argentina/Buenos_Aires": TimeZone.AMERICA_ARGENTINA_BUENOS_AIRES,
    "Australia/Melbourne": TimeZone.AUSTRALIA_MELBOURNE,
    "Etc/GMT+6": TimeZone.ETC_GMT_PLUS_6,
    "PST8PDT": TimeZone.PST8PDT,
    "America/Scoresbysund": TimeZone.AMERICA_SCORESBYSUND,
    "Australia/ACT": TimeZone.AUSTRALIA_ACT,
    "Africa/Blantyre": TimeZone.AFRICA_BLANTYRE,
    "Asia/Saigon": TimeZone.ASIA_SAIGON,
    "Asia/Chongqing": TimeZone.ASIA_CHONGQING,
    "GB-Eire": TimeZone.GB_EIRE,
    "US/Samoa": TimeZone.US_SAMOA,
    "Arctic/Longyearbyen": TimeZone.ARCTIC_LONGYEARBYEN,
    "America/Curacao": TimeZone.AMERICA_CURACAO,
    "America/Mexico_City": TimeZone.AMERICA_MEXICO_CITY,
    "Asia/Kabul": TimeZone.ASIA_KABUL,
    "America/Indianapolis": TimeZone.AMERICA_INDIANAPOLIS,
    "Asia/Macao": TimeZone.ASIA_MACAO,
    "Canada/Central": TimeZone.CANADA_CENTRAL,
    "Asia/Famagusta": TimeZone.ASIA_FAMAGUSTA,
    "America/Atikokan": TimeZone.AMERICA_ATIKOKAN,
    "Asia/Brunei": TimeZone.ASIA_BRUNEI,
    "Asia/Ust-Nera": TimeZone.ASIA_UST_NERA,
    "Brazil/DeNoronha": TimeZone.BRAZIL_DE_NORONHA,
    "Indian/Chagos": TimeZone.INDIAN_CHAGOS,
    "Asia/Kathmandu": TimeZone.ASIA_KATHMANDU,
    "Asia/Tehran": TimeZone.ASIA_TEHRAN,
    "Africa/Dar_es_Salaam": TimeZone.AFRICA_DAR_ES_SALAAM,
    "America/Managua": TimeZone.AMERICA_MANAGUA,
    "Africa/Cairo": TimeZone.AFRICA_CAIRO,
    "Pacific/Nauru": TimeZone.PACIFIC_NAURU,
    "Europe/Saratov": TimeZone.EUROPE_SARATOV,
    "Indian/Maldives": TimeZone.INDIAN_MALDIVES,
    "Asia/Makassar": TimeZone.ASIA_MAKASSAR,
    "America/Sao_Paulo": TimeZone.AMERICA_SAO_PAULO,
    "America/St_Johns": TimeZone.AMERICA_ST_JOHNS,
    "Etc/GMT+9": TimeZone.ETC_GMT_PLUS_9,
    "Asia/Qyzylorda": TimeZone.ASIA_QYZYLORDA,
    "Australia/North": TimeZone.AUSTRALIA_NORTH,
    "America/Montevideo": TimeZone.AMERICA_MONTEVIDEO,
    "Australia/West": TimeZone.AUSTRALIA_WEST,
    "Europe/Oslo": TimeZone.EUROPE_OSLO,
    "Turkey": TimeZone.TURKEY,
    "US/Central": TimeZone.US_CENTRAL,
    "Europe/Berlin": TimeZone.EUROPE_BERLIN,
    "Europe/Bratislava": TimeZone.EUROPE_BRATISLAVA,
    "America/El_Salvador": TimeZone.AMERICA_EL_SALVADOR,
    "Africa/Kampala": TimeZone.AFRICA_KAMPALA,
    "America/Dawson": TimeZone.AMERICA_DAWSON,
    "America/La_Paz": TimeZone.AMERICA_LA_PAZ,
    "US/Aleutian": TimeZone.US_ALEUTIAN,
    "Asia/Kolkata": TimeZone.ASIA_KOLKATA,
    "Asia/Oral": TimeZone.ASIA_ORAL,
    "Asia/Omsk": TimeZone.ASIA_OMSK,
    "America/Santiago": TimeZone.AMERICA_SANTIAGO,
    "America/Detroit": TimeZone.AMERICA_DETROIT,
    "America/Anguilla": TimeZone.AMERICA_ANGUILLA,
    "America/Nome": TimeZone.AMERICA_NOME,
    "Singapore": TimeZone.SINGAPORE,
    "Africa/Conakry": TimeZone.AFRICA_CONAKRY,
    "Africa/Maputo": TimeZone.AFRICA_MAPUTO,
    "Antarctica/Davis": TimeZone.ANTARCTICA_DAVIS,
    "Asia/Manila": TimeZone.ASIA_MANILA,
    "Pacific/Majuro": TimeZone.PACIFIC_MAJURO,
    "Africa/Lubumbashi": TimeZone.AFRICA_LUBUMBASHI,
    "Portugal": TimeZone.PORTUGAL,
    "Pacific/Port_Moresby": TimeZone.PACIFIC_PORT_MORESBY,
    "Etc/GMT+3": TimeZone.ETC_GMT_PLUS_3,
    "Chile/Continental": TimeZone.CHILE_CONTINENTAL,
    "GMT": TimeZone.GMT,
    "America/Martinique": TimeZone.AMERICA_MARTINIQUE,
    "Africa/Sao_Tome": TimeZone.AFRICA_SAO_TOME,
    "America/Sitka": TimeZone.AMERICA_SITKA,
    "Asia/Taipei": TimeZone.ASIA_TAIPEI,
    "Indian/Mayotte": TimeZone.INDIAN_MAYOTTE,
    "America/Argentina/Rio_Gallegos": TimeZone.AMERICA_ARGENTINA_RIO_GALLEGOS,
    "America/Menominee": TimeZone.AMERICA_MENOMINEE,
    "Canada/Pacific": TimeZone.CANADA_PACIFIC,
    "MET": TimeZone.MET,
    "Asia/Thimbu": TimeZone.ASIA_THIMBU,
    "America/Campo_Grande": TimeZone.AMERICA_CAMPO_GRANDE,
    "Asia/Magadan": TimeZone.ASIA_MAGADAN,
    "Africa/Casablanca": TimeZone.AFRICA_CASABLANCA,
    "America/Guadeloupe": TimeZone.AMERICA_GUADELOUPE,
    "Atlantic/Faroe": TimeZone.ATLANTIC_FAROE,
    "Asia/Anadyr": TimeZone.ASIA_ANADYR,
    "Africa/Porto-Novo": TimeZone.AFRICA_PORTO_NOVO,
    "Africa/Banjul": TimeZone.AFRICA_BANJUL,
    "Indian/Comoro": TimeZone.INDIAN_COMORO,
    "America/Yakutat": TimeZone.AMERICA_YAKUTAT,
    "Pacific/Gambier": TimeZone.PACIFIC_GAMBIER,
    "Asia/Ashgabat": TimeZone.ASIA_ASHGABAT,
    "Antarctica/DumontDUrville": TimeZone.ANTARCTICA_DUMONT_DURVILLE,
    "US/East-Indiana": TimeZone.US_EAST_IND,
    "Asia/Irkutsk": TimeZone.ASIA_IRKUTSK,
    "America/Mazatlan": TimeZone.AMERICA_MAZATLAN,
    "Pacific/Apia": TimeZone.PACIFIC_APIA,
    "America/Boa_Vista": TimeZone.AMERICA_BOA_VISTA,
    "Etc/GMT": TimeZone.ETC_GMT,
    "America/Guyana": TimeZone.AMERICA_GUYANA,
    "Australia/Currie": TimeZone.AUSTRALIA_CURRIE,
    "Europe/Ulyanovsk": TimeZone.EUROPE_ULYANOVSK,
    "Pacific/Fakaofo": TimeZone.PACIFIC_FAKAOFO,
    "America/North_Dakota/Beulah": TimeZone.AMERICA_NORTH_DAKOTA_BEULAH,
    "Europe/Prague": TimeZone.EUROPE_PRAGUE,
    "Asia/Qatar": TimeZone.ASIA_QATAR,
    "Pacific/Funafuti": TimeZone.PACIFIC_FUNAFUTI,
    "Jamaica": TimeZone.JAMAICA,
    "Canada/Eastern": TimeZone.CANADA_EASTERN,
    "Pacific/Guam": TimeZone.PACIFIC_GUAM,
    "Pacific/Fiji": TimeZone.PACIFIC_FIJI,
    "Africa/Kigali": TimeZone.AFRICA_KIGALI,
    "Pacific/Tongatapu": TimeZone.PACIFIC_TONGATAPU,
    "America/Lima": TimeZone.AMERICA_LIMA,
    "Asia/Muscat": TimeZone.ASIA_MUSCAT,
    "Antarctica/Macquarie": TimeZone.ANTARCTICA_MACQUARIE,
    "Etc/GMT-2": TimeZone.ETC_GMT_MINUS_2,
    "Pacific/Pitcairn": TimeZone.PACIFIC_PITCAIRN,
    "Canada/Mountain": TimeZone.CANADA_MOUNTAIN,
    "Asia/Yekaterinburg": TimeZone.ASIA_YEKATERINBURG,
    "Pacific/Johnston": TimeZone.PACIFIC_JOHNSTON,
    "Europe/Vatican": TimeZone.EUROPE_VATICAN,
    "Atlantic/Bermuda": TimeZone.ATLANTIC_BERMUDA,
    "Asia/Jerusalem": TimeZone.ASIA_JERUSALEM,
    "America/Ciudad_Juarez": TimeZone.AMERICA_CIUDAD_JUAREZ,
    "Pacific/Galapagos": TimeZone.PACIFIC_GALAPAGOS,
    "America/Montreal": TimeZone.AMERICA_MONTREAL,
    "Africa/Nouakchott": TimeZone.AFRICA_NOUAKCHOTT,
    "US/Arizona": TimeZone.US_ARIZONA,
    "Asia/Kuching": TimeZone.ASIA_KUCHING,
    "Etc/GMT+4": TimeZone.ETC_GMT_PLUS_4,
    "Australia/Brisbane": TimeZone.AUSTRALIA_BRISBANE,
    "Canada/Saskatchewan": TimeZone.CANADA_SASKATCHEWAN,
    "Europe/Dublin": TimeZone.EUROPE_DUBLIN,
    "Asia/Qostanay": TimeZone.ASIA_QOSTANAY,
    "America/Edmonton": TimeZone.AMERICA_EDMONTON,
    "Atlantic/Reykjavik": TimeZone.ATLANTIC_REYKJAVIK,
    "America/Fortaleza": TimeZone.AMERICA_FORTALEZA,
    "Pacific/Kiritimati": TimeZone.PACIFIC_KIRITIMATI,
    "Etc/Universal": TimeZone.ETC_UNIVERSAL,
    "GMT0": TimeZone.GMT0,
    "Europe/Belfast": TimeZone.EUROPE_BELFAST,
    "Pacific/Yap": TimeZone.PACIFIC_YAP,
    "America/Santo_Domingo": TimeZone.AMERICA_SANTO_DOMINGO,
    "Iceland": TimeZone.ICELAND,
    "America/Araguaina": TimeZone.AMERICA_ARAGUAINA,
    "Asia/Karachi": TimeZone.ASIA_KARACHI,
    "Etc/GMT+7": TimeZone.ETC_GMT_PLUS_7,
    "Africa/Bujumbura": TimeZone.AFRICA_BUJUMBURA,
    "America/Dawson_Creek": TimeZone.AMERICA_DAWSON_CREEK,
    "Europe/Zaporozhye": TimeZone.EUROPE_ZAPOROZHYE,
    "Asia/Ulaanbaatar": TimeZone.ASIA_ULAANBAATAR,
    "Pacific/Samoa": TimeZone.PACIFIC_SAMOA,
    "Australia/Darwin": TimeZone.AUSTRALIA_DARWIN,
    "Etc/GMT0": TimeZone.ETC_GMT0,
    "Pacific/Tahiti": TimeZone.PACIFIC_TAHITI,
    "Etc/GMT-8": TimeZone.ETC_GMT_MINUS_8,
    "Atlantic/Faeroe": TimeZone.ATLANTIC_FAEROE,
    "Africa/Libreville": TimeZone.AFRICA_LIBREVILLE,
    "Asia/Barnaul": TimeZone.ASIA_BARNAUL,
    "America/Coral_Harbour": TimeZone.AMERICA_CORAL_HARBOUR,
    "Antarctica/Syowa": TimeZone.ANTARCTICA_SYOWA,
    "America/Buenos_Aires": TimeZone.AMERICA_BUENOS_AIRES,
    "Europe/Vienna": TimeZone.EUROPE_VIENNA,
    "America/Fort_Wayne": TimeZone.AMERICA_FORT_WAYNE,
    "NZ": TimeZone.NZ,
    "Atlantic/Azores": TimeZone.ATLANTIC_AZORES,
    "America/Coyhaique": TimeZone.AMERICA_COYHAIQUE,
    "Asia/Pyongyang": TimeZone.ASIA_PYONGYANG,
    "Etc/GMT-10": TimeZone.ETC_GMT_MINUS_10,
    "MST": TimeZone.MST,
    "America/Argentina/Jujuy": TimeZone.AMERICA_ARGENTINA_JUJUY,
    "America/Tijuana": TimeZone.AMERICA_TIJUANA,
    "Pacific/Guadalcanal": TimeZone.PACIFIC_GUADALCANAL,
    "Europe/Stockholm": TimeZone.EUROPE_STOCKHOLM,
    "US/Alaska": TimeZone.US_ALASKA,
    "Europe/Tiraspol": TimeZone.EUROPE_TIRASPOL,
    "Europe/Samara": TimeZone.EUROPE_SAMARA,
    "Etc/GMT-12": TimeZone.ETC_GMT_MINUS_12,
    "Kwajalein": TimeZone.KWAJALEIN,
    "Asia/Macau": TimeZone.ASIA_MACAU,
    "Pacific/Truk": TimeZone.PACIFIC_TRUK,
    "Asia/Bangkok": TimeZone.ASIA_BANGKOK,
    "America/Antigua": TimeZone.AMERICA_ANTIGUA,
    "Africa/El_Aaiun": TimeZone.AFRICA_EL_AAIUN,
    "Europe/Mariehamn": TimeZone.EUROPE_MARIEHAMN,
    "Asia/Jayapura": TimeZone.ASIA_JAYAPURA,
    "Europe/San_Marino": TimeZone.EUROPE_SAN_MARINO,
    "US/Pacific": TimeZone.US_PACIFIC,
    "Africa/Johannesburg": TimeZone.AFRICA_JOHANNESBURG,
    "Australia/Eucla": TimeZone.AUSTRALIA_EUCLA,
    "Africa/Nairobi": TimeZone.AFRICA_NAIROBI,
    "Etc/GMT-7": TimeZone.ETC_GMT_MINUS_7,
    "America/Inuvik": TimeZone.AMERICA_INUVIK,
    "Asia/Tokyo": TimeZone.ASIA_TOKYO,
    "Asia/Atyrau": TimeZone.ASIA_ATYRAU,
    "Asia/Kashgar": TimeZone.ASIA_KASHGAR,
    "W-SU": TimeZone.W_SU,
    "Asia/Tashkent": TimeZone.ASIA_TASHKENT,
    "Africa/Freetown": TimeZone.AFRICA_FREETOWN,
    "Pacific/Pago_Pago": TimeZone.PACIFIC_PAGO_PAGO,
    "America/Denver": TimeZone.AMERICA_DENVER,
    "Australia/LHI": TimeZone.AUSTRALIA_LHI,
    "Pacific/Rarotonga": TimeZone.PACIFIC_RAROTONGA,
    "MST7MDT": TimeZone.MST7MDT,
    "Pacific/Noumea": TimeZone.PACIFIC_NOUMEA,
    "Etc/UCT": TimeZone.ETC_UCT,
    "Etc/GMT+10": TimeZone.ETC_GMT_PLUS_10,
    "ROK": TimeZone.ROK,
    "Pacific/Auckland": TimeZone.PACIFIC_AUCKLAND,
    "Asia/Novokuznetsk": TimeZone.ASIA_NOVOKUZNETSK,
    "America/Hermosillo": TimeZone.AMERICA_HERMOSILLO,
    "America/Louisville": TimeZone.AMERICA_LOUISVILLE,
    "Asia/Ho_Chi_Minh": TimeZone.ASIA_HO_CHI_MINH,
    "Asia/Yerevan": TimeZone.ASIA_YEREVAN,
    "Asia/Yakutsk": TimeZone.ASIA_YAKUTSK,
    "Universal": TimeZone.UNIVERSAL,
    "America/Tegucigalpa": TimeZone.AMERICA_TEGUCIGALPA,
    "Mexico/BajaNorte": TimeZone.MEXICO_BAJANORTE,
    "Europe/Sarajevo": TimeZone.EUROPE_SARAJEVO,
    "America/Argentina/Catamarca": TimeZone.AMERICA_ARGENTINA_CATAMARCA,
    "Cuba": TimeZone.CUBA,
    "Asia/Khandyga": TimeZone.ASIA_KHANDYGA,
    "America/Lower_Princes": TimeZone.AMERICA_LOWER_PRINCES,
    "America/Blanc-Sablon": TimeZone.AMERICA_BLANC_SABLON,
    "America/Bogota": TimeZone.AMERICA_BOGOTA,
    "Africa/Lome": TimeZone.AFRICA_LOME,
    "America/Toronto": TimeZone.AMERICA_TORONTO,
    "Europe/Warsaw": TimeZone.EUROPE_WARSAW,
    "America/Yellowknife": TimeZone.AMERICA_YELLOWKNIFE,
    "America/Swift_Current": TimeZone.AMERICA_SWIFT_CURRENT,
    "EST": TimeZone.EST,
    "Europe/Sofia": TimeZone.EUROPE_SOFIA,
    "Africa/Ceuta": TimeZone.AFRICA_CEUTA,
    "America/Marigot": TimeZone.AMERICA_MARIGOT,
    "America/Danmarkshavn": TimeZone.AMERICA_DANMARKSHAVN,
    "Africa/Harare": TimeZone.AFRICA_HARARE,
    "UTC": TimeZone.UTC,
    "UTC+1": TimeZone.UTC_PLUS_1,
    "UTC+2": TimeZone.UTC_PLUS_2,
    "UTC+3": TimeZone.UTC_PLUS_3,
    "UTC+4": TimeZone.UTC_PLUS_4,
    "UTC+5": TimeZone.UTC_PLUS_5,
    "UTC+6": TimeZone.UTC_PLUS_6,
    "UTC+7": TimeZone.UTC_PLUS_7,
    "UTC+8": TimeZone.UTC_PLUS_8,
    "UTC+9": TimeZone.UTC_PLUS_9,
    "UTC+10": TimeZone.UTC_PLUS_10,
    "UTC+11": TimeZone.UTC_PLUS_11,
    "UTC+12": TimeZone.UTC_PLUS_12,
    "UTC-1": TimeZone.UTC_MINUS_1,
    "UTC-2": TimeZone.UTC_MINUS_2,
    "UTC-3": TimeZone.UTC_MINUS_3,
    "UTC-4": TimeZone.UTC_MINUS_4,
    "UTC-5": TimeZone.UTC_MINUS_5,
    "UTC-6": TimeZone.UTC_MINUS_6,
    "UTC-7": TimeZone.UTC_MINUS_7,
    "UTC-8": TimeZone.UTC_MINUS_8,
    "UTC-9": TimeZone.UTC_MINUS_9,
    "UTC-10": TimeZone.UTC_MINUS_10,
    "UTC-11": TimeZone.UTC_MINUS_11,
    "UTC-12": TimeZone.UTC_MINUS_12,
    "EST5EDT": TimeZone.EST5EDT,
    "Pacific/Midway": TimeZone.PACIFIC_MIDWAY,
    "Asia/Istanbul": TimeZone.ASIA_ISTANBUL,
    "America/Argentina/ComodRivadavia": TimeZone.AMERICA_ARGENTINA_COMODRIVADAVIA,
    "Asia/Baku": TimeZone.ASIA_BAKU,
    "Australia/NSW": TimeZone.AUSTRALIA_NSW,
    "Europe/Busingen": TimeZone.EUROPE_BUSINGEN,
    "America/Regina": TimeZone.AMERICA_REGINA,
    "Africa/Bangui": TimeZone.AFRICA_BANGUI,
    "Poland": TimeZone.POLAND,
    "Indian/Christmas": TimeZone.INDIAN_CHRISTMAS,
    "Australia/Queensland": TimeZone.AUSTRALIA_QUEENSLAND,
    "Asia/Bishkek": TimeZone.ASIA_BISHKEK,
    "Asia/Dubai": TimeZone.ASIA_DUBAI,
    "Africa/Mbabane": TimeZone.AFRICA_MBABANE,
    "America/Grand_Turk": TimeZone.AMERICA_GRAND_TURK,
    "America/Glace_Bay": TimeZone.AMERICA_GLACE_BAY,
    "Pacific/Enderbury": TimeZone.PACIFIC_ENDERBURY,
    "Africa/Dakar": TimeZone.AFRICA_DAKAR,
    "Africa/Algiers": TimeZone.AFRICA_ALGIERS,
    "Asia/Damascus": TimeZone.ASIA_DAMASCUS,
    "America/Rankin_Inlet": TimeZone.AMERICA_RANKIN_INLET,
    "Europe/Brussels": TimeZone.EUROPE_BRUSSELS,
    "Asia/Hovd": TimeZone.ASIA_HOVD,
    "Australia/Hobart": TimeZone.AUSTRALIA_HOBART,
    "Europe/Bucharest": TimeZone.EUROPE_BUCHAREST,
    "Asia/Gaza": TimeZone.ASIA_GAZA,
    "Iran": TimeZone.IRAN,
    "Africa/Djibouti": TimeZone.AFRICA_DJIBOUTI,
    "America/Rosario": TimeZone.AMERICA_ROSARIO,
    "Europe/Belgrade": TimeZone.EUROPE_BELGRADE,
    "Antarctica/Rothera": TimeZone.ANTARCTICA_ROTHERA,
    "Africa/Addis_Ababa": TimeZone.AFRICA_ADDIS_ABABA,
    "Asia/Dacca": TimeZone.ASIA_DACCA,
    "Asia/Krasnoyarsk": TimeZone.ASIA_KRASNOYARSK,
    "Europe/Chisinau": TimeZone.EUROPE_CHISINAU,
    "Indian/Cocos": TimeZone.INDIAN_COCOS,
    "America/Indiana/Vincennes": TimeZone.AMERICA_INDiana_VINCENNES,
    "America/Cambridge_Bay": TimeZone.AMERICA_CAMBRIDGE_BAY,
    "Asia/Thimphu": TimeZone.ASIA_THIMPHU,
    "Europe/Riga": TimeZone.EUROPE_RIGA,
    "US/Mountain": TimeZone.US_MOUNTAIN,
    "Egypt": TimeZone.EGYPT,
    "America/Argentina/Tucuman": TimeZone.AMERICA_ARGENTINA_TUCUMAN,
    "Atlantic/St_Helena": TimeZone.ATLANTIC_ST_HELENA,
    "Greenwich": TimeZone.GREENWICH,
    "Asia/Ashkhabad": TimeZone.ASIA_ASHKHABAD,
    "Europe/Nicosia": TimeZone.EUROPE_NICOSIA,
    "Asia/Aqtau": TimeZone.ASIA_AQTAU,
    "Antarctica/Mawson": TimeZone.ANTARCTICA_MAWSON,
    "America/North_Dakota/Center": TimeZone.AMERICA_NORTH_DAKOTA_CENTER,
    "EET": TimeZone.EET,
    "ROC": TimeZone.ROC,
    "America/Mendoza": TimeZone.AMERICA_MENDOZA,
    "America/St_Vincent": TimeZone.AMERICA_ST_VINCENT,
    "CST6CDT": TimeZone.CST6CDT,
    "Asia/Bahrain": TimeZone.ASIA_BAHRAIN,
    "Asia/Riyadh": TimeZone.ASIA_RIYADH,
    "Pacific/Efate": TimeZone.PACIFIC_EFATE,
    "Indian/Mauritius": TimeZone.INDIAN_MAURITIUS,
    "Indian/Kerguelen": TimeZone.INDIAN_KERGULEN,
    "Asia/Colombo": TimeZone.ASIA_COLOMBO,
    "Africa/Maseru": TimeZone.AFRICA_MASERU,
    "America/Asuncion": TimeZone.AMERICA_ASUNCION,
    "Europe/Copenhagen": TimeZone.EUROPE_COPENHAGEN,
    "America/Argentina/Salta": TimeZone.AMERICA_ARGENTINA_SALTA,
    "Africa/Malabo": TimeZone.AFRICA_MALABO,
    "America/Matamoros": TimeZone.AMERICA_MATAMOROS,
    "America/Argentina/La_Rioja": TimeZone.AMERICA_ARGENTINA_LA_RIOJA,
    "Africa/Accra": TimeZone.AFRICA_ACCRA,
    "Eire": TimeZone.EIRE,
    "America/Kentucky/Louisville": TimeZone.AMERICA_KENTUCKY_LOUISVILLE,
    "Africa/Bamako": TimeZone.AFRICA_BAMAKO,
    "Etc/GMT-5": TimeZone.ETC_GMT_5,
    "Pacific/Chatham": TimeZone.PACIFIC_CHATHAM,
    "WET": TimeZone.WET,
    "Etc/GMT+5": TimeZone.ETC_GMT_PLUS_5,
    "Africa/Mogadishu": TimeZone.AFRICA_MOGADISHU,
    "America/Thule": TimeZone.AMERICA_THULE,
    "America/Phoenix": TimeZone.AMERICA_PHOENIX,
    "Australia/Lord_Howe": TimeZone.AUSTRALIA_LORD_HOWE,
    "Pacific/Chuuk": TimeZone.PACIFIC_CHUUK,
    "Pacific/Marquesas": TimeZone.PACIFIC_MARQUESAS,
    "Pacific/Wake": TimeZone.PACIFIC_WAKE,
    "Africa/Brazzaville": TimeZone.AFRICA_BRAZZAVILLE,
    "Australia/Broken_Hill": TimeZone.AUSTRALIA_BROKEN_HILL,
    "Australia/South": TimeZone.AUSTRALIA_SOUTH,
    "America/Kentucky/Monticello": TimeZone.AMERICA_KENTUCKY_MONTICELLO,
    "Europe/Kiev": TimeZone.EUROPE_KIEV,
    "Etc/GMT-9": TimeZone.ETC_GMT_9,
    "Australia/Lindeman": TimeZone.AUSTRALIA_LINDEMAN,
    "America/Metlakatla": TimeZone.AMERICA_METLAKATLA,
    "America/Goose_Bay": TimeZone.AMERICA_GOOSE_BAY,
    "America/St_Lucia": TimeZone.AMERICA_ST_LUCIA,
    "Europe/Ljubljana": TimeZone.EUROPE_LJUBLJANA,
    "Europe/Tirane": TimeZone.EUROPE_TIRANE,
    "America/Santarem": TimeZone.AMERICA_SANTAREM,
    "Atlantic/Canary": TimeZone.ATLANTIC_CANARY,
    "America/Grenada": TimeZone.AMERICA_GRENADA,
    "America/Shiprock": TimeZone.AMERICA_SHIPROCK,
    "Europe/Skopje": TimeZone.EUROPE_SKOPJE,
    "Etc/GMT+8": TimeZone.ETC_GMT_PLUS_8,
    "Asia/Baghdad": TimeZone.ASIA_BAGHDAD,
    "Australia/Sydney": TimeZone.AUSTRALIA_SYDNEY,
    "Europe/Istanbul": TimeZone.EUROPE_ISTANBUL,
    "America/Dominica": TimeZone.AMERICA_DOMINICA,
    "America/Nipigon": TimeZone.AMERICA_NIPIGON,
    "Asia/Calcutta": TimeZone.ASIA_CALCUTTA,
    "Etc/GMT-0": TimeZone.ETC_GMT_0,
    "Antarctica/Casey": TimeZone.ANTARCTICA_CASEY,
    "Asia/Vladivostok": TimeZone.ASIA_VLADIVOSTOK,
    "America/Godthab": TimeZone.AMERICA_GODTHAB,
    "Asia/Aqtube": TimeZone.ASIA_AQTUBE,
    "Europe/Kirov": TimeZone.EUROPE_KIROV,
    "Asia/Aden": TimeZone.ASIA_ADEN,
    "Europe/Isle_of_Man": TimeZone.EUROPE_ISLE_OF_MAN,
}