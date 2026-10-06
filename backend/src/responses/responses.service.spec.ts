import { Prisma } from '@prisma/client';
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ResponsesService } from './responses.service';

const FAKE_CHAT_SYSTEM = { post: jest.fn(), postToChat: jest.fn() };

function txMock() {
  return {
    response: { updateMany: jest.fn().mockResolvedValue({ count: 1 }), update: jest.fn(), create: jest.fn(), findUniqueOrThrow: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
    cargo: { updateMany: jest.fn() },
    // findFirst — проверка «на груз нет активной сделки» (задача 038, п.1).
    deal: { create: jest.fn(), findFirst: jest.fn().mockResolvedValue(null) },
    chat: { updateMany: jest.fn() },
    $queryRaw: jest.fn().mockResolvedValue([]),
    // Задача 031 — снимок связки тягач/прицеп при создании сделки; задача
    // 032, п.5 — источник связки теперь активный анонс водителя, гараж
    // (vehicle.findFirst) — только фолбэк, когда анонса нет.
    arrival: { findMany: jest.fn().mockResolvedValue([]) },
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
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', publishedByUserId: 'logist-1', status: 'PUBLISHED' }) },
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
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', publishedByUserId: null, status: 'PUBLISHED' }) },
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
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', status: 'PUBLISHED' }) },
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
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', publishedByUserId: 'logist-1', status: 'PUBLISHED' }) },
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
    const tx = txMock();
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'REJECTED', driver: { userId: 'u1' } });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const notifications = { notify: jest.fn() };
    const service = new ResponsesService(prisma, notifications as any, FAKE_CHAT_SYSTEM as any);

    await service.updateStatus('r1', 'c1', 'REJECTED');

    expect(tx.response.updateMany).toHaveBeenCalledWith({ where: { id: 'r1', status: { in: ['PENDING', 'INVITED'] } }, data: { status: 'REJECTED' } });
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
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
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
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
    tx.arrival.findMany.mockResolvedValue([{ status: 'PLANNED', tractorId: 'announced-tractor', trailerId: 'announced-trailer' }]);
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
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'user-d1' } });
    tx.arrival.findMany.mockResolvedValue([]);
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
    const tx = txMock();
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'CANCELLED', driver: { fullName: 'Ерлан', userId: 'user-d1' } });
    const prisma: any = {
      response: {
        findUnique: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'PENDING', driver: { fullName: 'Ерлан' }, cargo: { companyId: 'c1' } }),
      },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    const result = await service.withdraw('r1', 'd1');

    expect(tx.response.updateMany).toHaveBeenCalledWith({ where: { id: 'r1', status: { in: ['PENDING', 'INVITED'] } }, data: { status: 'CANCELLED' } });
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

describe('ResponsesService.createDealDirect — attaches the pre-deal chat too (задача 017, п.3) + CARGO_INVITE (011)', () => {
  it('rejects a driver whose response is already decided', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue({ status: 'REJECTED' }) },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.createDealDirect('cargo1', 'd1', 'c1')).rejects.toThrow(ConflictException);
  });

  it('039 п.3: P2002 от уникального индекса при приглашении — 409, а не 500', async () => {
    const tx = txMock();
    tx.response.create.mockRejectedValue(new Prisma.PrismaClientKnownRequestError('dup', { code: 'P2002', clientVersion: 'x' }));
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.createDealDirect('cargo1', 'd1', 'c1')).rejects.toThrow(ConflictException);
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

    await service.createDealDirect('cargo1', 'd1', 'c1');

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
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'SELECTED', driver: { userId: 'user-d1' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', companyId: 'c1', company: { name: 'Acme' } }) },
      response: { findUnique: jest.fn().mockResolvedValue({ id: 'r1', status: 'CANCELLED' }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await service.createDealDirect('cargo1', 'd1', 'c1');

    expect(tx.response.create).not.toHaveBeenCalled();
    expect(tx.response.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'r1', status: { in: ['PENDING', 'INVITED', 'CANCELLED'] } }, data: { status: 'SELECTED' } }),
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

    await expect(service.createDealDirect('cargo1', 'd1', 'c1')).rejects.toThrow(ConflictException);
    expect(tx.deal.create).not.toHaveBeenCalled();
  });
});

