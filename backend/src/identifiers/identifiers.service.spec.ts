import { IdentifiersService } from './identifiers.service';
import { hashIdentifier } from './crypto';

const OLD_ENV = process.env;

function prismaMock() {
  return {
    identifier: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      upsert: jest.fn(),
      findUnique: jest.fn(),
    },
    blockedIdentifier: {
      findFirst: jest.fn(),
      create: jest.fn(),
      updateMany: jest.fn(),
    },
    auditLog: { create: jest.fn() },
  };
}

describe('IdentifiersService constructor — задача 031, этап F, п.27', () => {
  afterEach(() => {
    process.env = OLD_ENV;
  });

  it('throws at construction if IDENTIFIER_PEPPER/IDENTIFIER_KEY are not configured (same principle as JWT_ACCESS_SECRET)', () => {
    process.env = { ...OLD_ENV };
    delete process.env.IDENTIFIER_PEPPER;
    delete process.env.IDENTIFIER_KEY;
    expect(() => new IdentifiersService({} as any)).toThrow('IDENTIFIER_PEPPER is not configured');
  });
});

describe('IdentifiersService — задача 031, этап C', () => {
  let prisma: ReturnType<typeof prismaMock>;
  let service: IdentifiersService;

  beforeEach(() => {
    process.env = { ...OLD_ENV, IDENTIFIER_PEPPER: 'test-pepper', IDENTIFIER_KEY: 'a'.repeat(64) };
    prisma = prismaMock();
    service = new IdentifiersService(prisma as any);
  });

  afterEach(() => {
    process.env = OLD_ENV;
  });

  describe('checkMatches', () => {
    it('reports ⛔ when the normalized value is on the blacklist and not lifted', async () => {
      prisma.blockedIdentifier.findFirst.mockResolvedValue({ reason: 'Мошенничество с грузом', createdAt: new Date('2026-10-01') });
      prisma.identifier.findFirst.mockResolvedValue(null);

      const result = await service.checkMatches('IIN', '850712300123');

      expect(prisma.blockedIdentifier.findFirst).toHaveBeenCalledWith({
        where: { type: 'IIN', valueHash: hashIdentifier('850712300123'), liftedAt: null },
        orderBy: { createdAt: 'desc' },
      });
      expect(result.blocked).toEqual({ reason: 'Мошенничество с грузом', blockedAt: new Date('2026-10-01') });
    });

    it('reports a ⚠ duplicate when another active owner already confirmed the same value', async () => {
      prisma.blockedIdentifier.findFirst.mockResolvedValue(null);
      prisma.identifier.findFirst.mockResolvedValue({ ownerType: 'DRIVER', ownerId: 'other-driver' });

      const result = await service.checkMatches('PLATE', '123ABC02', { ownerType: 'VEHICLE', ownerId: 'my-vehicle' });

      expect(prisma.identifier.findFirst).toHaveBeenCalledWith({
        where: { type: 'PLATE', valueHash: hashIdentifier('123ABC02'), NOT: { ownerType: 'VEHICLE', ownerId: 'my-vehicle' } },
      });
      expect(result.blocked).toBeNull();
      expect(result.duplicateOwner).toEqual({ ownerType: 'DRIVER', ownerId: 'other-driver' });
    });

    it('reports neither when the value is unseen', async () => {
      prisma.blockedIdentifier.findFirst.mockResolvedValue(null);
      prisma.identifier.findFirst.mockResolvedValue(null);

      const result = await service.checkMatches('VIN', 'XTA123456AB789012');

      expect(result.blocked).toBeNull();
      expect(result.duplicateOwner).toBeNull();
    });
  });

  describe('confirmIdentifier', () => {
    it('upserts by (ownerType, ownerId, type), encrypting only sensitive types', async () => {
      await service.confirmIdentifier({
        type: 'IIN',
        rawValue: '850712 300123',
        ownerType: 'DRIVER',
        ownerId: 'd1',
        confirmedByUserId: 'admin-1',
      });

      expect(prisma.identifier.upsert).toHaveBeenCalledTimes(1);
      const call = prisma.identifier.upsert.mock.calls[0][0];
      expect(call.where).toEqual({ ownerType_ownerId_type: { ownerType: 'DRIVER', ownerId: 'd1', type: 'IIN' } });
      expect(call.create.valueHash).toBe(hashIdentifier('850712300123'));
      expect(call.create.valueMasked).toBe('8507••••0123');
      expect(call.create.valueEncrypted).not.toBeNull();
    });

    it('does not encrypt a non-sensitive type (plate)', async () => {
      await service.confirmIdentifier({ type: 'PLATE', rawValue: '123 ABC 02', ownerType: 'VEHICLE', ownerId: 'v1', confirmedByUserId: 'admin-1' });

      const call = prisma.identifier.upsert.mock.calls[0][0];
      expect(call.create.valueEncrypted).toBeNull();
      expect(call.create.valueMasked).toBe('123ABC02');
    });
  });

  describe('blockOwnerIdentifiers / liftOwnerIdentifierBlocks', () => {
    it('blocks every confirmed identifier of the owner, skipping ones already actively blocked', async () => {
      prisma.identifier.findMany.mockResolvedValue([
        { type: 'IIN', valueHash: 'hash-iin', valueMasked: '8507••••0123' },
        { type: 'PHONE', valueHash: 'hash-phone', valueMasked: '+77011234501' },
      ]);
      prisma.blockedIdentifier.findFirst
        .mockResolvedValueOnce(null) // IIN not yet blocked
        .mockResolvedValueOnce({ id: 'already-blocked' }); // PHONE already blocked

      const created = await service.blockOwnerIdentifiers({ ownerType: 'DRIVER', ownerId: 'd1', reason: 'Жалоба на мошенничество', blockedByUserId: 'admin-1' });

      expect(prisma.blockedIdentifier.create).toHaveBeenCalledTimes(1);
      expect(prisma.blockedIdentifier.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ type: 'IIN', valueHash: 'hash-iin', sourceOwnerType: 'DRIVER', sourceOwnerId: 'd1' }),
      });
      expect(created).toHaveLength(1);
    });

    it('lifts only the blocks that trace back to this owner', async () => {
      await service.liftOwnerIdentifierBlocks({ ownerType: 'DRIVER', ownerId: 'd1', reason: 'Ошибка блокировки', liftedByUserId: 'admin-1' });

      expect(prisma.blockedIdentifier.updateMany).toHaveBeenCalledWith({
        where: { sourceOwnerType: 'DRIVER', sourceOwnerId: 'd1', liftedAt: null },
        data: expect.objectContaining({ liftedByUserId: 'admin-1', liftReason: 'Ошибка блокировки' }),
      });
    });
  });

  describe('blockDriverAndVehicles', () => {
    it('blocks the driver and every listed vehicle', async () => {
      prisma.identifier.findMany.mockResolvedValue([]);

      await service.blockDriverAndVehicles({ driverId: 'd1', vehicleIds: ['tractor1', 'trailer1'], reason: 'r', blockedByUserId: 'admin-1' });

      // driver + 2 vehicles = 3 lookups of confirmed identifiers to block.
      expect(prisma.identifier.findMany).toHaveBeenCalledTimes(3);
      expect(prisma.identifier.findMany).toHaveBeenCalledWith({ where: { ownerType: 'DRIVER', ownerId: 'd1' } });
      expect(prisma.identifier.findMany).toHaveBeenCalledWith({ where: { ownerType: 'VEHICLE', ownerId: 'tractor1' } });
      expect(prisma.identifier.findMany).toHaveBeenCalledWith({ where: { ownerType: 'VEHICLE', ownerId: 'trailer1' } });
    });
  });

  describe('revealIdentifier', () => {
    it('decrypts the value and writes an audit_log entry', async () => {
      const { encryptIdentifier } = require('./crypto');
      prisma.identifier.findUnique.mockResolvedValue({
        id: 'ident-1',
        type: 'IIN',
        ownerType: 'DRIVER',
        ownerId: 'd1',
        valueEncrypted: encryptIdentifier('850712300123'),
      });

      const value = await service.revealIdentifier('ident-1', 'admin-1');

      expect(value).toBe('850712300123');
      expect(prisma.auditLog.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ actorUserId: 'admin-1', action: 'IDENTIFIER_REVEALED', entityType: 'Identifier', entityId: 'ident-1' }),
      });
    });

    it('returns null for a non-sensitive type with nothing encrypted, without touching audit_log', async () => {
      prisma.identifier.findUnique.mockResolvedValue({ id: 'ident-2', type: 'PLATE', valueEncrypted: null });

      const value = await service.revealIdentifier('ident-2', 'admin-1');

      expect(value).toBeNull();
      expect(prisma.auditLog.create).not.toHaveBeenCalled();
    });
  });
});
