import { FreshnessArrival, decideFreshness } from './arrival-freshness';

const H = 60 * 60 * 1000;
const day = (s: string) => new Date(`${s}T00:00:00.000Z`);

function arrival(over: Partial<FreshnessArrival>): FreshnessArrival {
  return {
    status: 'PLANNED',
    plannedDay: day('2026-10-08'),
    arrivedAt: null,
    lastConfirmedAt: null,
    dayAskedAt: null,
    staleAskedAt: null,
    waitDays: 3,
    ...over,
  };
}

describe('decideFreshness — правило свежести анонса (задача 040, п.4)', () => {
  describe('1. запланированный: молчим до дня приезда', () => {
    it('за день до приезда — тишина', () => {
      expect(decideFreshness(arrival({}), new Date('2026-10-07T10:00:00.000Z'))).toBe('NONE');
    });

    it('в день приезда рано утром (до 08:00 по Алматы) — ещё тишина', () => {
      // 02:00 UTC = 07:00 по Алматы (UTC+5)
      expect(decideFreshness(arrival({}), new Date('2026-10-08T02:00:00.000Z'))).toBe('NONE');
    });
  });

  describe('2. день приезда: одно напоминание, к концу дня — гаснет', () => {
    it('в день приезда днём — «Доехали?»', () => {
      expect(decideFreshness(arrival({}), new Date('2026-10-08T07:00:00.000Z'))).toBe('ASK_DAY');
    });

    it('напоминание уже было — повторно не спрашиваем', () => {
      expect(decideFreshness(arrival({ dayAskedAt: new Date('2026-10-08T03:10:00.000Z') }), new Date('2026-10-08T12:00:00.000Z'))).toBe('NONE');
    });

    it('день по Алматы закончился, «на месте» не нажато — гаснет', () => {
      // 19:30 UTC 8 октября = 00:30 9 октября по Алматы
      expect(decideFreshness(arrival({ dayAskedAt: new Date('2026-10-08T03:10:00.000Z') }), new Date('2026-10-08T19:30:00.000Z'))).toBe('EXPIRE');
    });

    it('а за минуту до полуночи по Алматы ещё жив', () => {
      expect(decideFreshness(arrival({ dayAskedAt: new Date('2026-10-08T03:10:00.000Z') }), new Date('2026-10-08T18:59:00.000Z'))).toBe('NONE');
    });
  });

  describe('2а. анонс «на сегодня» после 22:00 (042 п.0)', () => {
    // 2026-10-08 23:30 по Алматы (UTC+5) = 18:30 UTC.
    const late = new Date('2026-10-08T18:30:00.000Z');
    it('в полночь не гаснет', () => {
      expect(decideFreshness(arrival({ createdAt: late }), new Date('2026-10-08T19:05:00.000Z'))).toBe('NONE');
    });
    it('на следующий день с 08:00 — «Доехали?»', () => {
      expect(decideFreshness(arrival({ createdAt: late }), new Date('2026-10-09T04:00:00.000Z'))).toBe('ASK_DAY');
    });
    it('к концу следующего дня — гаснет', () => {
      expect(decideFreshness(arrival({ createdAt: late, dayAskedAt: new Date('2026-10-09T04:00:00.000Z') }), new Date('2026-10-09T19:05:00.000Z'))).toBe('EXPIRE');
    });
    it('поданный днём — правило прежнее: гаснет в полночь', () => {
      expect(decideFreshness(arrival({ createdAt: new Date('2026-10-08T06:00:00.000Z') }), new Date('2026-10-08T19:05:00.000Z'))).toBe('EXPIRE');
    });
  });

  describe('3. «на месте»: «Ещё ищете груз?» каждые 12 ч, без ответа — гаснет', () => {
    const arrivedAt = new Date('2026-10-08T05:00:00.000Z');
    const onSite = (over: Partial<FreshnessArrival> = {}) => arrival({ status: 'ON_SITE', arrivedAt, lastConfirmedAt: arrivedAt, ...over });

    it('до 12 ч после «Я на месте» — тишина', () => {
      expect(decideFreshness(onSite(), new Date(arrivedAt.getTime() + 11 * H))).toBe('NONE');
    });

    it('через 12 ч — «Ещё ищете груз?»', () => {
      expect(decideFreshness(onSite(), new Date(arrivedAt.getTime() + 12 * H))).toBe('ASK_STILL_LOOKING');
    });

    it('спросили, ответа нет, прошло меньше 12 ч — ждём', () => {
      const asked = new Date(arrivedAt.getTime() + 12 * H);
      expect(decideFreshness(onSite({ staleAskedAt: asked }), new Date(asked.getTime() + 11 * H))).toBe('NONE');
    });

    it('спросили, 12 ч без ответа — гаснет', () => {
      const asked = new Date(arrivedAt.getTime() + 12 * H);
      expect(decideFreshness(onSite({ staleAskedAt: asked }), new Date(asked.getTime() + 12 * H))).toBe('EXPIRE');
    });

    it('ответил «Да» — отсчёт 12 ч идёт заново и старое напоминание не гасит анонс', () => {
      const asked = new Date(arrivedAt.getTime() + 12 * H);
      const answered = new Date(asked.getTime() + 2 * H);
      const a = onSite({ staleAskedAt: asked, lastConfirmedAt: answered });
      expect(decideFreshness(a, new Date(answered.getTime() + 10 * H))).toBe('NONE');
      expect(decideFreshness(a, new Date(answered.getTime() + 12 * H))).toBe('ASK_STILL_LOOKING');
    });

    it('срок ожидания, который задал водитель (waitDays), — предел при любых ответах', () => {
      const a = onSite({ waitDays: 1, lastConfirmedAt: new Date(arrivedAt.getTime() + 20 * H) });
      expect(decideFreshness(a, new Date(arrivedAt.getTime() + 24 * H))).toBe('EXPIRE');
    });
  });

  it('завершённые анонсы правило не трогает', () => {
    expect(decideFreshness(arrival({ status: 'COMPLETED' }), new Date('2030-01-01T00:00:00.000Z'))).toBe('NONE');
    expect(decideFreshness(arrival({ status: 'EXPIRED' }), new Date('2030-01-01T00:00:00.000Z'))).toBe('NONE');
  });
});
