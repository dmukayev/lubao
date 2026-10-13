import { hasCjk, isValidLatinName, suggestLatinName } from './latin-name';

/// 069: латинское название китайской компании.
describe('latin-name', () => {
  it('иероглифы — нужно латинское название; кириллица и латиница — нет', () => {
    expect(hasCjk('霍尔果斯瑞达贸易有限公司')).toBe(true);
    expect(hasCjk('ТОО Транс')).toBe(false);
    expect(hasCjk('Horgos Trade')).toBe(false);
  });

  it('подсказка: известные части — словом, остальное — пиньинь слитно', () => {
    expect(suggestLatinName('霍尔果斯瑞达贸易有限公司')).toBe('Horgos Ruida Trading Co., Ltd.');
    expect(suggestLatinName('乌鲁木齐天山物流有限公司')).toBe('Urumqi Tianshan Logistics Co., Ltd.');
    expect(suggestLatinName('ABC国际货运')).toBe('ABC International Freight');
    expect(isValidLatinName(suggestLatinName('新疆123运输公司'))).toBe(true);
  });

  it('разрешены латиница, цифры, пробел и . , & - ( ) \', длина 2–100', () => {
    expect(isValidLatinName("Horgos Ruida Trading Co., Ltd. (KZ) & Sons-1 O'Neil")).toBe(true);
    expect(isValidLatinName('A')).toBe(false);
    expect(isValidLatinName('Хоргос')).toBe(false);
    expect(isValidLatinName('霍尔果斯')).toBe(false);
    expect(isValidLatinName('x'.repeat(101))).toBe(false);
  });
});
