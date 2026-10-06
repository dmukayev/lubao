import { nbkRatesUrl, parseNbkRates } from './nbk-rates';

const SAMPLE = `<?xml version="1.0" encoding="utf-8"?>
<rates>
<generator>nationalbank.kz</generator>
<date>07.10.2026</date>
<item><fullname>ДОЛЛАР США</fullname><title>USD</title><description>478.34</description><quant>1</quant><index>UP</index><change>0.51</change></item>
<item><fullname>ЕВРО</fullname><title>EUR</title><description>560.1</description><quant>1</quant></item>
<item><fullname>КИТАЙСКИЙ ЮАНЬ</fullname><title>CNY</title><description>670.5</description><quant>10</quant></item>
<item><fullname>РУБЛЬ</fullname><title>RUB</title><description>5.9</description><quant>1</quant></item>
</rates>`;

describe('курс НБ РК (задача 042, п.4)', () => {
  it('берёт только USD и CNY и приводит курс к одной единице (quant)', () => {
    expect(parseNbkRates(SAMPLE)).toEqual([
      { currency: 'USD', rateToKzt: 478.34 },
      { currency: 'CNY', rateToKzt: 67.05 },
    ]);
  });

  it('мусор и пустой ответ — пустой список, а не исключение', () => {
    expect(parseNbkRates('')).toEqual([]);
    expect(parseNbkRates('<html>Service unavailable</html>')).toEqual([]);
    expect(parseNbkRates('<item><title>USD</title><description>abc</description></item>')).toEqual([]);
  });

  it('запятая как десятичный разделитель', () => {
    expect(parseNbkRates('<item><title>USD</title><description>478,5</description><quant>1</quant></item>')).toEqual([{ currency: 'USD', rateToKzt: 478.5 }]);
  });

  it('URL с датой ДД.ММ.ГГГГ', () => {
    expect(nbkRatesUrl(new Date('2026-10-07T00:00:00.000Z'), 'https://nb.example/rates')).toBe('https://nb.example/rates?fdate=07.10.2026');
  });
});
