import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ResponsesService } from './responses.service';

function txMock() {
  return {
    response: { updateMany: jest.fn(), update: jest.fn(), create: jest.fn() },
    deal: { create: jest.fn() },
    chat: { updateMany: jest.fn() },
  };
}

describe('ResponsesService.createForCargo — NEW_RESPONSE notification (задача 011)', () => {
  it('throws NotFoundException for an unknown cargo', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue(null) },
      cargo: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any);
    await expect(service.createForCargo('cargo1', 'd1', 'hi')).rejects.toThrow(NotFoundException);
  });

  it('notifies the cargo publisher (push) and the whole company (WeCom)', async () => {
    const prisma: any = {
      response: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { fullName: 'Ерлан' } }),
      },
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', publishedByUserId: 'logist-1' }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any);

    await service.createForCargo('cargo1', 'd1', 'hi');

    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['logist-1'], companyId: 'c1' },
      'NEW_RESPONSE',
      { cargoId: 'cargo1', driverName: 'Ерлан' },
    );
  });

  it('falls back to the oldest OWNER when the cargo has no publisher', async () => {
    const prisma: any = {
      response: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { fullName: 'Ерлан' } }),
      },
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', publishedByUserId: null }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ userId: 'owner-1' }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any);

    await service.createForCargo('cargo1', 'd1', 'hi');

    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['owner-1'], companyId: 'c1' },
      'NEW_RESPONSE',
      expect.anything(),
    );
  });

  it('rejects a duplicate response before touching notifications', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ id: 'existing' }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any);

    await expect(service.createForCargo('cargo1', 'd1', 'hi')).rejects.toThrow(ConflictException);
    expect(notifications.notify).not.toHaveBeenCalled();
  });
});

describe('ResponsesService.updateStatus — attaches the pre-deal chat (задача 017, п.3) + DEAL_STATUS (011)', () => {
  it('REJECTED does not touch deal/chat/notifications', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', cargo: { companyId: 'c1' } }), update: jest.fn().mockResolvedValue({ driver: {} }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any);

    await service.updateStatus('r1', 'c1', 'REJECTED');

    expect(prisma.response.update).toHaveBeenCalledWith(expect.objectContaining({ data: { status: 'REJECTED' } }));
    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('throws NotFoundException for an unknown response', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any);
    await expect(service.updateStatus('missing', 'c1', 'REJECTED')).rejects.toThrow(NotFoundException);
  });

  it('refuses to act on another company\'s cargo', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', cargo: { companyId: 'other' } }) } };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any);
    await expect(service.updateStatus('r1', 'c1', 'REJECTED')).rejects.toThrow(ForbiddenException);
  });

  it('SELECTED creates the deal, re-attaches any existing pre-deal chat, and notifies the driver of the status change', async () => {
    const tx = txMock();
    tx.response.update.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any);

    await service.updateStatus('r1', 'c1', 'SELECTED');

    expect(tx.chat.updateMany).toHaveBeenCalledWith({
      where: { driverId: 'd1', companyId: 'c1', cargoId: 'cargo1' },
      data: { dealId: 'deal1' },
    });
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['user-d1'] },
      'DEAL_STATUS',
      expect.objectContaining({ dealId: 'deal1' }),
    );
  });
});

describe('ResponsesService.inviteDriver — attaches the pre-deal chat too (задача 017, п.3) + CARGO_INVITE (011)', () => {
  it('rejects a driver whose response is already decided', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue({ status: 'REJECTED' }) },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any);
    await expect(service.inviteDriver('cargo1', 'd1', 'c1')).rejects.toThrow(ConflictException);
  });

  it('creates a SELECTED response + deal, attaches the chat, and notifies the invited driver', async () => {
    const tx = txMock();
    tx.response.create.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any);

    await service.inviteDriver('cargo1', 'd1', 'c1');

    expect(tx.chat.updateMany).toHaveBeenCalledWith({
      where: { driverId: 'd1', companyId: 'c1', cargoId: 'cargo1' },
      data: { dealId: 'deal1' },
    });
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['user-d1'] },
      'CARGO_INVITE',
      { cargoId: 'cargo1', companyName: 'Acme' },
    );
  });
});
