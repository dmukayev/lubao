import { markResponsesSeen, newResponsesByCargo } from './new-responses';

/// 056 п.5: «новые» — у каждого сотрудника свои.
describe('newResponsesByCargo', () => {
  it('без отметки «видел» — все ждущие новые; с отметкой — только позже неё', async () => {
    const prisma: any = {
      cargoResponsesSeen: { findMany: jest.fn().mockResolvedValue([{ cargoId: 'c2', seenAt: new Date('2026-10-09T12:00:00Z') }]) },
      response: {
        findMany: jest.fn().mockResolvedValue([
          { cargoId: 'c1', updatedAt: new Date('2026-10-09T10:00:00Z') },
          { cargoId: 'c1', updatedAt: new Date('2026-10-09T11:00:00Z') },
          { cargoId: 'c2', updatedAt: new Date('2026-10-09T11:00:00Z') },
          { cargoId: 'c2', updatedAt: new Date('2026-10-09T13:00:00Z') },
        ]),
      },
    };
    const r = await newResponsesByCargo(prisma, 'u1', ['c1', 'c2']);
    expect(r.get('c1')).toBe(2);
    expect(r.get('c2')).toBe(1);
    expect(prisma.cargoResponsesSeen.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { userId: 'u1', cargoId: { in: ['c1', 'c2'] } } }));
    expect(prisma.response.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { cargoId: { in: ['c1', 'c2'] }, status: 'PENDING' } }));
  });

  it('открыл отклики — отметка «видел» для этого сотрудника', async () => {
    const prisma: any = { cargoResponsesSeen: { upsert: jest.fn() } };
    const at = new Date('2026-10-09T14:00:00Z');
    await markResponsesSeen(prisma, 'u1', 'c1', at);
    expect(prisma.cargoResponsesSeen.upsert).toHaveBeenCalledWith({ where: { userId_cargoId: { userId: 'u1', cargoId: 'c1' } }, create: { userId: 'u1', cargoId: 'c1', seenAt: at }, update: { seenAt: at } });
  });
});
