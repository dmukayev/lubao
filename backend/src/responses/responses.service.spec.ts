import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ResponsesService } from './responses.service';

const FAKE_CHAT_SYSTEM = { post: jest.fn(), postToChat: jest.fn() };

function txMock() {
  return {
    response: { updateMany: jest.fn(), update: jest.fn(), create: jest.fn() },
    // findFirst — проверка «на груз нет активной сделки» (задача 038, п.1).
    deal: { create: jest.fn(), findFirst: jest.fn().mockResolvedValue(null) },
    chat: { updateMany: jest.fn() },
    // Задача 031 — снимок связки тягач/прицеп при создании сделки; задача
    // 032, п.5 — источник связки теперь активный анонс водителя, гараж
    // (vehicle.findFirst) — только фолбэк, когда анонса нет.
    arrival: { findFirst: jest.fn().mockResolvedValue(null) },
    vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
  };
}

describe('ResponsesService.createForCargo — NEW_RESPONSE notification (задача 011)', () => {
  it('throws NotFoundException for an unknown cargo', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue(null) },
      cargo: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
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
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

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
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

    await service.createForCargo('cargo1', 'd1', 'hi');

    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['owner-1'], companyId: 'c1' },
      'NEW_RESPONSE',
      expect.anything(),
    );
  });

  it('rejects a duplicate response before touching notifications', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ id: 'existing', status: 'PENDING' }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

    await expect(service.createForCargo('cargo1', 'd1', 'hi')).rejects.toThrow(ConflictException);
    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('задача 038, п.2 — reopens a CANCELLED response instead of 409 (withdraw → changed mind)', async () => {
    const prisma: any = {
      response: {
        findUnique: jest.fn().mockResolvedValue({ id: 'r1', status: 'CANCELLED', message: 'старое' }),
        update: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'PENDING', driver: { fullName: 'Ерлан' } }),
        create: jest.fn(),
      },
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', publishedByUserId: 'logist-1' }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

    const result = await service.createForCargo('cargo1', 'd1', undefined);

    expect(prisma.response.create).not.toHaveBeenCalled();
    expect(prisma.response.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'r1' }, data: { status: 'PENDING', message: 'старое' } }),
    );
    expect(result.status).toBe('PENDING');
    // Логист снова получает уведомление — для него это новый отклик.
    expect(notifications.notify).toHaveBeenCalled();
  });
});

describe('ResponsesService.updateStatus — attaches the pre-deal chat (задача 017, п.3) + DEAL_STATUS (011)', () => {
  it('REJECTED does not touch deal/chat/notifications', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }), update: jest.fn().mockResolvedValue({ driver: {} }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

    await service.updateStatus('r1', 'c1', 'REJECTED');

    expect(prisma.response.update).toHaveBeenCalledWith(expect.objectContaining({ data: { status: 'REJECTED' } }));
    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('throws NotFoundException for an unknown response', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.updateStatus('missing', 'c1', 'REJECTED')).rejects.toThrow(NotFoundException);
  });

  it('refuses to act on another company\'s cargo', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'other' } }) } };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.updateStatus('r1', 'c1', 'REJECTED')).rejects.toThrow(ForbiddenException);
  });

  it('SELECTED creates the deal, re-attaches any existing pre-deal chat, and notifies the driver of the status change', async () => {
    const tx = txMock();
    tx.response.update.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

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

  it('задача 038, п.1 — SELECTED only from PENDING: a REJECTED response cannot be resurrected into a deal', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'REJECTED', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await expect(service.updateStatus('r1', 'c1', 'SELECTED')).rejects.toThrow(ConflictException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('задача 038, п.1 — 409 CARGO_ALREADY_HAS_DEAL when the cargo already has an active deal', async () => {
    const tx = txMock();
    tx.deal.findFirst.mockResolvedValue({ id: 'existing-deal' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await expect(service.updateStatus('r1', 'c1', 'SELECTED')).rejects.toThrow(ConflictException);
    expect(tx.deal.findFirst).toHaveBeenCalledWith({
      where: { cargoId: 'cargo1', status: { not: 'CANCELLED' } },
      select: { id: true },
    });
    expect(tx.deal.create).not.toHaveBeenCalled();
  });

  it('задача 038, п.1 — REJECTED is idempotent but refuses to reject a SELECTED response', async () => {
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'SELECTED', cargo: { companyId: 'c1' }, driver: { fullName: 'X' } }), update: jest.fn() },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.updateStatus('r1', 'c1', 'REJECTED')).rejects.toThrow(ConflictException);

    prisma.response.findUnique.mockResolvedValue({ cargoId: 'cargo1', status: 'REJECTED', cargo: { companyId: 'c1' }, driver: { fullName: 'X' } });
    const result = await service.updateStatus('r1', 'c1', 'REJECTED');
    expect(result.status).toBe('REJECTED');
    expect(prisma.response.update).not.toHaveBeenCalled();
  });

  it('задача 032, п.5 — the deal combo comes from the driver\'s active arrival, not the first-by-date vehicles in the garage', async () => {
    const tx = txMock();
    tx.response.update.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
    tx.arrival.findFirst.mockResolvedValue({ tractorId: 'announced-tractor', trailerId: 'announced-trailer' });
    // Гараж вернул бы ДРУГУЮ, первую по дате машину — не должна попасть в сделку.
    tx.vehicle.findFirst.mockResolvedValue({ id: 'garage-first-tractor' });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await service.updateStatus('r1', 'c1', 'SELECTED');

    expect(tx.deal.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'announced-tractor', trailerId: 'announced-trailer' }) }),
    );
    expect(tx.vehicle.findFirst).not.toHaveBeenCalled();
  });

  it('задача 032, п.5 — falls back to the garage only when there is no active arrival at all', async () => {
    const tx = txMock();
    tx.response.update.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
    tx.arrival.findFirst.mockResolvedValue(null);
    tx.vehicle.findFirst.mockResolvedValueOnce({ id: 'garage-tractor' }).mockResolvedValueOnce({ id: 'garage-trailer' });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await service.updateStatus('r1', 'c1', 'SELECTED');

    expect(tx.deal.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'garage-tractor', trailerId: 'garage-trailer' }) }),
    );
  });
});

