/// Категории груза (047 п.1) — те же, что вставляет миграция
/// 20261008170000; сид их только досоздаёт/обновляет названия.
const L = (ru: string, kk: string, zh: string, en: string) => ({ kk, ru, zh, en });

export const CARGO_CATEGORIES = [
  { code: 'CONSTRUCTION', name: L('Стройматериалы', 'Құрылыс материалдары', '建材', 'Construction materials'), sortOrder: 10 },
  { code: 'FOOD', name: L('Продукты', 'Азық-түлік', '食品', 'Food'), sortOrder: 20 },
  { code: 'EQUIPMENT', name: L('Оборудование', 'Жабдық', '设备', 'Equipment'), sortOrder: 30 },
  { code: 'CONSUMER_GOODS', name: L('ТНП / текстиль', 'ХТТ / тоқыма', '日用品/纺织品', 'Consumer goods / textiles'), sortOrder: 40 },
  { code: 'METAL', name: L('Металл', 'Металл', '金属', 'Metal'), sortOrder: 50 },
  { code: 'OVERSIZE', name: L('Негабарит', 'Габаритсіз', '超限货物', 'Oversize'), sortOrder: 60 },
  { code: 'DANGEROUS', name: L('Опасный (ADR)', 'Қауіпті (ADR)', '危险品 (ADR)', 'Dangerous (ADR)'), sortOrder: 70 },
  { code: 'OTHER', name: L('Другое', 'Басқа', '其他', 'Other'), sortOrder: 1000 },
];
