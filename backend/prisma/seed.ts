import { Prisma, PrismaClient } from '@prisma/client';
import { BODY_TYPE_PROFILES } from './body-type-profiles';
import { CARGO_CATEGORIES } from './cargo-categories';

const prisma = new PrismaClient();

type I18n = { kk: string; ru: string; zh: string; en?: string };

const countries: {
  code: string;
  name: I18n;
  isCisMember: boolean;
  sortOrder: number;
}[] = [
  { code: 'KZ', name: { kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦', en: 'Kazakhstan' }, isCisMember: true, sortOrder: 0 },
  { code: 'CN', name: { kk: 'Қытай', ru: 'Китай', zh: '中国', en: 'China' }, isCisMember: false, sortOrder: 1 },
  { code: 'RU', name: { kk: 'Ресей', ru: 'Россия', zh: '俄罗斯', en: 'Russia' }, isCisMember: true, sortOrder: 2 },
  { code: 'KG', name: { kk: 'Қырғызстан', ru: 'Кыргызстан', zh: '吉尔吉斯斯坦', en: 'Kyrgyzstan' }, isCisMember: true, sortOrder: 3 },
  { code: 'UZ', name: { kk: 'Өзбекстан', ru: 'Узбекистан', zh: '乌兹别克斯坦', en: 'Uzbekistan' }, isCisMember: true, sortOrder: 4 },
  { code: 'TJ', name: { kk: 'Тәжікстан', ru: 'Таджикистан', zh: '塔吉克斯坦', en: 'Tajikistan' }, isCisMember: true, sortOrder: 5 },
  { code: 'TM', name: { kk: 'Түрікменстан', ru: 'Туркменистан', zh: '土库曼斯坦', en: 'Turkmenistan' }, isCisMember: true, sortOrder: 6 },
  { code: 'AZ', name: { kk: 'Әзербайжан', ru: 'Азербайджан', zh: '阿塞拜疆', en: 'Azerbaijan' }, isCisMember: true, sortOrder: 7 },
  { code: 'AM', name: { kk: 'Армения', ru: 'Армения', zh: '亚美尼亚', en: 'Armenia' }, isCisMember: true, sortOrder: 8 },
  { code: 'BY', name: { kk: 'Беларусь', ru: 'Беларусь', zh: '白俄罗斯', en: 'Belarus' }, isCisMember: true, sortOrder: 9 },
  { code: 'MD', name: { kk: 'Молдова', ru: 'Молдова', zh: '摩尔多瓦', en: 'Moldova' }, isCisMember: true, sortOrder: 10 },
  { code: 'UA', name: { kk: 'Украина', ru: 'Украина', zh: '乌克兰', en: 'Ukraine' }, isCisMember: false, sortOrder: 11 },
  { code: 'GE', name: { kk: 'Грузия', ru: 'Грузия', zh: '格鲁吉亚', en: 'Georgia' }, isCisMember: false, sortOrder: 12 },
  { code: 'MN', name: { kk: 'Моңғолия', ru: 'Монголия', zh: '蒙古', en: 'Mongolia' }, isCisMember: false, sortOrder: 13 },
  { code: 'IR', name: { kk: 'Иран', ru: 'Иран', zh: '伊朗', en: 'Iran' }, isCisMember: false, sortOrder: 14 },
];

// Области Казахстана (17) + 3 города республиканского значения.
// Хоргос находится в области Жетісу (Панфиловский район, рядом с Жаркентом).
const kzRegions: { code: string; name: I18n; adminCenter: I18n }[] = [
  { code: 'ABAI', name: { kk: 'Абай облысы', ru: 'Абайская область', zh: '阿拜州', en: 'Abai Region' }, adminCenter: { kk: 'Семей', ru: 'Семей', zh: '塞梅伊', en: 'Semey' } },
  { code: 'AKMOLA', name: { kk: 'Ақмола облысы', ru: 'Акмолинская область', zh: '阿克莫拉州', en: 'Akmola Region' }, adminCenter: { kk: 'Көкшетау', ru: 'Кокшетау', zh: '科克舍陶', en: 'Kokshetau' } },
  { code: 'AKTOBE', name: { kk: 'Ақтөбе облысы', ru: 'Актюбинская область', zh: '阿克托别州', en: 'Aktobe Region' }, adminCenter: { kk: 'Ақтөбе', ru: 'Актобе', zh: '阿克托别', en: 'Aktobe' } },
  { code: 'ALMATY_REGION', name: { kk: 'Алматы облысы', ru: 'Алматинская область', zh: '阿拉木图州', en: 'Almaty Region' }, adminCenter: { kk: 'Қонаев', ru: 'Конаев', zh: '科纳耶夫', en: 'Konaev' } },
  { code: 'ATYRAU', name: { kk: 'Атырау облысы', ru: 'Атырауская область', zh: '阿特劳州', en: 'Atyrau Region' }, adminCenter: { kk: 'Атырау', ru: 'Атырау', zh: '阿特劳', en: 'Atyrau' } },
  { code: 'EAST_KZ', name: { kk: 'Шығыс Қазақстан облысы', ru: 'Восточно-Казахстанская область', zh: '东哈萨克斯坦州', en: 'East Kazakhstan Region' }, adminCenter: { kk: 'Өскемен', ru: 'Усть-Каменогорск', zh: '厄斯克门', en: 'Oskemen' } },
  { code: 'ZHAMBYL', name: { kk: 'Жамбыл облысы', ru: 'Жамбылская область', zh: '江布尔州', en: 'Zhambyl Region' }, adminCenter: { kk: 'Тараз', ru: 'Тараз', zh: '塔拉兹', en: 'Taraz' } },
  { code: 'ZHETYSU', name: { kk: 'Жетісу облысы', ru: 'Область Жетысу', zh: '哲特苏州', en: 'Zhetysu Region' }, adminCenter: { kk: 'Талдықорған', ru: 'Талдыкорган', zh: '塔尔迪库尔干', en: 'Taldykorgan' } },
  { code: 'WEST_KZ', name: { kk: 'Батыс Қазақстан облысы', ru: 'Западно-Казахстанская область', zh: '西哈萨克斯坦州', en: 'West Kazakhstan Region' }, adminCenter: { kk: 'Орал', ru: 'Уральск', zh: '乌拉尔斯克', en: 'Oral' } },
  { code: 'KARAGANDY', name: { kk: 'Қарағанды облысы', ru: 'Карагандинская область', zh: '卡拉干达州', en: 'Karagandy Region' }, adminCenter: { kk: 'Қарағанды', ru: 'Караганда', zh: '卡拉干达', en: 'Karagandy' } },
  { code: 'KOSTANAY', name: { kk: 'Қостанай облысы', ru: 'Костанайская область', zh: '科斯塔奈州', en: 'Kostanay Region' }, adminCenter: { kk: 'Қостанай', ru: 'Костанай', zh: '科斯塔奈', en: 'Kostanay' } },
  { code: 'KYZYLORDA', name: { kk: 'Қызылорда облысы', ru: 'Кызылординская область', zh: '克孜勒奥尔达州', en: 'Kyzylorda Region' }, adminCenter: { kk: 'Қызылорда', ru: 'Кызылорда', zh: '克孜勒奥尔达', en: 'Kyzylorda' } },
  { code: 'MANGYSTAU', name: { kk: 'Маңғыстау облысы', ru: 'Мангистауская область', zh: '曼吉斯套州', en: 'Mangystau Region' }, adminCenter: { kk: 'Ақтау', ru: 'Актау', zh: '阿克套', en: 'Aktau' } },
  { code: 'PAVLODAR', name: { kk: 'Павлодар облысы', ru: 'Павлодарская область', zh: '巴甫洛达尔州', en: 'Pavlodar Region' }, adminCenter: { kk: 'Павлодар', ru: 'Павлодар', zh: '巴甫洛达尔', en: 'Pavlodar' } },
  { code: 'NORTH_KZ', name: { kk: 'Солтүстік Қазақстан облысы', ru: 'Северо-Казахстанская область', zh: '北哈萨克斯坦州', en: 'North Kazakhstan Region' }, adminCenter: { kk: 'Петропавл', ru: 'Петропавловск', zh: '彼得罗巴甫洛夫斯克', en: 'Petropavl' } },
  { code: 'TURKISTAN', name: { kk: 'Түркістан облысы', ru: 'Туркестанская область', zh: '突厥斯坦州', en: 'Turkistan Region' }, adminCenter: { kk: 'Түркістан', ru: 'Туркестан', zh: '突厥斯坦', en: 'Turkistan' } },
  { code: 'ULYTAU', name: { kk: 'Ұлытау облысы', ru: 'Улытауская область', zh: '乌雷套州', en: 'Ulytau Region' }, adminCenter: { kk: 'Жезқазған', ru: 'Жезказган', zh: '杰兹卡兹甘', en: 'Zhezkazgan' } },
];

const kzRepublicanCities: { code: string; name: I18n; isCapital: boolean }[] = [
  { code: 'KZ-ASTANA', name: { kk: 'Астана', ru: 'Астана', zh: '阿斯塔纳', en: 'Astana' }, isCapital: true },
  { code: 'KZ-ALMATY', name: { kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图', en: 'Almaty' }, isCapital: false },
  { code: 'KZ-SHYMKENT', name: { kk: 'Шымкент', ru: 'Шымкент', zh: '奇姆肯特', en: 'Shymkent' }, isCapital: false },
];

// Хоргос — приграничный город/сухой порт в Жетісуской области, рядом с Жаркентом.
const khorgosCity: I18n = { kk: 'Қорғас', ru: 'Хоргос', zh: '霍尔果斯', en: 'Khorgos' };
const zharkentCity: I18n = { kk: 'Жаркент', ru: 'Жаркент', zh: '扎尔肯特', en: 'Zharkent' };

// Дополнительные города/райцентры по областям — реальные, проверенные
// названия (не выдумываем переводы: zh оставлен пустым там, где нет
// уверенного перевода — по тексту задачи это ожидаемо и даёт фолбэк на ru).
// Это не исчерпывающий список всех ~200 райцентров РК — честная, точная
// выборка самых известных городов; остальные районные центры со временем
// появятся через «Нет моего города» → модерация админом (задача 021).
const kzDistrictCities: { code: string; regionCode: string; name: I18n }[] = [
  { code: 'KZ-ABAI-AYAGOZ', regionCode: 'ABAI', name: { kk: 'Аягөз', ru: 'Аягоз', zh: '', en: 'Ayagoz' } },
  { code: 'KZ-ABAI-KURCHATOV', regionCode: 'ABAI', name: { kk: 'Курчатов', ru: 'Курчатов', zh: '', en: 'Kurchatov' } },
  { code: 'KZ-AKMOLA-STEPNOGORSK', regionCode: 'AKMOLA', name: { kk: 'Степногорск', ru: 'Степногорск', zh: '', en: 'Stepnogorsk' } },
  { code: 'KZ-AKMOLA-SHCHUCHINSK', regionCode: 'AKMOLA', name: { kk: 'Щучинск', ru: 'Щучинск', zh: '', en: 'Shchuchinsk' } },
  { code: 'KZ-AKMOLA-ATBASAR', regionCode: 'AKMOLA', name: { kk: 'Атбасар', ru: 'Атбасар', zh: '', en: 'Atbasar' } },
  { code: 'KZ-AKTOBE-KHROMTAU', regionCode: 'AKTOBE', name: { kk: 'Хромтау', ru: 'Хромтау', zh: '', en: 'Khromtau' } },
  { code: 'KZ-AKTOBE-SHALKAR', regionCode: 'AKTOBE', name: { kk: 'Шалқар', ru: 'Шалкар', zh: '', en: 'Shalkar' } },
  { code: 'KZ-ALMATY_REGION-TALGAR', regionCode: 'ALMATY_REGION', name: { kk: 'Талғар', ru: 'Талгар', zh: '', en: 'Talgar' } },
  { code: 'KZ-ALMATY_REGION-KASKELEN', regionCode: 'ALMATY_REGION', name: { kk: 'Қаскелең', ru: 'Каскелен', zh: '', en: 'Kaskelen' } },
  { code: 'KZ-ALMATY_REGION-ESIK', regionCode: 'ALMATY_REGION', name: { kk: 'Есік', ru: 'Есик', zh: '', en: 'Esik' } },
  { code: 'KZ-ATYRAU-KULSARY', regionCode: 'ATYRAU', name: { kk: 'Құлсары', ru: 'Кульсары', zh: '', en: 'Kulsary' } },
  { code: 'KZ-EAST_KZ-RIDDER', regionCode: 'EAST_KZ', name: { kk: 'Риддер', ru: 'Риддер', zh: '', en: 'Ridder' } },
  { code: 'KZ-EAST_KZ-ZYRYANOVSK', regionCode: 'EAST_KZ', name: { kk: 'Зыряновск', ru: 'Зыряновск', zh: '', en: 'Zyryanovsk' } },
  { code: 'KZ-ZHAMBYL-SHU', regionCode: 'ZHAMBYL', name: { kk: 'Шу', ru: 'Шу', zh: '', en: 'Shu' } },
  { code: 'KZ-ZHAMBYL-KARATAU', regionCode: 'ZHAMBYL', name: { kk: 'Қаратау', ru: 'Каратау', zh: '', en: 'Karatau' } },
  { code: 'KZ-ZHAMBYL-ZHANATAS', regionCode: 'ZHAMBYL', name: { kk: 'Жаңатас', ru: 'Жанатас', zh: '', en: 'Zhanatas' } },
  { code: 'KZ-ZHETYSU-USHARAL', regionCode: 'ZHETYSU', name: { kk: 'Үшарал', ru: 'Ушарал', zh: '', en: 'Usharal' } },
  { code: 'KZ-ZHETYSU-SARKAND', regionCode: 'ZHETYSU', name: { kk: 'Сарқанд', ru: 'Сарканд', zh: '', en: 'Sarkand' } },
  { code: 'KZ-WEST_KZ-AKSAI', regionCode: 'WEST_KZ', name: { kk: 'Ақсай', ru: 'Аксай', zh: '', en: 'Aksai' } },
  { code: 'KZ-KARAGANDY-TEMIRTAU', regionCode: 'KARAGANDY', name: { kk: 'Теміртау', ru: 'Темиртау', zh: '', en: 'Temirtau' } },
  { code: 'KZ-KARAGANDY-BALKHASH', regionCode: 'KARAGANDY', name: { kk: 'Балқаш', ru: 'Балхаш', zh: '', en: 'Balkhash' } },
  { code: 'KZ-KARAGANDY-SARAN', regionCode: 'KARAGANDY', name: { kk: 'Сарань', ru: 'Сарань', zh: '', en: 'Saran' } },
  { code: 'KZ-KOSTANAY-RUDNY', regionCode: 'KOSTANAY', name: { kk: 'Рудный', ru: 'Рудный', zh: '', en: 'Rudny' } },
  { code: 'KZ-KOSTANAY-LISAKOVSK', regionCode: 'KOSTANAY', name: { kk: 'Лисаковск', ru: 'Лисаковск', zh: '', en: 'Lisakovsk' } },
  { code: 'KZ-KYZYLORDA-BAIKONUR', regionCode: 'KYZYLORDA', name: { kk: 'Байқоңыр', ru: 'Байконур', zh: '', en: 'Baikonur' } },
  { code: 'KZ-KYZYLORDA-ARALSK', regionCode: 'KYZYLORDA', name: { kk: 'Арал', ru: 'Аральск', zh: '', en: 'Aralsk' } },
  { code: 'KZ-MANGYSTAU-ZHANAOZEN', regionCode: 'MANGYSTAU', name: { kk: 'Жаңаөзен', ru: 'Жанаозен', zh: '', en: 'Zhanaozen' } },
  { code: 'KZ-PAVLODAR-EKIBASTUZ', regionCode: 'PAVLODAR', name: { kk: 'Екібастұз', ru: 'Экибастуз', zh: '', en: 'Ekibastuz' } },
  { code: 'KZ-PAVLODAR-AKSU', regionCode: 'PAVLODAR', name: { kk: 'Ақсу', ru: 'Аксу', zh: '', en: 'Aksu' } },
  { code: 'KZ-NORTH_KZ-TAIYNSHA', regionCode: 'NORTH_KZ', name: { kk: 'Тайынша', ru: 'Тайынша', zh: '', en: 'Taiynsha' } },
  { code: 'KZ-TURKISTAN-SARYAGASH', regionCode: 'TURKISTAN', name: { kk: 'Сарыағаш', ru: 'Сарыагаш', zh: '', en: 'Saryagash' } },
  { code: 'KZ-TURKISTAN-ZHETYSAY', regionCode: 'TURKISTAN', name: { kk: 'Жетісай', ru: 'Жетысай', zh: '', en: 'Zhetysay' } },
  { code: 'KZ-TURKISTAN-ARYS', regionCode: 'TURKISTAN', name: { kk: 'Арыс', ru: 'Арыс', zh: '', en: 'Arys' } },
  { code: 'KZ-TURKISTAN-KENTAU', regionCode: 'TURKISTAN', name: { kk: 'Кентау', ru: 'Кентау', zh: '', en: 'Kentau' } },
  { code: 'KZ-ULYTAU-SATBAYEV', regionCode: 'ULYTAU', name: { kk: 'Сәтбаев', ru: 'Сатпаев', zh: '', en: 'Satbayev' } },
];

// Крупные города/столицы соседних стран — для выбора «домашний город» водителя.
// Расширено по маршрутам из Хоргоса (задача 021): Синьцзян (CN), Узбекистан,
// Киргизия, Таджикистан, Туркменистан, юг России.
const foreignCities: Record<string, { code: string; name: I18n; isCapital: boolean }[]> = {
  CN: [
    { code: 'CN-BEIJING', name: { kk: 'Пекин', ru: 'Пекин', zh: '北京', en: 'Beijing' }, isCapital: true },
    { code: 'CN-URUMQI', name: { kk: 'Үрімші', ru: 'Урумчи', zh: '乌鲁木齐', en: 'Urumqi' }, isCapital: false },
    { code: 'CN-KASHGAR', name: { kk: 'Қашқар', ru: 'Кашгар', zh: '喀什', en: 'Kashgar' }, isCapital: false },
    { code: 'CN-YINING', name: { kk: 'Құлжа', ru: 'Инин (Кульджа)', zh: '伊宁', en: 'Yining' }, isCapital: false },
    { code: 'CN-KORLA', name: { kk: 'Корла', ru: 'Корла', zh: '库尔勒', en: 'Korla' }, isCapital: false },
  ],
  RU: [
    { code: 'RU-MOSCOW', name: { kk: 'Мәскеу', ru: 'Москва', zh: '莫斯科', en: 'Moscow' }, isCapital: true },
    { code: 'RU-NOVOSIBIRSK', name: { kk: 'Новосібір', ru: 'Новосибирск', zh: '新西伯利亚', en: 'Novosibirsk' }, isCapital: false },
    { code: 'RU-OMSK', name: { kk: 'Омбы', ru: 'Омск', zh: '', en: 'Omsk' }, isCapital: false },
  ],
  KG: [
    { code: 'KG-BISHKEK', name: { kk: 'Бішкек', ru: 'Бишкек', zh: '比什凯克', en: 'Bishkek' }, isCapital: true },
    { code: 'KG-OSH', name: { kk: 'Ош', ru: 'Ош', zh: '', en: 'Osh' }, isCapital: false },
  ],
  UZ: [
    { code: 'UZ-TASHKENT', name: { kk: 'Ташкент', ru: 'Ташкент', zh: '塔什干', en: 'Tashkent' }, isCapital: true },
    { code: 'UZ-SAMARKAND', name: { kk: 'Самарқанд', ru: 'Самарканд', zh: '撒马尔罕', en: 'Samarkand' }, isCapital: false },
  ],
  TJ: [{ code: 'TJ-DUSHANBE', name: { kk: 'Душанбе', ru: 'Душанбе', zh: '杜尚别', en: 'Dushanbe' }, isCapital: true }],
  TM: [{ code: 'TM-ASHGABAT', name: { kk: 'Ашғабат', ru: 'Ашхабад', zh: '阿什哈巴德', en: 'Ashgabat' }, isCapital: true }],
  AZ: [{ code: 'AZ-BAKU', name: { kk: 'Баку', ru: 'Баку', zh: '巴库', en: 'Baku' }, isCapital: true }],
  AM: [{ code: 'AM-YEREVAN', name: { kk: 'Ереван', ru: 'Ереван', zh: '埃里温', en: 'Yerevan' }, isCapital: true }],
  BY: [{ code: 'BY-MINSK', name: { kk: 'Минск', ru: 'Минск', zh: '明斯克', en: 'Minsk' }, isCapital: true }],
  MD: [{ code: 'MD-CHISINAU', name: { kk: 'Кишинев', ru: 'Кишинёв', zh: '基希讷乌', en: 'Chisinau' }, isCapital: true }],
  UA: [{ code: 'UA-KYIV', name: { kk: 'Киев', ru: 'Киев', zh: '基辅', en: 'Kyiv' }, isCapital: true }],
  GE: [{ code: 'GE-TBILISI', name: { kk: 'Тбилиси', ru: 'Тбилиси', zh: '第比利斯', en: 'Tbilisi' }, isCapital: true }],
  MN: [{ code: 'MN-ULAANBAATAR', name: { kk: 'Ұланбатыр', ru: 'Улан-Батор', zh: '乌兰巴托', en: 'Ulaanbaatar' }, isCapital: true }],
  IR: [{ code: 'IR-TEHRAN', name: { kk: 'Тегеран', ru: 'Тегеран', zh: '德黑兰', en: 'Tehran' }, isCapital: true }],
};

const bodyTypes: { code: string; name: I18n; sortOrder: number }[] = [
  { code: 'TENT', name: { kk: 'Тентті', ru: 'Тентованный', zh: '帆布篷车', en: 'Curtainsider' }, sortOrder: 0 },
  { code: 'REFRIGERATOR', name: { kk: 'Рефрижератор', ru: 'Рефрижератор', zh: '冷藏车', en: 'Reefer' }, sortOrder: 1 },
  { code: 'ISOTHERM', name: { kk: 'Изотермиялық', ru: 'Изотермический', zh: '保温车', en: 'Insulated van' }, sortOrder: 2 },
  { code: 'FLATBED', name: { kk: 'Бортты', ru: 'Бортовой', zh: '平板车', en: 'Flatbed' }, sortOrder: 3 },
  { code: 'CONTAINER', name: { kk: 'Контейнеровоз', ru: 'Контейнеровоз', zh: '集装箱车', en: 'Container carrier' }, sortOrder: 4 },
  { code: 'DUMP', name: { kk: 'Самосвал', ru: 'Самосвал', zh: '自卸车', en: 'Dump truck' }, sortOrder: 5 },
  { code: 'LOWLOADER', name: { kk: 'Аласа рамалы трал', ru: 'Низкорамный трал', zh: '低平板拖车', en: 'Low loader' }, sortOrder: 6 },
  { code: 'CARCARRIER', name: { kk: 'Автотасығыш', ru: 'Автовоз', zh: '汽车运输车', en: 'Car carrier' }, sortOrder: 7 },
  { code: 'GRAIN', name: { kk: 'Астық тасығыш', ru: 'Зерновоз', zh: '谷物运输车', en: 'Grain truck' }, sortOrder: 8 },
  { code: 'TANK', name: { kk: 'Цистерна', ru: 'Цистерна', zh: '罐车', en: 'Tanker' }, sortOrder: 9 },
];

/// Шаблоны размеров кузова (задача 033) — значения ОРИЕНТИРОВОЧНЫЕ
/// (уточнить с Болатом и водителями), админ правит без релиза.
/// `bodyTypeCodes` резолвится в bodyTypeIds при сиде.
const bodySizePresets: {
  code: string;
  name: I18n;
  bodyTypeCodes: string[];
  innerLengthM: number | null;
  innerWidthM: number | null;
  innerHeightM: number | null;
  volumeM3: number | null;
  palletsEuro: number | null;
  palletsStandard: number | null;
  sortOrder: number;
}[] = [
  {
    code: 'STANDARD',
    name: { kk: 'Стандарт (тент/изотерм)', ru: 'Стандарт (тент/изотерм)', zh: '标准（帆布篷/保温）', en: 'Standard (curtainsider/insulated)' },
    bodyTypeCodes: ['TENT', 'ISOTHERM'],
    innerLengthM: 13.6, innerWidthM: 2.45, innerHeightM: 2.7, volumeM3: 90, palletsEuro: 33, palletsStandard: 26, sortOrder: 0,
  },
  {
    code: 'MEGA',
    name: { kk: 'Мега', ru: 'Мега', zh: '加高型', en: 'Mega' },
    bodyTypeCodes: ['TENT'],
    innerLengthM: 13.6, innerWidthM: 2.45, innerHeightM: 3.0, volumeM3: 100, palletsEuro: 33, palletsStandard: 26, sortOrder: 1,
  },
  {
    code: 'JUMBO',
    name: { kk: 'Джамбо/тіркеспе', ru: 'Джамбо/сцепка', zh: '大容积挂车组', en: 'Jumbo / road train' },
    bodyTypeCodes: ['TENT'],
    innerLengthM: 15.4, innerWidthM: 2.45, innerHeightM: 3.0, volumeM3: 115, palletsEuro: 38, palletsStandard: 30, sortOrder: 2,
  },
  {
    code: 'REEFER',
    name: { kk: 'Реф', ru: 'Реф', zh: '冷藏', en: 'Reefer' },
    bodyTypeCodes: ['REFRIGERATOR'],
    innerLengthM: 13.4, innerWidthM: 2.46, innerHeightM: 2.6, volumeM3: 85, palletsEuro: 33, palletsStandard: 26, sortOrder: 3,
  },
  {
    code: 'RIGID_7M',
    name: { kk: 'Жалғыз 7 м', ru: 'Одиночка 7 м', zh: '单车7米', en: 'Rigid 7 m' },
    bodyTypeCodes: ['TENT', 'ISOTHERM', 'FLATBED'],
    innerLengthM: 7.2, innerWidthM: 2.45, innerHeightM: 2.4, volumeM3: 42, palletsEuro: 18, palletsStandard: 14, sortOrder: 4,
  },
];

const permits: { code: string; name: I18n; sortOrder: number }[] = [
  { code: 'TIR', name: { kk: 'TIR кітапшасы', ru: 'Книжка МДП (TIR)', zh: 'TIR单证', en: 'TIR carnet' }, sortOrder: 0 },
  { code: 'CMR', name: { kk: 'CMR жүкқұжаты', ru: 'CMR-накладная', zh: 'CMR运单', en: 'CMR waybill' }, sortOrder: 1 },
  { code: 'ADR', name: { kk: 'ADR рұқсаты (қауіпті жүктер)', ru: 'Допуск ADR (опасные грузы)', zh: 'ADR危险品准运证', en: 'ADR permit (dangerous goods)' }, sortOrder: 2 },
  { code: 'OVERSIZE', name: { kk: 'Негабарит жүкке рұқсат', ru: 'Допуск на негабаритный груз', zh: '超限运输许可', en: 'Oversize cargo permit' }, sortOrder: 3 },
  { code: 'SANITARY', name: { kk: 'Санитарлық паспорт', ru: 'Санитарный паспорт', zh: '卫生护照', en: 'Sanitary passport' }, sortOrder: 4 },
];

const messageTemplates: { code: string; category: string; text: I18n }[] = [
  {
    code: 'CONTACT_FOLLOWUP',
    category: 'contact_reminder',
    text: { kk: 'Келістіңіздер ме?', ru: 'Договорились?', zh: '谈好了吗?', en: 'Did you agree?' },
  },
  {
    code: 'CARGO_ARCHIVED',
    category: 'cargo_lifecycle',
    text: { kk: 'Жүк мұрағатталды', ru: 'Груз архивирован', zh: '货物已归档', en: 'Cargo archived' },
  },
];

// Координаты городов-точек погрузки (задача 040): областные центры, города
// республиканского значения, Хоргос/Жаркент — для сортировки ленты «≤200 км»
// и геозоны терминала.
const pointCoords: Record<string, { lat: number; lng: number }> = {
  'KZ-ABAI-ADMIN': { lat: 50.4111, lng: 80.2275 },
  'KZ-AKMOLA-ADMIN': { lat: 53.2948, lng: 69.4048 },
  'KZ-AKTOBE-ADMIN': { lat: 50.2839, lng: 57.167 },
  'KZ-ALMATY_REGION-ADMIN': { lat: 43.8667, lng: 77.0667 },
  'KZ-ATYRAU-ADMIN': { lat: 47.1164, lng: 51.883 },
  'KZ-EAST_KZ-ADMIN': { lat: 49.9487, lng: 82.628 },
  'KZ-ZHAMBYL-ADMIN': { lat: 42.9, lng: 71.3667 },
  'KZ-ZHETYSU-ADMIN': { lat: 45.0156, lng: 78.3739 },
  'KZ-WEST_KZ-ADMIN': { lat: 51.2333, lng: 51.3667 },
  'KZ-KARAGANDY-ADMIN': { lat: 49.8061, lng: 73.0856 },
  'KZ-KOSTANAY-ADMIN': { lat: 53.2144, lng: 63.6246 },
  'KZ-KYZYLORDA-ADMIN': { lat: 44.8528, lng: 65.5092 },
  'KZ-MANGYSTAU-ADMIN': { lat: 43.6532, lng: 51.1975 },
  'KZ-PAVLODAR-ADMIN': { lat: 52.2873, lng: 76.9674 },
  'KZ-NORTH_KZ-ADMIN': { lat: 54.8667, lng: 69.15 },
  'KZ-TURKISTAN-ADMIN': { lat: 43.2973, lng: 68.2518 },
  'KZ-ULYTAU-ADMIN': { lat: 47.7833, lng: 67.7667 },
  'KZ-ASTANA': { lat: 51.1694, lng: 71.4491 },
  'KZ-ALMATY': { lat: 43.2389, lng: 76.8897 },
  'KZ-SHYMKENT': { lat: 42.3417, lng: 69.5901 },
  'KZ-ZHETYSU-KHORGOS': { lat: 44.2167, lng: 80.4167 },
  'KZ-ZHETYSU-ZHARKENT': { lat: 44.1667, lng: 79.9833 },
};
// Координаты остальных городов справочника (049 п.11): без них OSRM не считает
// расстояние до города назначения — км и ₸/км у груза пустые. Центры городов.
const cityCoords: Record<string, { lat: number; lng: number }> = {
  'AM-YEREVAN': { lat: 40.1792, lng: 44.4991 },
  'AZ-BAKU': { lat: 40.4093, lng: 49.8671 },
  'BY-MINSK': { lat: 53.9006, lng: 27.559 },
  'CN-BEIJING': { lat: 39.9042, lng: 116.4074 },
  'CN-KASHGAR': { lat: 39.4704, lng: 75.9898 },
  'CN-KORLA': { lat: 41.7259, lng: 86.1747 },
  'CN-URUMQI': { lat: 43.8256, lng: 87.6168 },
  'CN-YINING': { lat: 43.9168, lng: 81.3241 },
  'GE-TBILISI': { lat: 41.7151, lng: 44.8271 },
  'IR-TEHRAN': { lat: 35.6892, lng: 51.389 },
  'KG-BISHKEK': { lat: 42.8746, lng: 74.5698 },
  'KG-OSH': { lat: 40.5283, lng: 72.7985 },
  'KZ-ABAI-AYAGOZ': { lat: 47.9645, lng: 80.4344 },
  'KZ-ABAI-KURCHATOV': { lat: 50.7564, lng: 78.5404 },
  'KZ-AKMOLA-ATBASAR': { lat: 51.8, lng: 68.3333 },
  'KZ-AKMOLA-SHCHUCHINSK': { lat: 52.9333, lng: 70.2 },
  'KZ-AKMOLA-STEPNOGORSK': { lat: 52.35, lng: 71.8833 },
  'KZ-AKTOBE-KHROMTAU': { lat: 50.2503, lng: 58.4347 },
  'KZ-AKTOBE-SHALKAR': { lat: 47.8333, lng: 59.6 },
  'KZ-ALMATY_REGION-ESIK': { lat: 43.3553, lng: 77.4528 },
  'KZ-ALMATY_REGION-KASKELEN': { lat: 43.2, lng: 76.6167 },
  'KZ-ALMATY_REGION-TALGAR': { lat: 43.3, lng: 77.24 },
  'KZ-ATYRAU-KULSARY': { lat: 46.9531, lng: 54.0197 },
  'KZ-EAST_KZ-RIDDER': { lat: 50.3444, lng: 83.5122 },
  'KZ-EAST_KZ-ZYRYANOVSK': { lat: 49.7389, lng: 84.2731 },
  'KZ-KARAGANDY-BALKHASH': { lat: 46.8481, lng: 74.995 },
  'KZ-KARAGANDY-SARAN': { lat: 49.8, lng: 72.85 },
  'KZ-KARAGANDY-TEMIRTAU': { lat: 50.0549, lng: 72.9646 },
  'KZ-KOSTANAY-LISAKOVSK': { lat: 52.5369, lng: 62.4936 },
  'KZ-KOSTANAY-RUDNY': { lat: 52.9653, lng: 63.1336 },
  'KZ-KYZYLORDA-ARALSK': { lat: 46.8, lng: 61.6667 },
  'KZ-KYZYLORDA-BAIKONUR': { lat: 45.6167, lng: 63.3167 },
  'KZ-MANGYSTAU-ZHANAOZEN': { lat: 43.3412, lng: 52.8619 },
  'KZ-NORTH_KZ-TAIYNSHA': { lat: 53.8478, lng: 69.7639 },
  'KZ-PAVLODAR-AKSU': { lat: 52.0333, lng: 76.9167 },
  'KZ-PAVLODAR-EKIBASTUZ': { lat: 51.7231, lng: 75.3228 },
  'KZ-TURKISTAN-ARYS': { lat: 42.4333, lng: 68.8 },
  'KZ-TURKISTAN-KENTAU': { lat: 43.5167, lng: 68.5167 },
  'KZ-TURKISTAN-SARYAGASH': { lat: 41.45, lng: 69.1667 },
  'KZ-TURKISTAN-ZHETYSAY': { lat: 40.7753, lng: 68.3272 },
  'KZ-ULYTAU-SATBAYEV': { lat: 47.9, lng: 67.5333 },
  'KZ-WEST_KZ-AKSAI': { lat: 51.1678, lng: 52.995 },
  'KZ-ZHAMBYL-KARATAU': { lat: 43.1833, lng: 70.4667 },
  'KZ-ZHAMBYL-SHU': { lat: 43.6, lng: 73.7667 },
  'KZ-ZHAMBYL-ZHANATAS': { lat: 43.5667, lng: 69.75 },
  'KZ-ZHETYSU-SARKAND': { lat: 45.4103, lng: 79.9186 },
  'KZ-ZHETYSU-USHARAL': { lat: 46.1667, lng: 80.9333 },
  'MD-CHISINAU': { lat: 47.0105, lng: 28.8638 },
  'MN-ULAANBAATAR': { lat: 47.8864, lng: 106.9057 },
  'RU-MOSCOW': { lat: 55.7558, lng: 37.6173 },
  'RU-NOVOSIBIRSK': { lat: 55.0084, lng: 82.9357 },
  'RU-OMSK': { lat: 54.9885, lng: 73.3242 },
  'TJ-DUSHANBE': { lat: 38.5598, lng: 68.787 },
  'TM-ASHGABAT': { lat: 37.9601, lng: 58.3261 },
  'UA-KYIV': { lat: 50.4501, lng: 30.5234 },
  'UZ-SAMARKAND': { lat: 39.627, lng: 66.975 },
  'UZ-TASHKENT': { lat: 41.2995, lng: 69.2401 },
};

async function seedCityCoords() {
  for (const [code, coords] of Object.entries(cityCoords)) {
    await prisma.city.updateMany({ where: { code }, data: coords });
  }
}

const terminalPointCodes = new Set(['KZ-ZHETYSU-KHORGOS']);
/// Геозона терминала — 10 км (042 п.0, решение 2026-10-07): очередь фур стоит дальше 3 км.
const TERMINAL_RADIUS_M = 10_000;

async function seedPoints() {
  for (const [code, coords] of Object.entries(pointCoords)) {
    const city = await prisma.city.findUnique({ where: { code } });
    if (!city) continue;
    await prisma.city.update({ where: { id: city.id }, data: coords });
    const kind = terminalPointCodes.has(code) ? 'TERMINAL' : 'CITY';
    const radiusM = kind === 'TERMINAL' ? TERMINAL_RADIUS_M : null;
    const existing = await prisma.point.findFirst({ where: { cityId: city.id } });
    if (existing) {
      await prisma.point.update({ where: { id: existing.id }, data: { ...coords, kind, radiusM } });
    } else {
      // Жаркент — не точка погрузки, координаты нужны только городу.
      if (code === 'KZ-ZHETYSU-ZHARKENT') continue;
      await prisma.point.create({ data: { cityId: city.id, name: city.name as object, ...coords, kind, radiusM, isActive: true } });
    }
  }
}

async function main() {
  const countryByCode = new Map<string, string>();
  for (const c of countries) {
    const row = await prisma.country.upsert({
      where: { code: c.code },
      update: { name: c.name, isCisMember: c.isCisMember, sortOrder: c.sortOrder },
      create: { code: c.code, name: c.name, isCisMember: c.isCisMember, sortOrder: c.sortOrder },
    });
    countryByCode.set(c.code, row.id);
  }

  const kzId = countryByCode.get('KZ')!;

  const regionByCode = new Map<string, string>();
  for (const region of kzRegions) {
    const regionRow = await prisma.region.upsert({
      where: { countryId_code: { countryId: kzId, code: region.code } },
      update: { name: region.name },
      create: { code: region.code, name: region.name, countryId: kzId },
    });
    regionByCode.set(region.code, regionRow.id);

    const adminCenterCode = `KZ-${region.code}-ADMIN`;
    await prisma.city.upsert({
      where: { code: adminCenterCode },
      update: { name: region.adminCenter, countryId: kzId, regionId: regionRow.id },
      create: { code: adminCenterCode, name: region.adminCenter, countryId: kzId, regionId: regionRow.id, isCapital: false },
    });

    if (region.code === 'ZHETYSU') {
      await prisma.city.upsert({
        where: { code: 'KZ-ZHETYSU-ZHARKENT' },
        update: { name: zharkentCity, countryId: kzId, regionId: regionRow.id },
        create: { code: 'KZ-ZHETYSU-ZHARKENT', name: zharkentCity, countryId: kzId, regionId: regionRow.id, isCapital: false },
      });

      const khorgosRow = await prisma.city.upsert({
        where: { code: 'KZ-ZHETYSU-KHORGOS' },
        update: { name: khorgosCity, countryId: kzId, regionId: regionRow.id },
        create: { code: 'KZ-ZHETYSU-KHORGOS', name: khorgosCity, countryId: kzId, regionId: regionRow.id, isCapital: false },
      });

      await prisma.point.upsert({
        where: {
          id:
            (await prisma.point.findFirst({ where: { cityId: khorgosRow.id } }))?.id ?? '__none__',
        },
        update: { name: khorgosCity, cityId: khorgosRow.id, isActive: true },
        create: { name: khorgosCity, cityId: khorgosRow.id, isActive: true },
      });
    }
  }

  for (const city of kzDistrictCities) {
    const regionId = regionByCode.get(city.regionCode);
    if (!regionId) continue;
    await prisma.city.upsert({
      where: { code: city.code },
      update: { name: city.name, countryId: kzId, regionId },
      create: { code: city.code, name: city.name, countryId: kzId, regionId, isCapital: false },
    });
  }

  for (const city of kzRepublicanCities) {
    await prisma.city.upsert({
      where: { code: city.code },
      update: { name: city.name, countryId: kzId },
      create: { code: city.code, name: city.name, countryId: kzId, isCapital: city.isCapital },
    });
  }

  for (const [countryCode, cities] of Object.entries(foreignCities)) {
    const countryId = countryByCode.get(countryCode);
    if (!countryId) continue;
    for (const city of cities) {
      await prisma.city.upsert({
        where: { code: city.code },
        update: { name: city.name, countryId, isCapital: city.isCapital },
        create: { code: city.code, name: city.name, countryId, isCapital: city.isCapital },
      });
    }
  }

  await seedPoints();
  await seedCityCoords();

  for (const bt of bodyTypes) {
    // 048: профиль и поля — из prisma/body-type-profiles.ts.
    const profile = BODY_TYPE_PROFILES[bt.code];
    const extra = profile ? { profile: profile.profile, fields: profile.fields as unknown as Prisma.InputJsonValue } : {};
    await prisma.bodyType.upsert({
      where: { code: bt.code },
      update: { name: bt.name, sortOrder: bt.sortOrder, ...extra },
      create: { ...bt, ...extra },
    });
  }

  for (const preset of bodySizePresets) {
    const { bodyTypeCodes, ...rest } = preset;
    const matchingBodyTypes = await prisma.bodyType.findMany({ where: { code: { in: bodyTypeCodes } }, select: { id: true } });
    const bodyTypeIds = matchingBodyTypes.map((bt) => bt.id);
    await prisma.bodySizePreset.upsert({
      where: { code: preset.code },
      update: { ...rest, bodyTypeIds },
      create: { ...rest, bodyTypeIds },
    });
  }

  for (const p of permits) {
    await prisma.permit.upsert({
      where: { code: p.code },
      update: { name: p.name, sortOrder: p.sortOrder },
      create: p,
    });
  }

  for (const c of CARGO_CATEGORIES) {
    await prisma.cargoCategory.upsert({ where: { code: c.code }, update: { name: c.name, sortOrder: c.sortOrder }, create: c });
  }

  for (const t of messageTemplates) {
    await prisma.messageTemplate.upsert({
      where: { code: t.code },
      update: { category: t.category, text: t.text },
      create: t,
    });
  }

  // Снимок курса НБ РК — обновляется отдельным фидом, здесь только базовое
  // значение, чтобы пересчёт цены в ₸ работал сразу после установки.
  const exchangeRateSnapshotDate = new Date('2026-09-01');
  const exchangeRates: { currency: 'USD' | 'CNY' | 'RUB' | 'UZS'; rateToKzt: number }[] = [
    { currency: 'USD', rateToKzt: 480 },
    { currency: 'CNY', rateToKzt: 67 },
    // 058 п.4: рейсы в Россию и Узбекистан.
    { currency: 'RUB', rateToKzt: 5.9 },
    { currency: 'UZS', rateToKzt: 0.039 },
  ];
  for (const rate of exchangeRates) {
    await prisma.exchangeRate.upsert({
      where: { currency_effectiveDate: { currency: rate.currency, effectiveDate: exchangeRateSnapshotDate } },
      update: { rateToKzt: rate.rateToKzt },
      create: { currency: rate.currency, rateToKzt: rate.rateToKzt, effectiveDate: exchangeRateSnapshotDate },
    });
  }

  // Точка загрузки по умолчанию (задача 015) — город из справочника по
  // стабильному коду, не текстом "Хоргос" (решение 2026-10-04).
  const defaultPointCity = await prisma.city.findUnique({ where: { code: 'KZ-ZHETYSU-KHORGOS' } });
  if (defaultPointCity) {
    await prisma.appSetting.upsert({
      where: { key: 'defaultPointCityId' },
      update: { value: defaultPointCity.id },
      create: { key: 'defaultPointCityId', value: defaultPointCity.id },
    });
  }

  console.log('Seed завершён.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