describe('ResponsesService.withdraw — «Отозвать» (задача 035)', () => {
  it('cancels a PENDING response belonging to this driver', async () => {
    const prisma: any = {
      response: {
        findUnique: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'PENDING', driver: { fullName: 'Ерлан' }, cargo: { companyId: 'c1' } }),
        update: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'CANCELLED', driver: { fullName: 'Ерлан', userId: 'user-d1' } }),
      },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    const result = await service.withdraw('r1', 'd1');

    expect(prisma.response.update).toHaveBeenCalledWith({ where: { id: 'r1' }, data: { status: 'CANCELLED' }, include: { driver: true } });
    expect(result.status).toBe('CANCELLED');
  });

  it('throws NotFoundException for an unknown response', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.withdraw('missing', 'd1')).rejects.toThrow(NotFoundException);
  });

  it('refuses to withdraw another driver\'s response', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue({ id: 'r1', driverId: 'someone-else', status: 'PENDING' }) } };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.withdraw('r1', 'd1')).rejects.toThrow(ForbiddenException);
  });

  it('refuses to withdraw a response that is no longer PENDING (logist already acted on it)', async () => {
    const prisma: any = { response: { findUnique: jest.fn().mockResolvedValue({ id: 'r1', driverId: 'd1', status: 'SELECTED' }) } };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.withdraw('r1', 'd1')).rejects.toThrow(ConflictException);
  });
});

describe('ResponsesService.inviteDriver — attaches the pre-deal chat too (задача 017, п.3) + CARGO_INVITE (011)', () => {
  it('rejects a driver whose response is already decided', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue({ status: 'REJECTED' }) },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
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
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

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

  it('задача 038, п.2 — a CANCELLED response can be re-invited (reopened as SELECTED)', async () => {
    const tx = txMock();
    tx.response.update.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'SELECTED', driver: { userId: 'user-d1' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue({ id: 'r1', status: 'CANCELLED' }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await service.inviteDriver('cargo1', 'd1', 'c1');

    expect(tx.response.create).not.toHaveBeenCalled();
    expect(tx.response.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'r1' }, data: { status: 'SELECTED' } }),
    );
  });

  it('задача 038, п.1 — invite refuses when the cargo already has an active deal', async () => {
    const tx = txMock();
    tx.deal.findFirst.mockResolvedValue({ id: 'existing-deal' });
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await expect(service.inviteDriver('cargo1', 'd1', 'c1')).rejects.toThrow(ConflictException);
    expect(tx.deal.create).not.toHaveBeenCalled();
  });
});