describe('ResponsesService — гонка двух сделок на груз (задача 038, п.22)', () => {
  it('берёт advisory-замок по грузу ДО проверки активной сделки', async () => {
    const tx = txMock();
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'u1' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await service.updateStatus('r1', 'c1', 'SELECTED');

    expect(tx.$queryRaw.mock.invocationCallOrder[0]).toBeLessThan(tx.deal.findFirst.mock.invocationCallOrder[0]);
  });

  it('отклик, ушедший из PENDING между чтением и замком, → 409 и сделка не создаётся', async () => {
    const tx = txMock();
    tx.response.updateMany.mockResolvedValue({ count: 0 });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);

    await expect(service.updateStatus('r1', 'c1', 'SELECTED')).rejects.toThrow(ConflictException);
    expect(tx.deal.create).not.toHaveBeenCalled();
  });
});

describe('ResponsesService.updateStatus REJECTED — системная строка водителю (задача 038, п.27)', () => {
  it('постит RESPONSE_REJECTED в чат пары', async () => {
    const chatSystem = { post: jest.fn(), postToChat: jest.fn() };
    const tx = txMock();
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'REJECTED', driver: { userId: 'u-d1', fullName: 'Ерлан' } });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, chatSystem as any);

    await service.updateStatus('r1', 'c1', 'REJECTED', 'logist-1');

    expect(chatSystem.post).toHaveBeenCalledWith(
      expect.objectContaining({ driverId: 'd1', companyId: 'c1', cargoId: 'cargo1', actorUserId: 'logist-1', code: 'RESPONSE_REJECTED' }),
    );
  });

  it('DRIVER_SELECTED несёт имя водителя (нейтральный текст для обеих сторон)', async () => {
    const chatSystem = { post: jest.fn(), postToChat: jest.fn() };
    const tx = txMock();
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'u-d1', fullName: 'Ерлан Тохтаров' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', status: 'PENDING', cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, chatSystem as any);

    await service.updateStatus('r1', 'c1', 'SELECTED', 'logist-1');

    expect(chatSystem.post).toHaveBeenCalledWith(
      expect.objectContaining({ code: 'DRIVER_SELECTED', systemParams: { driverName: 'Ерлан Тохтаров' } }),
    );
  });
});

describe('ResponsesService — «Отклонить»/«Отозвать» под замком груза (задача 039, п.1)', () => {
  function setup(claimCount: number) {
    const tx = txMock();
    tx.response.updateMany.mockResolvedValue({ count: claimCount });
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'u', fullName: 'Е' } });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'PENDING', cargo: { companyId: 'c1' }, driver: { userId: 'u', fullName: 'Е' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    return { tx, service: new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any) };
  }

  it('замок по грузу берётся до условного апдейта (reject)', async () => {
    const { tx, service } = setup(1);
    await service.updateStatus('r1', 'c1', 'REJECTED');
    expect(tx.$queryRaw.mock.invocationCallOrder[0]).toBeLessThan(tx.response.updateMany.mock.invocationCallOrder[0]);
  });

  it('параллельный «Выбрать» успел раньше: reject → 409, статус не перезаписан', async () => {
    const { service } = setup(0);
    await expect(service.updateStatus('r1', 'c1', 'REJECTED')).rejects.toThrow(ConflictException);
  });

  it('параллельный «Выбрать» успел раньше: withdraw → 409', async () => {
    const { service } = setup(0);
    await expect(service.withdraw('r1', 'd1')).rejects.toThrow(ConflictException);
  });
});


