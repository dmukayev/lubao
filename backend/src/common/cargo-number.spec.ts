import { formatCargoNumber, formatDealNumber, parseCargoNumberQuery } from './cargo-number';
import { withDealNumber } from '../notifications/notification-events';

describe('062: номер груза и сделки', () => {
  it('группы по 3: «482 915», сделка «482 915-1»', () => {
    expect(formatCargoNumber(482915)).toBe('482 915');
    expect(formatCargoNumber(1482915)).toBe('1 482 915');
    expect(formatDealNumber(482915, 2)).toBe('482 915-2');
  });

  it('поиск понимает номер с пробелами, «№», машину; не номер — null', () => {
    expect(parseCargoNumberQuery('482 915')).toEqual({ number: 482915, seq: null });
    expect(parseCargoNumberQuery('№ 482 915-1')).toEqual({ number: 482915, seq: 1 });
    expect(parseCargoNumberQuery('482915-12')).toEqual({ number: 482915, seq: 12 });
    expect(parseCargoNumberQuery('No. 482915')).toEqual({ number: 482915, seq: null });
    expect(parseCargoNumberQuery('4829')).toBeNull();
    expect(parseCargoNumberQuery('3f2a9c1e')).toBeNull();
    expect(parseCargoNumberQuery('+7 701 000 00 05')).toBeNull();
  });

  it('push о сделке — номер в заголовке на языке получателя', () => {
    const r = { title: 'Загрузился', body: 'x' };
    expect(withDealNumber(r, { dealNumber: '482 915-1' }, 'ru').title).toBe('Загрузился · № 482 915-1');
    expect(withDealNumber(r, { dealNumber: '482 915-1' }, 'zh').title).toBe('Загрузился · 编号 482 915-1');
    expect(withDealNumber(r, {}, 'en')).toBe(r);
  });
});
