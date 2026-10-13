import { evaluateVehicleLoad } from './vehicle-load';

/// 068: догруз по паллетам — только если у кузова включено поле паллет.
describe('evaluateVehicleLoad — паллеты по флагу кузова', () => {
  const ready = new Date('2026-10-20T00:00:00Z');
  const run = (showPallets: boolean) => {
    const db: any = {
      deal: { findMany: jest.fn().mockResolvedValue([{ id: 'deal1', cargo: { weightKg: 5000, volumeM3: null, palletCount: 20, readyDate: ready, destinationCountryId: 'kz', destinationCityId: null } }]) },
      vehicle: { findUnique: jest.fn().mockResolvedValue({ capacityTons: 20, volumeM3: null, palletsEuro: 33, bodyType: { profile: 'VOLUME', showPallets } }) },
    };
    return evaluateVehicleLoad(db, {
      driverId: 'd1',
      tractorId: 't1',
      trailerId: 'tr1',
      cargo: { weightKg: 5000 as any, volumeM3: null, palletCount: 20, readyDate: ready },
      partialLoadsEnabled: true,
    });
  };

  it('выключено — 40 паллет на 33 места не мешают (вес помещается)', async () => {
    expect((await run(false)).verdict).toBe('OK');
  });

  it('включено — 40 паллет на 33 места: машина полная', async () => {
    expect((await run(true)).verdict).toBe('FULL');
  });
});