describe('ResponsesService — приглашение с согласием, груз в сделке (задача 041)', () => {
  const cargoPublished = { id: 'cargo1', companyId: 'c1', status: 'PUBLISHED', company: { name: 'Acme' } };

  it('createForCargo: груз IN_DEAL — 409 CARGO_NOT_AVAILABLE, отклик не создаётся', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ ...cargoPublished, status: 'IN_DEAL' }) },
      response: { findUnique: jest.fn(), create: jest.fn() },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    await expect(service.createForCargo('cargo1', 'd1', undefined)).rejects.toMatchObject({ response: { code: 'CARGO_NOT_AVAILABLE' } });
    expect(prisma.response.create).not.toHaveBeenCalled();
  });

  it('createForCargo: приглашённый водитель жмёт «Готов взять» — INVITED → PENDING (не 409)', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ ...cargoPublished, publishedByUserId: 'l1' }) },
      response: {
        findUnique: jest.fn().mockResolvedValue({ id: 'r1', status: 'INVITED', message: null }),
        update: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'PENDING', driver: { fullName: 'Ерлан', userId: 'u1' } }),
      },
    };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any);
    const result = await service.createForCargo('cargo1', 'd1', undefined);
    expect(result.status).toBe('PENDING');
  });

  /// inviteDriver работает в $transaction под замком груза (041, п.13).
  function inviteSetup(opts: { freshCargoStatus?: string; existing?: Record<string, unknown> | null } = {}) {
    const tx: any = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      cargo: { findUnique: jest.fn().mockResolvedValue({ status: opts.freshCargoStatus ?? 'PUBLISHED' }) },
      response: {
        findUnique: jest.fn().mockResolvedValue(opts.existing ?? null),
        create: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'INVITED', driver: { fullName: 'Ерлан', userId: 'u1' } }),
        update: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'INVITED', driver: { fullName: 'Ерлан', userId: 'u1' } }),
        updateMany: jest.fn(),
      },
      deal: { create: jest.fn() },
    };
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(cargoPublished) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const notifications = { notify: jest.fn() };
    const chat = { post: jest.fn(), postToChat: jest.fn() };
    return { service: new ResponsesService(prisma, notifications as any, chat as any), prisma, tx, notifications, chat };
  }

  it('inviteDriver: создаёт отклик INVITED, НЕ сделку и НЕ отклоняет чужие отклики', async () => {
    const { service, tx, notifications, chat } = inviteSetup();

    const result = await service.inviteDriver('cargo1', 'd1', 'c1', 'logist-1');

    expect(result.status).toBe('INVITED');
    expect(tx.response.create).toHaveBeenCalledWith(expect.objectContaining({ data: { cargoId: 'cargo1', driverId: 'd1', status: 'INVITED' } }));
    expect(tx.deal.create).not.toHaveBeenCalled();
    expect(tx.response.updateMany).not.toHaveBeenCalled();
    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['u1'] }, 'CARGO_INVITE', { cargoId: 'cargo1', companyName: 'Acme' });
    expect(chat.post).toHaveBeenCalledWith(expect.objectContaining({ code: 'DRIVER_INVITED' }));
  });

  it('041, п.13: статус груза проверяется ПОД замком — ушёл в сделку между проверкой и записью → 409 и никакого «висячего» INVITED', async () => {
    const { service, tx, notifications } = inviteSetup({ freshCargoStatus: 'IN_DEAL' });

    await expect(service.inviteDriver('cargo1', 'd1', 'c1')).rejects.toMatchObject({ response: { code: 'CARGO_NOT_AVAILABLE' } });

    expect(tx.$queryRaw).toHaveBeenCalled(); // advisory-замок взят
    expect(tx.response.create).not.toHaveBeenCalled();
    expect(tx.response.update).not.toHaveBeenCalled();
    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('inviteDriver: отозванный отклик (CANCELLED) переоткрывается как INVITED, тот же id', async () => {
    const { service, tx } = inviteSetup({ existing: { id: 'r1', status: 'CANCELLED', driver: { fullName: 'Ерлан', userId: 'u1' } } });
    await service.inviteDriver('cargo1', 'd1', 'c1');
    expect(tx.response.update).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'r1' }, data: { status: 'INVITED' } }));
    expect(tx.response.create).not.toHaveBeenCalled();
  });

  it('inviteDriver: повторное приглашение того, кто уже в игре, идемпотентно — без повторных уведомлений', async () => {
    const { service, tx, notifications, chat } = inviteSetup({
      existing: { id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'PENDING', driver: { fullName: 'Ерлан' } },
    });
    const result = await service.inviteDriver('cargo1', 'd1', 'c1');
    expect(result.status).toBe('PENDING');
    expect(tx.response.create).not.toHaveBeenCalled();
    expect(notifications.notify).not.toHaveBeenCalled();
    expect(chat.post).not.toHaveBeenCalled();
  });

  it('inviteDriver: груз не опубликован (IN_DEAL) — 409', async () => {
    const { service } = inviteSetup({ freshCargoStatus: 'IN_DEAL' });
    await expect(service.inviteDriver('cargo1', 'd1', 'c1')).rejects.toThrow(ConflictException);
  });

  it('inviteDriver: чужой груз — 403, неизвестный — 404, транзакция не открывается', async () => {
    const { service, prisma } = inviteSetup();
    prisma.cargo.findUnique.mockResolvedValue({ ...cargoPublished, companyId: 'other' });
    await expect(service.inviteDriver('cargo1', 'd1', 'c1')).rejects.toThrow(ForbiddenException);
    prisma.cargo.findUnique.mockResolvedValue(null);
    await expect(service.inviteDriver('cargo1', 'd1', 'c1')).rejects.toThrow(NotFoundException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('«Выбрать»: груз → IN_DEAL, остальные PENDING/INVITED → REJECTED и им «Груз ушёл другому»', async () => {
    const tx = txMock();
    tx.response.findMany.mockResolvedValue([{ id: 'r2', driverId: 'd2', driver: { userId: 'u2' } }]);
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', driver: { userId: 'u1', fullName: 'Ерлан' } });
    tx.deal.create.mockResolvedValue({ id: 'deal1', cargoId: 'cargo1', driverId: 'd1', companyId: 'c1' });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ cargoId: 'cargo1', driverId: 'd1', status: 'PENDING', cargo: { companyId: 'c1' }, driver: { userId: 'u1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const chat = { post: jest.fn(), postToChat: jest.fn() };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, chat as any);

    await service.updateStatus('r1', 'c1', 'SELECTED');

    expect(tx.response.updateMany).toHaveBeenCalledWith({ where: { id: { in: ['r2'] } }, data: { status: 'REJECTED' } });
    expect(tx.cargo.updateMany).toHaveBeenCalledWith({ where: { id: 'cargo1', status: 'PUBLISHED' }, data: { status: 'IN_DEAL' } });
    expect(chat.post).toHaveBeenCalledWith(expect.objectContaining({ driverId: 'd2', code: 'CARGO_TAKEN' }));
  });

  it('водитель отказывается от приглашения: INVITED → CANCELLED, системная строка «отказался от приглашения»', async () => {
    const tx = txMock();
    tx.response.findUniqueOrThrow.mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'CANCELLED', driver: { userId: 'u1', fullName: 'Ерлан' } });
    const prisma: any = {
      response: { findUnique: jest.fn().mockResolvedValue({ id: 'r1', cargoId: 'cargo1', driverId: 'd1', status: 'INVITED', driver: { userId: 'u1' }, cargo: { companyId: 'c1' } }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    const chat = { post: jest.fn(), postToChat: jest.fn() };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, chat as any);
    await service.withdraw('r1', 'd1');
    expect(chat.post).toHaveBeenCalledWith(expect.objectContaining({ code: 'INVITATION_DECLINED' }));
  });
});


describe('ResponsesService.createForCargo — чёрный список по телефону (задача 041)', () => {
  it('водитель с заблокированным номером откликаться не может (403 DRIVER_BLACKLISTED), даже без гейта верификации', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ user: { phone: '+77010000099' } }) },
      cargo: { findUnique: jest.fn() },
      response: { findUnique: jest.fn(), create: jest.fn() },
    };
    const identifiers: any = { checkMatches: jest.fn().mockResolvedValue({ blocked: { reason: 'E2E' }, duplicateOwner: null }) };
    const service = new ResponsesService(prisma, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any, identifiers);
    await expect(service.createForCargo('cargo1', 'd1')).rejects.toMatchObject({ response: { code: 'DRIVER_BLACKLISTED' } });
    expect(prisma.response.create).not.toHaveBeenCalled();
  });
});
