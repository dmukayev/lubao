import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

type I18n = { kk: string; ru: string; zh: string; en?: string };

const countries: {
  code: string;
  name: I18n;
  isCisMember: boolean;
  sortOrder: number;
}[] = [
  { code: 'KZ', name: { kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦' }, isCisMember: true, sortOrder: 0 },
  { code: 'CN', name: { kk: 'Қытай', ru: 'Китай', zh: '中国' }, isCisMember: false, sortOrder: 1 },
  { code: 'RU', name: { kk: 'Ресей', ru: 'Россия', zh: '俄罗斯' }, isCisMember: true, sortOrder: 2 },
  { code: 'KG', name: { kk: 'Қырғызстан', ru: 'Кыргызстан', zh: '吉尔吉斯斯坦' }, isCisMember: true, sortOrder: 3 },
  { code: 'UZ', name: { kk: 'Өзбекстан', ru: 'Узбекистан', zh: '乌兹别克斯坦' }, isCisMember: true, sortOrder: 4 },
  { code: 'TJ', name: { kk: 'Тәжікстан', ru: 'Таджикистан', zh: '塔吉克斯坦' }, isCisMember: true, sortOrder: 5 },
  { code: 'TM', name: { kk: 'Түрікменстан', ru: 'Туркменистан', zh: '土库曼斯坦' }, isCisMember: true, sortOrder: 6 },
  { code: 'AZ', name: { kk: 'Әзербайжан', ru: 'Азербайджан', zh: '阿塞拜疆' }, isCisMember: true, sortOrder: 7 },
  { code: 'AM', name: { kk: 'Армения', ru: 'Армения', zh: '亚美尼亚' }, isCisMember: true, sortOrder: 8 },
  { code: 'BY', name: { kk: 'Беларусь', ru: 'Беларусь', zh: '白俄罗斯' }, isCisMember: true, sortOrder: 9 },
  { code: 'MD', name: { kk: 'Молдова', ru: 'Молдова', zh: '摩尔多瓦' }, isCisMember: true, sortOrder: 10 },
  { code: 'UA', name: { kk: 'Украина', ru: 'Украина', zh: '乌克兰' }, isCisMember: false, sortOrder: 11 },
  { code: 'GE', name: { kk: 'Грузия', ru: 'Грузия', zh: '格鲁吉亚' }, isCisMember: false, sortOrder: 12 },
  { code: 'MN', name: { kk: 'Моңғолия', ru: 'Монголия', zh: '蒙古' }, isCisMember: false, sortOrder: 13 },
  { code: 'IR', name: { kk: 'Иран', ru: 'Иран', zh: '伊朗' }, isCisMember: false, sortOrder: 14 },
];

// Области Казахстана (17) + 3 города республиканского значения.
// Хоргос находится в области Жетісу (Панфиловский район, рядом с Жаркентом).
const kzRegions: { code: string; name: I18n; adminCenter: I18n }[] = [
  { code: 'ABAI', name: { kk: 'Абай облысы', ru: 'Абайская область', zh: '阿拜州' }, adminCenter: { kk: 'Семей', ru: 'Семей', zh: '塞梅伊' } },
  { code: 'AKMOLA', name: { kk: 'Ақмола облысы', ru: 'Акмолинская область', zh: '阿克莫拉州' }, adminCenter: { kk: 'Көкшетау', ru: 'Кокшетау', zh: '科克舍陶' } },
  { code: 'AKTOBE', name: { kk: 'Ақтөбе облысы', ru: 'Актюбинская область', zh: '阿克托别州' }, adminCenter: { kk: 'Ақтөбе', ru: 'Актобе', zh: '阿克托别' } },
  { code: 'ALMATY_REGION', name: { kk: 'Алматы облысы', ru: 'Алматинская область', zh: '阿拉木图州' }, adminCenter: { kk: 'Қонаев', ru: 'Конаев', zh: '科纳耶夫' } },
  { code: 'ATYRAU', name: { kk: 'Атырау облысы', ru: 'Атырауская область', zh: '阿特劳州' }, adminCenter: { kk: 'Атырау', ru: 'Атырау', zh: '阿特劳' } },
  { code: 'EAST_KZ', name: { kk: 'Шығыс Қазақстан облысы', ru: 'Восточно-Казахстанская область', zh: '东哈萨克斯坦州' }, adminCenter: { kk: 'Өскемен', ru: 'Усть-Каменогорск', zh: '厄斯克门' } },
  { code: 'ZHAMBYL', name: { kk: 'Жамбыл облысы', ru: 'Жамбылская область', zh: '江布尔州' }, adminCenter: { kk: 'Тараз', ru: 'Тараз', zh: '塔拉兹' } },
  { code: 'ZHETYSU', name: { kk: 'Жетісу облысы', ru: 'Область Жетысу', zh: '哲特苏州' }, adminCenter: { kk: 'Талдықорған', ru: 'Талдыкорган', zh: '塔尔迪库尔干' } },
  { code: 'WEST_KZ', name: { kk: 'Батыс Қазақстан облысы', ru: 'Западно-Казахстанская область', zh: '西哈萨克斯坦州' }, adminCenter: { kk: 'Орал', ru: 'Уральск', zh: '乌拉尔斯克' } },
  { code: 'KARAGANDY', name: { kk: 'Қарағанды облысы', ru: 'Карагандинская область', zh: '卡拉干达州' }, adminCenter: { kk: 'Қарағанды', ru: 'Караганда', zh: '卡拉干达' } },
  { code: 'KOSTANAY', name: { kk: 'Қостанай облысы', ru: 'Костанайская область', zh: '科斯塔奈州' }, adminCenter: { kk: 'Қостанай', ru: 'Костанай', zh: '科斯塔奈' } },
  { code: 'KYZYLORDA', name: { kk: 'Қызылорда облысы', ru: 'Кызылординская область', zh: '克孜勒奥尔达州' }, adminCenter: { kk: 'Қызылорда', ru: 'Кызылорда', zh: '克孜勒奥尔达' } },
  { code: 'MANGYSTAU', name: { kk: 'Маңғыстау облысы', ru: 'Мангистауская область', zh: '曼吉斯套州' }, adminCenter: { kk: 'Ақтау', ru: 'Актау', zh: '阿克套' } },
  { code: 'PAVLODAR', name: { kk: 'Павлодар облысы', ru: 'Павлодарская область', zh: '巴甫洛达尔州' }, adminCenter: { kk: 'Павлодар', ru: 'Павлодар', zh: '巴甫洛达尔' } },
  { code: 'NORTH_KZ', name: { kk: 'Солтүстік Қазақстан облысы', ru: 'Северо-Казахстанская область', zh: '北哈萨克斯坦州' }, adminCenter: { kk: 'Петропавл', ru: 'Петропавловск', zh: '彼得罗巴甫洛夫斯克' } },
  { code: 'TURKISTAN', name: { kk: 'Түркістан облысы', ru: 'Туркестанская область', zh: '突厥斯坦州' }, adminCenter: { kk: 'Түркістан', ru: 'Туркестан', zh: '突厥斯坦' } },
  { code: 'ULYTAU', name: { kk: 'Ұлытау облысы', ru: 'Улытауская область', zh: '乌雷套州' }, adminCenter: { kk: 'Жезқазған', ru: 'Жезказган', zh: '杰兹卡兹甘' } },
];

const kzRepublicanCities: { code: string; name: I18n; isCapital: boolean }[] = [
  { code: 'KZ-ASTANA', name: { kk: 'Астана', ru: 'Астана', zh: '阿斯塔纳' }, isCapital: true },
  { code: 'KZ-ALMATY', name: { kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图' }, isCapital: false },
  { code: 'KZ-SHYMKENT', name: { kk: 'Шымкент', ru: 'Шымкент', zh: '奇姆肯特' }, isCapital: false },
];

// Хоргос — приграничный город/сухой порт в Жетісуской области, рядом с Жаркентом.
const khorgosCity: I18n = { kk: 'Қорғас', ru: 'Хоргос', zh: '霍尔果斯' };
const zharkentCity: I18n = { kk: 'Жаркент', ru: 'Жаркент', zh: '扎尔肯特' };

// Дополнительные города/райцентры по областям — реальные, проверенные
// названия (не выдумываем переводы: zh оставлен пустым там, где нет
// уверенного перевода — по тексту задачи это ожидаемо и даёт фолбэк на ru).
// Это не исчерпывающий список всех ~200 райцентров РК — честная, точная
// выборка самых известных городов; остальные районные центры со временем
// появятся через «Нет моего города» → модерация админом (задача 021).
const kzDistrictCities: { code: string; regionCode: string; name: I18n }[] = [
  { code: 'KZ-ABAI-AYAGOZ', regionCode: 'ABAI', name: { kk: 'Аягөз', ru: 'Аягоз', zh: '' } },
  { code: 'KZ-ABAI-KURCHATOV', regionCode: 'ABAI', name: { kk: 'Курчатов', ru: 'Курчатов', zh: '' } },
  { code: 'KZ-AKMOLA-STEPNOGORSK', regionCode: 'AKMOLA', name: { kk: 'Степногорск', ru: 'Степногорск', zh: '' } },
  { code: 'KZ-AKMOLA-SHCHUCHINSK', regionCode: 'AKMOLA', name: { kk: 'Щучинск', ru: 'Щучинск', zh: '' } },
  { code: 'KZ-AKMOLA-ATBASAR', regionCode: 'AKMOLA', name: { kk: 'Атбасар', ru: 'Атбасар', zh: '' } },
  { code: 'KZ-AKTOBE-KHROMTAU', regionCode: 'AKTOBE', name: { kk: 'Хромтау', ru: 'Хромтау', zh: '' } },
  { code: 'KZ-AKTOBE-SHALKAR', regionCode: 'AKTOBE', name: { kk: 'Шалқар', ru: 'Шалкар', zh: '' } },
  { code: 'KZ-ALMATY_REGION-TALGAR', regionCode: 'ALMATY_REGION', name: { kk: 'Талғар', ru: 'Талгар', zh: '' } },
  { code: 'KZ-ALMATY_REGION-KASKELEN', regionCode: 'ALMATY_REGION', name: { kk: 'Қаскелең', ru: 'Каскелен', zh: '' } },
  { code: 'KZ-ALMATY_REGION-ESIK', regionCode: 'ALMATY_REGION', name: { kk: 'Есік', ru: 'Есик', zh: '' } },
  { code: 'KZ-ATYRAU-KULSARY', regionCode: 'ATYRAU', name: { kk: 'Құлсары', ru: 'Кульсары', zh: '' } },
  { code: 'KZ-EAST_KZ-RIDDER', regionCode: 'EAST_KZ', name: { kk: 'Риддер', ru: 'Риддер', zh: '' } },
  { code: 'KZ-EAST_KZ-ZYRYANOVSK', regionCode: 'EAST_KZ', name: { kk: 'Зыряновск', ru: 'Зыряновск', zh: '' } },
  { code: 'KZ-ZHAMBYL-SHU', regionCode: 'ZHAMBYL', name: { kk: 'Шу', ru: 'Шу', zh: '' } },
  { code: 'KZ-ZHAMBYL-KARATAU', regionCode: 'ZHAMBYL', name: { kk: 'Қаратау', ru: 'Каратау', zh: '' } },
  { code: 'KZ-ZHAMBYL-ZHANATAS', regionCode: 'ZHAMBYL', name: { kk: 'Жаңатас', ru: 'Жанатас', zh: '' } },
  { code: 'KZ-ZHETYSU-USHARAL', regionCode: 'ZHETYSU', name: { kk: 'Үшарал', ru: 'Ушарал', zh: '' } },
  { code: 'KZ-ZHETYSU-SARKAND', regionCode: 'ZHETYSU', name: { kk: 'Сарқанд', ru: 'Сарканд', zh: '' } },
  { code: 'KZ-WEST_KZ-AKSAI', regionCode: 'WEST_KZ', name: { kk: 'Ақсай', ru: 'Аксай', zh: '' } },
  { code: 'KZ-KARAGANDY-TEMIRTAU', regionCode: 'KARAGANDY', name: { kk: 'Теміртау', ru: 'Темиртау', zh: '' } },
  { code: 'KZ-KARAGANDY-BALKHASH', regionCode: 'KARAGANDY', name: { kk: 'Балқаш', ru: 'Балхаш', zh: '' } },
  { code: 'KZ-KARAGANDY-SARAN', regionCode: 'KARAGANDY', name: { kk: 'Сарань', ru: 'Сарань', zh: '' } },
  { code: 'KZ-KOSTANAY-RUDNY', regionCode: 'KOSTANAY', name: { kk: 'Рудный', ru: 'Рудный', zh: '' } },
  { code: 'KZ-KOSTANAY-LISAKOVSK', regionCode: 'KOSTANAY', name: { kk: 'Лисаковск', ru: 'Лисаковск', zh: '' } },
  { code: 'KZ-KYZYLORDA-BAIKONUR', regionCode: 'KYZYLORDA', name: { kk: 'Байқоңыр', ru: 'Байконур', zh: '' } },
  { code: 'KZ-KYZYLORDA-ARALSK', regionCode: 'KYZYLORDA', name: { kk: 'Арал', ru: 'Аральск', zh: '' } },
  { code: 'KZ-MANGYSTAU-ZHANAOZEN', regionCode: 'MANGYSTAU', name: { kk: 'Жаңаөзен', ru: 'Жанаозен', zh: '' } },
  { code: 'KZ-PAVLODAR-EKIBASTUZ', regionCode: 'PAVLODAR', name: { kk: 'Екібастұз', ru: 'Экибастуз', zh: '' } },
  { code: 'KZ-PAVLODAR-AKSU', regionCode: 'PAVLODAR', name: { kk: 'Ақсу', ru: 'Аксу', zh: '' } },
  { code: 'KZ-NORTH_KZ-TAIYNSHA', regionCode: 'NORTH_KZ', name: { kk: 'Тайынша', ru: 'Тайынша', zh: '' } },
  { code: 'KZ-TURKISTAN-SARYAGASH', regionCode: 'TURKISTAN', name: { kk: 'Сарыағаш', ru: 'Сарыагаш', zh: '' } },
  { code: 'KZ-TURKISTAN-ZHETYSAY', regionCode: 'TURKISTAN', name: { kk: 'Жетісай', ru: 'Жетысай', zh: '' } },
  { code: 'KZ-TURKISTAN-ARYS', regionCode: 'TURKISTAN', name: { kk: 'Арыс', ru: 'Арыс', zh: '' } },
  { code: 'KZ-TURKISTAN-KENTAU', regionCode: 'TURKISTAN', name: { kk: 'Кентау', ru: 'Кентау', zh: '' } },
  { code: 'KZ-ULYTAU-SATBAYEV', regionCode: 'ULYTAU', name: { kk: 'Сәтбаев', ru: 'Сатпаев', zh: '' } },
];

// Крупные города/столицы соседних стран — для выбора «домашний город» водителя.
// Расширено по маршрутам из Хоргоса (задача 021): Синьцзян (CN), Узбекистан,
// Киргизия, Таджикистан, Туркменистан, юг России.
const foreignCities: Record<string, { code: string; name: I18n; isCapital: boolean }[]> = {
  CN: [
    { code: 'CN-BEIJING', name: { kk: 'Пекин', ru: 'Пекин', zh: '北京' }, isCapital: true },
    { code: 'CN-URUMQI', name: { kk: 'Үрімші', ru: 'Урумчи', zh: '乌鲁木齐' }, isCapital: false },
    { code: 'CN-KASHGAR', name: { kk: 'Қашқар', ru: 'Кашгар', zh: '喀什' }, isCapital: false },
    { code: 'CN-YINING', name: { kk: 'Құлжа', ru: 'Инин (Кульджа)', zh: '伊宁' }, isCapital: false },
    { code: 'CN-KORLA', name: { kk: 'Корла', ru: 'Корла', zh: '库尔勒' }, isCapital: false },
  ],
  RU: [
    { code: 'RU-MOSCOW', name: { kk: 'Мәскеу', ru: 'Москва', zh: '莫斯科' }, isCapital: true },
    { code: 'RU-NOVOSIBIRSK', name: { kk: 'Новосібір', ru: 'Новосибирск', zh: '新西伯利亚' }, isCapital: false },
    { code: 'RU-OMSK', name: { kk: 'Омбы', ru: 'Омск', zh: '' }, isCapital: false },
  ],
  KG: [
    { code: 'KG-BISHKEK', name: { kk: 'Бішкек', ru: 'Бишкек', zh: '比什凯克' }, isCapital: true },
    { code: 'KG-OSH', name: { kk: 'Ош', ru: 'Ош', zh: '' }, isCapital: false },
  ],
  UZ: [
    { code: 'UZ-TASHKENT', name: { kk: 'Ташкент', ru: 'Ташкент', zh: '塔什干' }, isCapital: true },
    { code: 'UZ-SAMARKAND', name: { kk: 'Самарқанд', ru: 'Самарканд', zh: '撒马尔罕' }, isCapital: false },
  ],
  TJ: [{ code: 'TJ-DUSHANBE', name: { kk: 'Душанбе', ru: 'Душанбе', zh: '杜尚别' }, isCapital: true }],
  TM: [{ code: 'TM-ASHGABAT', name: { kk: 'Ашғабат', ru: 'Ашхабад', zh: '阿什哈巴德' }, isCapital: true }],
  AZ: [{ code: 'AZ-BAKU', name: { kk: 'Баку', ru: 'Баку', zh: '巴库' }, isCapital: true }],
  AM: [{ code: 'AM-YEREVAN', name: { kk: 'Ереван', ru: 'Ереван', zh: '埃里温' }, isCapital: true }],
  BY: [{ code: 'BY-MINSK', name: { kk: 'Минск', ru: 'Минск', zh: '明斯克' }, isCapital: true }],
  MD: [{ code: 'MD-CHISINAU', name: { kk: 'Кишинев', ru: 'Кишинёв', zh: '基希讷乌' }, isCapital: true }],
  UA: [{ code: 'UA-KYIV', name: { kk: 'Киев', ru: 'Киев', zh: '基辅' }, isCapital: true }],
  GE: [{ code: 'GE-TBILISI', name: { kk: 'Тбилиси', ru: 'Тбилиси', zh: '第比利斯' }, isCapital: true }],
  MN: [{ code: 'MN-ULAANBAATAR', name: { kk: 'Ұланбатыр', ru: 'Улан-Батор', zh: '乌兰巴托' }, isCapital: true }],
  IR: [{ code: 'IR-TEHRAN', name: { kk: 'Тегеран', ru: 'Тегеран', zh: '德黑兰' }, isCapital: true }],
};

const bodyTypes: { code: string; name: I18n; sortOrder: number }[] = [
  { code: 'TENT', name: { kk: 'Тентті', ru: 'Тентованный', zh: '帆布篷车' }, sortOrder: 0 },
  { code: 'REFRIGERATOR', name: { kk: 'Рефрижератор', ru: 'Рефрижератор', zh: '冷藏车' }, sortOrder: 1 },
  { code: 'ISOTHERM', name: { kk: 'Изотермиялық', ru: 'Изотермический', zh: '保温车' }, sortOrder: 2 },
  { code: 'FLATBED', name: { kk: 'Бортты', ru: 'Бортовой', zh: '平板车' }, sortOrder: 3 },
  { code: 'CONTAINER', name: { kk: 'Контейнеровоз', ru: 'Контейнеровоз', zh: '集装箱车' }, sortOrder: 4 },
  { code: 'DUMP', name: { kk: 'Самосвал', ru: 'Самосвал', zh: '自卸车' }, sortOrder: 5 },
  { code: 'LOWLOADER', name: { kk: 'Аласа рамалы трал', ru: 'Низкорамный трал', zh: '低平板拖车' }, sortOrder: 6 },
  { code: 'CARCARRIER', name: { kk: 'Автотасығыш', ru: 'Автовоз', zh: '汽车运输车' }, sortOrder: 7 },
  { code: 'GRAIN', name: { kk: 'Астық тасығыш', ru: 'Зерновоз', zh: '谷物运输车' }, sortOrder: 8 },
  { code: 'TANK', name: { kk: 'Цистерна', ru: 'Цистерна', zh: '罐车' }, sortOrder: 9 },
];

const permits: { code: string; name: I18n; sortOrder: number }[] = [
  { code: 'TIR', name: { kk: 'TIR кітапшасы', ru: 'Книжка МДП (TIR)', zh: 'TIR单证' }, sortOrder: 0 },
  { code: 'CMR', name: { kk: 'CMR жүкқұжаты', ru: 'CMR-накладная', zh: 'CMR运单' }, sortOrder: 1 },
  { code: 'ADR', name: { kk: 'ADR рұқсаты (қауіпті жүктер)', ru: 'Допуск ADR (опасные грузы)', zh: 'ADR危险品准运证' }, sortOrder: 2 },
  { code: 'OVERSIZE', name: { kk: 'Негабарит жүкке рұқсат', ru: 'Допуск на негабаритный груз', zh: '超限运输许可' }, sortOrder: 3 },
  { code: 'SANITARY', name: { kk: 'Санитарлық паспорт', ru: 'Санитарный паспорт', zh: '卫生护照' }, sortOrder: 4 },
];

const messageTemplates: { code: string; category: string; text: I18n }[] = [
  {
    code: 'CONTACT_FOLLOWUP',
    category: 'contact_reminder',
    text: { kk: 'Келістіңіздер ме?', ru: 'Договорились?', zh: '谈好了吗?' },
  },
  {
    code: 'CARGO_ARCHIVED',
    category: 'cargo_lifecycle',
    text: { kk: 'Жүк мұрағатталды', ru: 'Груз архивирован', zh: '货物已归档' },
  },
];

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

  for (const bt of bodyTypes) {
    await prisma.bodyType.upsert({
      where: { code: bt.code },
      update: { name: bt.name, sortOrder: bt.sortOrder },
      create: bt,
    });
  }

  for (const p of permits) {
    await prisma.permit.upsert({
      where: { code: p.code },
      update: { name: p.name, sortOrder: p.sortOrder },
      create: p,
    });
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
  const exchangeRates: { currency: 'USD' | 'CNY'; rateToKzt: number }[] = [
    { currency: 'USD', rateToKzt: 480 },
    { currency: 'CNY', rateToKzt: 67 },
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
