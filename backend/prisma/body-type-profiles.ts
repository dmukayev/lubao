/// Профили типов кузова и их поля (048, decisions.md 2026-10-08 «У каждого
/// кузова свои параметры»). Источник для сида и для первичного заполнения в
/// миграции; дальше админ правит `body_types.fields` без релиза.

export type BodyTypeProfileCode = 'VOLUME' | 'PLATFORM' | 'CONTAINER' | 'BULK' | 'TANK' | 'CAR_CARRIER';

type I18n = { kk: string; ru: string; zh: string; en: string };

export interface BodyField {
  key: string;
  kind: 'number' | 'enum' | 'multi' | 'bool';
  /// Код единицы — переводится в приложении (t, m3, pallets, m, l, c, cars, slots, sections).
  unit?: string;
  label: I18n;
  forVehicle: boolean;
  forCargo: boolean;
  required?: boolean;
  /// «Основа» типа — спрашивается при регистрации водителя (048 п.7).
  primary?: boolean;
  min?: number;
  max?: number;
  options?: Array<{ code: string; label: I18n }>;
}

const L = (ru: string, kk: string, zh: string, en: string): I18n => ({ kk, ru, zh, en });

const capacity: BodyField = { key: 'capacityTons', kind: 'number', unit: 't', label: L('Грузоподъёмность', 'Жүккөтергіштігі', '载重', 'Payload'), forVehicle: true, forCargo: false, required: true, primary: true, min: 0.5, max: 80 };
const volume: BodyField = { key: 'volumeM3', kind: 'number', unit: 'm3', label: L('Объём кузова', 'Шанақ көлемі', '车厢容积', 'Body volume'), forVehicle: true, forCargo: false, min: 1, max: 200 };
const pallets: BodyField = { key: 'palletsEuro', kind: 'number', unit: 'pallets', label: L('Европаллеты', 'Еуропаллеттер', '欧标托盘', 'Euro pallets'), forVehicle: true, forCargo: false, min: 1, max: 60 };
const dims: BodyField[] = [
  { key: 'innerLengthM', kind: 'number', unit: 'm', label: L('Длина кузова', 'Шанақ ұзындығы', '车厢长度', 'Body length'), forVehicle: true, forCargo: false, min: 1, max: 20 },
  { key: 'innerWidthM', kind: 'number', unit: 'm', label: L('Ширина кузова', 'Шанақ ені', '车厢宽度', 'Body width'), forVehicle: true, forCargo: false, min: 1, max: 4 },
  { key: 'innerHeightM', kind: 'number', unit: 'm', label: L('Высота кузова', 'Шанақ биіктігі', '车厢高度', 'Body height'), forVehicle: true, forCargo: false, min: 1, max: 4.5 },
];
const cargoDims: BodyField[] = [
  { key: 'cargoLengthM', kind: 'number', unit: 'm', label: L('Длина груза', 'Жүк ұзындығы', '货物长度', 'Cargo length'), forVehicle: false, forCargo: true, min: 0.1, max: 40 },
  { key: 'cargoWidthM', kind: 'number', unit: 'm', label: L('Ширина груза', 'Жүк ені', '货物宽度', 'Cargo width'), forVehicle: false, forCargo: true, min: 0.1, max: 10 },
  { key: 'cargoHeightM', kind: 'number', unit: 'm', label: L('Высота груза', 'Жүк биіктігі', '货物高度', 'Cargo height'), forVehicle: false, forCargo: true, min: 0.1, max: 10 },
  { key: 'oversize', kind: 'bool', label: L('Негабарит', 'Габаритсіз', '超限', 'Oversize'), forVehicle: false, forCargo: true },
];
const products = [
  { code: 'FUEL', label: L('Топливо', 'Жанармай', '燃油', 'Fuel') },
  { code: 'FOOD', label: L('Пищевое', 'Азық-түлік', '食品级', 'Food grade') },
  { code: 'CHEMICAL', label: L('Химия', 'Химия', '化学品', 'Chemicals') },
  { code: 'GAS', label: L('Газ', 'Газ', '气体', 'Gas') },
];
const containerTypes = [
  { code: '20', label: L("20'", "20'", "20'", "20'") },
  { code: '40', label: L("40'", "40'", "40'", "40'") },
  { code: '45', label: L("45'", "45'", "45'", "45'") },
];

