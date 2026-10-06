import { completeArrivalForConfirmedDeal, leaveTerminalIfOutside } from './arrival-lifecycle';

function makeDb() {
  return {
    arrival: {
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      findFirst: jest.fn().mockResolvedValue(null),
      update: jest.fn().mockResolvedValue({}),
    },
  } as any;
}

describe('completeArrivalForConfirmedDeal — подтвердил сделку → анонс гаснет (040, п.4)', () => {
  it('гасит анонс «на месте»', async () => {
    const db = makeDb();
    db.arrival.updateMany.mockResolvedValue({ count: 1 });
    await completeArrivalForConfirmedDeal(db, 'd1');
    expect(db.arrival.updateMany).toHaveBeenCalledWith({ where: { driverId: 'd1', status: 'ON_SITE' }, data: { status: 'COMPLETED' } });
    expect(db.arrival.findFirst).not.toHaveBeenCalled();
  });

  it('нет «на месте» — гасит ближайший запланированный на сегодня или раньше, будущие не трогает', async () => {
    const db = makeDb();
    db.arrival.findFirst.mockResolvedValue({ id: 'planned-today' });
    await completeArrivalForConfirmedDeal(db, 'd1', new Date('2026-10-08T07:00:00.000Z'));
    expect(db.arrival.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { driverId: 'd1', status: 'PLANNED', plannedDay: { lte: new Date('2026-10-08T00:00:00.000Z') } } }),
    );
    expect(db.arrival.update).toHaveBeenCalledWith({ where: { id: 'planned-today' }, data: { status: 'COMPLETED' } });
  });

  it('анонсов нет — ничего не делает', async () => {
    const db = makeDb();
    await completeArrivalForConfirmedDeal(db, 'd1');
    expect(db.arrival.update).not.toHaveBeenCalled();
  });
});

describe('leaveTerminalIfOutside — геозона терминала (Хоргос)', () => {
  const terminal = { id: 'a1', point: { lat: 44.2167, lng: 80.4167, radiusM: 3000 } };

  it('внутри радиуса остаётся на месте', async () => {
    const db = makeDb();
    db.arrival.findFirst.mockResolvedValue(terminal);
    expect(await leaveTerminalIfOutside(db, 'd1', { lat: 44.22, lng: 80.42 })).toBe(false);
    expect(db.arrival.update).not.toHaveBeenCalled();
  });

  it('вышел за радиус — анонс завершается («уехал»)', async () => {
    const db = makeDb();
    db.arrival.findFirst.mockResolvedValue(terminal);
    expect(await leaveTerminalIfOutside(db, 'd1', { lat: 43.2389, lng: 76.8897 })).toBe(true);
    expect(db.arrival.update).toHaveBeenCalledWith({ where: { id: 'a1' }, data: { status: 'COMPLETED' } });
  });

  it('у города без геозоны (kind=CITY) запрос ищет только терминалы — по координатам не гасит', async () => {
    const db = makeDb();
    expect(await leaveTerminalIfOutside(db, 'd1', { lat: 0, lng: 0 })).toBe(false);
    expect(db.arrival.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ point: expect.objectContaining({ kind: 'TERMINAL' }) }) }),
    );
  });
});
