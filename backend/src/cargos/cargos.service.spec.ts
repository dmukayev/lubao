import { CargosService } from './cargos.service';

describe('CargosService.feed — hides blocked companies\' cargo (задача 026, п.5)', () => {
  it('filters by company.isBlocked: false, without touching cargo status', async () => {
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([]) },
      deal: { count: jest.fn() },
    };
    const service = new CargosService(prisma);

    await service.feed();

    expect(prisma.cargo.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { status: 'PUBLISHED', company: { isBlocked: false } } }),
    );
  });
});