const VOLUME: BodyField[] = [capacity, volume, pallets, ...dims];
const REEFER: BodyField[] = [
  ...VOLUME,
  { key: 'tempMin', kind: 'number', unit: 'c', label: L('Температура от', 'Температура бастап', '最低温度', 'Temperature from'), forVehicle: true, forCargo: false, primary: true, min: -30, max: 25 },
  { key: 'tempMax', kind: 'number', unit: 'c', label: L('Температура до', 'Температура дейін', '最高温度', 'Temperature to'), forVehicle: true, forCargo: false, min: -30, max: 25 },
  { key: 'tempRequired', kind: 'number', unit: 'c', label: L('Нужная температура', 'Қажетті температура', '所需温度', 'Required temperature'), forVehicle: false, forCargo: true, min: -30, max: 25 },
];
const PLATFORM: BodyField[] = [
  capacity,
  { key: 'platformLengthM', kind: 'number', unit: 'm', label: L('Длина платформы', 'Платформа ұзындығы', '平台长度', 'Platform length'), forVehicle: true, forCargo: false, min: 3, max: 25 },
  ...cargoDims,
];
const LOWLOADER: BodyField[] = [
  ...PLATFORM.slice(0, 2),
  { key: 'deckHeightM', kind: 'number', unit: 'm', label: L('Высота площадки', 'Алаң биіктігі', '平台高度', 'Deck height'), forVehicle: true, forCargo: false, min: 0.2, max: 2 },
  { key: 'oversizeAllowed', kind: 'bool', label: L('Допуск на негабарит', 'Габаритсізге рұқсат', '可运超限', 'Oversize permit'), forVehicle: true, forCargo: false },
  ...cargoDims,
];
const CONTAINER: BodyField[] = [
  { key: 'containerTypes', kind: 'multi', label: L('Контейнеры', 'Контейнерлер', '集装箱类型', 'Containers'), forVehicle: true, forCargo: false, required: true, primary: true, options: containerTypes },
  { key: 'slots', kind: 'number', unit: 'slots', label: L('Мест под контейнеры', 'Контейнер орындары', '箱位数', 'Container slots'), forVehicle: true, forCargo: false, min: 1, max: 4 },
  { key: 'containerType', kind: 'enum', label: L('Тип контейнера', 'Контейнер түрі', '集装箱类型', 'Container type'), forVehicle: false, forCargo: true, required: true, options: containerTypes },
  { key: 'containerCount', kind: 'number', unit: 'slots', label: L('Количество', 'Саны', '数量', 'Count'), forVehicle: false, forCargo: true, min: 1, max: 4 },
];
const BULK: BodyField[] = [
  capacity,
  { key: 'bodyVolumeM3', kind: 'number', unit: 'm3', label: L('Объём кузова', 'Шанақ көлемі', '车厢容积', 'Body volume'), forVehicle: true, forCargo: false, min: 1, max: 150 },
];
const TANK: BodyField[] = [
  { key: 'liters', kind: 'number', unit: 'l', label: L('Объём цистерны', 'Цистерна көлемі', '罐容', 'Tank volume'), forVehicle: true, forCargo: false, required: true, primary: true, min: 1000, max: 60000 },
  { key: 'product', kind: 'enum', label: L('Продукт', 'Өнім', '介质', 'Product'), forVehicle: true, forCargo: false, required: true, primary: true, options: products },
  { key: 'sections', kind: 'number', unit: 'sections', label: L('Секции', 'Секциялар', '仓数', 'Compartments'), forVehicle: true, forCargo: false, min: 1, max: 8 },
  { key: 'cargoProduct', kind: 'enum', label: L('Продукт', 'Өнім', '介质', 'Product'), forVehicle: false, forCargo: true, required: true, options: products },
  { key: 'cargoLiters', kind: 'number', unit: 'l', label: L('Литров', 'Литр', '升', 'Liters'), forVehicle: false, forCargo: true, required: true, min: 100, max: 60000 },
];
const CAR_CARRIER: BodyField[] = [
  { key: 'carSlots', kind: 'number', unit: 'cars', label: L('Мест под машины', 'Көлік орындары', '车位数', 'Car slots'), forVehicle: true, forCargo: false, required: true, primary: true, min: 1, max: 12 },
  { key: 'closed', kind: 'bool', label: L('Закрытый', 'Жабық', '封闭式', 'Enclosed'), forVehicle: true, forCargo: false },
  { key: 'carCount', kind: 'number', unit: 'cars', label: L('Машин', 'Көлік', '车辆数', 'Cars'), forVehicle: false, forCargo: true, required: true, min: 1, max: 12 },
  {
    key: 'carType', kind: 'enum', label: L('Тип авто', 'Көлік түрі', '车型', 'Car type'), forVehicle: false, forCargo: true,
    options: [
      { code: 'PASSENGER', label: L('Легковые', 'Жеңіл', '轿车', 'Passenger cars') },
      { code: 'SUV', label: L('Внедорожники', 'Жол талғамайтын', 'SUV', 'SUVs') },
      { code: 'MINIBUS', label: L('Микроавтобусы', 'Шағын автобустар', '小型客车', 'Minibuses') },
    ],
  },
];

export const BODY_TYPE_PROFILES: Record<string, { profile: BodyTypeProfileCode; fields: BodyField[] }> = {
  TENT: { profile: 'VOLUME', fields: VOLUME },
  ISOTHERM: { profile: 'VOLUME', fields: VOLUME },
  REFRIGERATOR: { profile: 'VOLUME', fields: REEFER },
  FLATBED: { profile: 'PLATFORM', fields: PLATFORM },
  LOWLOADER: { profile: 'PLATFORM', fields: LOWLOADER },
  CONTAINER: { profile: 'CONTAINER', fields: CONTAINER },
  DUMP: { profile: 'BULK', fields: BULK },
  GRAIN: { profile: 'BULK', fields: BULK },
  TANK: { profile: 'TANK', fields: TANK },
  CARCARRIER: { profile: 'CAR_CARRIER', fields: CAR_CARRIER },
};
