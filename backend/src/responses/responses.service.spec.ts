import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ResponsesService } from './responses.service';

function txMock() {
  return {
    response: { updateMany: jest.fn(), update: jest.fn(), create: jest.fn() },
    deal: { create: jest.fn() },
    chat: { updateMany: jest.fn() },
  };
}

describe('ResponsesService.updateStatus — attaches the pre-deal chat (задача 017, п.3)', () => {
  it('REJECTED does not touch deal/chat', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', cargo: { companyId: 'c1' } }), update: jest.fn().mockResolvedValue({ driver: {} }) },
    };
    const service = new ResponsesService(prisma);

    await service.updateStatus('r1', 'c1', 'REJECTED');

    expect(prisma.response.update).toHaveBeenCalledWith(expect.objectContaining({ data: { status: 'REJECTED' } }));
  });

  it('throws NotFoundException for an unknown response', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new ResponsesService(prisma);
    await expect(service.updateStatus('missing', 'c1', 'REJECTED')).rejects.toThrow(NotFoundException);
  });

  it('refuses to act on another company\'s cargo', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', cargo: { companyId: 'other' } }) } };
    const service = new ResponsesService(prisma);
    await expect(service.updateStatus('r1', 'c1', 'REJECTED')).rejects.toThrow(ForbiddenException);
  });

  it('SELECTED creates the deal and re-attaches any existing pre-deal chat for that driver+company+cargo', async () => {
    const tx = txMock();
    tx.response.update.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: {} });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma);

    await service.updateStatus('r1', 'c1', 'SELECTED');

    expect(tx.chat.updateMany).toHaveBeenCalledWith({
      where: { driverId: 'd1', companyId: 'c1', cargoId: 'cargo1' },
      data: { dealId: 'deal1' },
    });
  });
});

describe('ResponsesService.inviteDriver — attaches the pre-deal chat too (задача 017, п.3)', () => {
  it('rejects a driver whose response is already decided', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1' }) },
      response: { findUnique: jest.fn().mockResolvedValue({ status: 'REJECTED' }) },
    };
    const service = new ResponsesService(prisma);
    await expect(service.inviteDriver('cargo1', 'd1', 'c1')).rejects.toThrow(ConflictException);
  });

  it('creates a SELECTED response + deal, then attaches the chat', async () => {
    const tx = txMock();
    tx.response.create.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: {} });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1' }) },
      response: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma);

    await service.inviteDriver('cargo1', 'd1', 'c1');

    expect(tx.chat.updateMany).toHaveBeenCalledWith({
      where: { driverId: 'd1', companyId: 'c1', cargoId: 'cargo1' },
      data: { dealId: 'deal1' },
    });
  });
});
