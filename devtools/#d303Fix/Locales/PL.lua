--[[
	d303Fix v0.9 by DRACULA
	Released under to public domain - http://en.wikipedia.org/wiki/Public_Domain
]]

--[[
	¹ - \196\133
	æ - \196\135
	ê - \196\153
	³ - \197\130
	ñ - \197\132
	ó - \195\178
	œ - \197\155
	¿ - \197\188
	Ÿ - \197\186
]]

d303Fix.Strings = {
	Header			= "[|cff00ff00d303Fix|r] ",
	Init			= "Za\197\130adowany z czasem: %s.\
Wpisz |cff00ff00/dtis help|r lub |cff00ff00/dtss help|r aby dowiedzie\196\135 si\196\153 wi\196\153cej o poleceniach.",
	NoFn			= "Funkcja \"%s\" jest niedost\196\153pna.",
	OsRedeclared	= "Obiekt os jest zadeklarowany. Zast\196\153powanie.",
	
	ItemShop = {
		On			= "Item Shop b\196\153dzie pr\195\178bkowany w celu pobrania czasu.",
		Off			= "Item Shop nie b\196\153dzie pr\195\178bkowany w celu pobrania czasu.",
		Offset		= "Czas pr\195\178bkowany z Item Shop'a przesuni\196\153ty o %d godzin(e).",
		Attempt		= "Pr\195\178ba pr\195\178bkowania czasu z Item Shop'a.",
		Success		= "Czas ustawiony na: %s z przesuni\196\153ciem %d godzin korzystaj\196\133c z informacji o przedmiocie z Item Shop'a: \"%s\".",
		Fail		= "Pr\195\178ba pr\195\178bkowania czasu z Item Shop'a zako\197\132czy\197\130a si\196\153 niepowodzeniem. Pozosta\197\130o %d pr\195\178b.",
		Help		= "Polecenia zwi\196\133zane z Item Shop'em:\
- |cff00ff00/dtis help|r - Wy\197\155wietla t\196\133 informacje.\
- |cff00ff00/dtis off|r - Wy\197\130\196\133cz pr\195\178bkowanie Item Shop'a.\
- |cff00ff00/dtis on|r - W\197\130\196\133cz pr\195\178bkowanie Item Shop'a.\
- |cff00ff00/dtis [hours]|r -Ustaw przesuni\196\153cie czasu pobieranego z Item Shop.\
- |cff00ff00/dtis|r - Reset\195\178j zegar (i ponownie pobierz czas z Item Shop'a).",
	},
	
	ScreenShot = {
		On			= "Screenshot b\196\153dzie ustawia\197\130 czas.",
		Off			= "Screenshot nie b\196\153dzie ustawia\197\130 czasu.",
		OnFail		= "Zrób screenshot je\197\188eli próbkowanie ItemShop'a si\196\153 niepowiedzie: ",
		Auto		= "Zrób screenshot podczas logowania: ",
		Yes			= "tak",
		No			= "nie",
		Attempt		= "Pr\195\178ba wyci\196\133gni\196\153cia czasu z nazwy screenshot'a.",
		Success		= "Czas ustawiony na: %s korzystaj\196\133c z nazwy screenshot'a.",
		Help		= "Polecenia zwi\196\133zane z Screenshot'ami:\
- |cff00ff00/dtss help|r - Wy\197\155wietla t\196\133 informacje.\
- |cff00ff00/dtss off|r - Wy\197\130\196\133cz pobieranie czasu z nazwy screenshot'a.\
- |cff00ff00/dtss on|r - W\197\130\196\133cz pobieranie czasu z nazwy screenshot'a.\
- |cff00ff00/dtss auto|r - W\197\130\196\133cza/Wy\197\130\196\133cza automatyczne robienie screenshot'a przy logowaniu.\
- |cff00ff00/dtss fail|r - W\197\130\196\133cza/Wy\197\130\196\133cza automatyczne robienie screenshot'a, gdy pr\195\178bkowanie Item Shop'a zawiedzie.\
- |cff00ff00/dtss|r - Zr\195\178b screenshot (niezale\197\188nie od powy\197\188szych opcji).",
	},

	MonthsShort		= { "Sty", "Lut", "Mar", "Kwi", "Maj", "Cze", "Lip", "Sie", "Wrz", "Pa\197\186", "Lis", "Gru", },
	MonthsFull		= { "Stycze\197\132", "Luty", "Marzec", "Kwiecie\197\132", "Maj", "Czerwiec", "Lipiec", "Sierpie\197\132", "Wrzesie\197\132", "Pa\197\186dziernik", "Listopad", "Grudzie\197\132", },
		
	WeekDaysShort	= { "Nie", "Pon", "Wto", "Sro", "Czw", "Pi\196\133", "sob", },
	WeekDaysFull	= { "Niedziela", "Poniedzia\197\130ek", "Wtorek", "Sroda", "Czwartek", "Pi\196\133tek", "Sobota", },
}
