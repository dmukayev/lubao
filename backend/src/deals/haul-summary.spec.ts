import { haulInfoByDriver } from './haul-summary';

describe('haulInfoByDriver — «Уже везёт…» (задача 038, п.8)', () => {
  const cargo = (weightKg: number | null) => ({
    weightKg,
    readyDate: new Date('2026-10-10T00:00:00Z'),
    destinationCountryId: 'kz',
    destinationCityId: 'almaty',
  });

  it('считает по тягачу: сделки другого тягача того же водителя не попадают в сводку', async () => {
    const prisma: any = {
      deal: {
        findMany: jest.fn().mockResolvedValue([
          { driverId: 'd1', tractorId: 'tractor-a', cargo: cargo(8000) },
          { driverId: 'd1', tractorId: 'tractor-b', cargo: cargo(20000) },
        ]),
      },
    };

    const result = await haulInfoByDriver(prisma, [{ driverId: 'd1', tractorId: 'tractor-a' }]);

    expect(result.get('d1')).toMatchObject({ committedWeightKg: 8000, activeDealsCount: 1 });
  });

  it('tractorId=null (старый анонс без связки) — консервативно считаются все активные сделки', async () => {
    const prisma: any = {
      deal: {
        findMany: jest.fn().mockResolvedValue([
          { driverId: 'd1', tractorId: 'tractor-a', cargo: cargo(8000) },
          { driverId: 'd1', tractorId: 'tractor-b', cargo: cargo(5000) },
        ]),
      },
    };

    const result = await haulInfoByDriver(prisma, [{ driverId: 'd1', tractorId: null }]);

    expect(result.get('d1')).toMatchObject({ committedWeightKg: 13000, activeDealsCount: 2 });
  });

  it('груз без веса — флаг «машина занята», а не молчаливый +0', async () => {
    const prisma: any = {
      deal: {
        findMany: jest.fn().mockResolvedValue([{ driverId: 'd1', tractorId: 't1', cargo: cargo(null) }]),
      },
    };

    const result = await haulInfoByDriver(prisma, [{ driverId: 'd1', tractorId: 't1' }]);

    expect(result.get('d1')).toMatchObject({
      committedWeightKg: 0,
      activeDealsCount: 1,
      committedHasUnknownWeight: true,
      committedDestinationCountryId: 'kz',
    });
  });

  it('без активных сделок — нули, пустой список водителей — пустая карта без запроса', async () => {
    const prisma: any = { deal: { findMany: jest.fn().mockResolvedValue([]) } };
    const result = await haulInfoByDriver(prisma, [{ driverId: 'd1', tractorId: 't1' }]);
    expect(result.get('d1')).toMatchObject({ committedWeightKg: 0, activeDealsCount: 0, committedHasUnknownWeight: false });

    const prisma2: any = { deal: { findMany: jest.fn() } };
    const empty = await haulInfoByDriver(prisma2, []);
    expect(empty.size).toBe(0);
    expect(prisma2.deal.findMany).not.toHaveBeenCalled();
  });
});
