import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { encryptIdentifier } from '../identifiers/crypto';
import { DOCS_AFTER_DELIVERY_MS, DriverDocumentsService } from './driver-documents.service';

// 044 п.1, п.8: пакет документов водителя — только компании-владельцу груза,
// после подтверждения водителем и до доставки + 30 дней; каждое открытие — в журнал.
function dealRow(over: Record<string, unknown> = {}) {
  return {
    id: 'deal1',
    driverId: 'd1',
    companyId: 'c1',
    status: 'CONFIRMED_BY_DRIVER',
    deliveredAt: null,
    tractorId: 'v1',
    trailerId: 'v2',
    driver: { id: 'd1', fullName: 'Ерлан Тестов', isVerified: true },
    company: { name: 'E2E Logistics' },
    cargo: { pointId: 'p1', destinationCityId: 'city2', destinationCountryId: 'kz', readyDate: new Date('2030-01-01') },
    ...over,
  };
}

function setup(deal: unknown) {
  const prisma: any = {
    deal: { findUnique: jest.fn().mockResolvedValue(deal) },
    verificationDocument: {
      findMany: jest
        .fn()
        .mockResolvedValueOnce([
          { id: 'selfie1', type: 'SELFIE', status: 'APPROVED', recognition: null },
          { id: 'lic1', type: 'DRIVER_LICENSE', status: 'APPROVED', recognition: { fields: { expiryDate: { value: '2031-05-01' } } } },
        ])
        .mockResolvedValueOnce([{ id: 'pass1', type: 'VEHICLE_PASSPORT', status: 'PENDING', vehicleId: 'v1' }]),
      findUnique: jest.fn(),
    },
    vehicle: {
      findMany: jest.fn().mockResolvedValue([
        { id: 'v2', kind: 'TRAILER', plateNumber: '12ABC02', vin: null, brand: null, isVerified: true },
        { id: 'v1', kind: 'TRACTOR', plateNumber: '123ABC02', vin: 'WDB9634031L123456', brand: 'MAN', isVerified: false },
      ]),
    },
    identifier: {
      findMany: jest.fn().mockResolvedValue([
        { type: 'IIN', valueEncrypted: encryptIdentifier('900101300123'), valueMasked: '9001••••0123' },
        { type: 'DRIVER_LICENSE_NO', valueEncrypted: encryptIdentifier('AB1234567'), valueMasked: 'AB•••67' },
      ]),
    },
    auditLog: { create: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
  };
  const uploads: any = { getDocumentStream: jest.fn().mockResolvedValue({ stream: 'S', contentType: 'image/jpeg' }) };
  return { prisma, uploads, service: new DriverDocumentsService(prisma, uploads) };
}

const logist: any = { user: { id: 'u-logist', name: 'Ли', email: 'li@x' }, companyMember: { companyId: 'c1', fullName: 'Ли Вэй' }, driver: null };

describe('DriverDocumentsService', () => {
  beforeAll(() => {
    process.env.IDENTIFIER_KEY = process.env.IDENTIFIER_KEY || 'a'.repeat(64);
  });

  it('после подтверждения: ФИО, полный ИИН и номер прав, тягач и прицеп по порядку; открытие — в журнал', async () => {
    const { prisma, service } = setup(dealRow());
    const pkg = await service.package('deal1', logist);
    expect(pkg.driver).toMatchObject({ fullName: 'Ерлан Тестов', iin: '900101300123' });
    expect(pkg.license).toMatchObject({ number: 'AB1234567', expiryDate: '2031-05-01', document: { id: 'lic1' } });
    expect(pkg.vehicles.map((v) => v.id)).toEqual(['v1', 'v2']);
    expect(pkg.vehicles[0]).toMatchObject({ isVerified: false, passport: { id: 'pass1', status: 'PENDING' } });
    expect(prisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ actorUserId: 'u-logist', action: 'DRIVER_DOCS_VIEWED', entityType: 'Deal', entityId: 'deal1' }),
    });
  });

  it('чужая компания — 403', async () => {
    await expect(setup(dealRow({ companyId: 'other' })).service.package('deal1', logist)).rejects.toMatchObject({ response: { code: 'NOT_YOUR_DEAL' } });
  });

  it('до подтверждения водителем и после отмены — 403', async () => {
    await expect(setup(dealRow({ status: 'SELECTED' })).service.package('deal1', logist)).rejects.toMatchObject({ response: { code: 'DOCS_NOT_YET' } });
    await expect(setup(dealRow({ status: 'CANCELLED' })).service.package('deal1', logist)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('через 30 дней после доставки — 403, в пределах 30 дней — можно', async () => {
    const old = new Date(Date.now() - DOCS_AFTER_DELIVERY_MS - 60_000);
    await expect(setup(dealRow({ status: 'DELIVERED', deliveredAt: old })).service.package('deal1', logist)).rejects.toMatchObject({ response: { code: 'DOCS_EXPIRED' } });
    const recent = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000);
    await expect(setup(dealRow({ status: 'DELIVERED', deliveredAt: recent })).service.package('deal1', logist)).resolves.toBeDefined();
  });

  it('водитель пакет так не получает (только компания)', async () => {
    await expect(setup(dealRow()).service.package('deal1', { user: { id: 'u' }, driver: { id: 'd1' }, companyMember: null } as any)).rejects.toMatchObject({ response: { code: 'COMPANY_ONLY' } });
  });

  it('файл не из пакета этой сделки — 404, из пакета — поток', async () => {
    const { prisma, uploads, service } = setup(dealRow());
    prisma.verificationDocument.findUnique.mockResolvedValueOnce({ id: 'x', type: 'SELFIE', status: 'APPROVED', driverId: 'someone-else', vehicleId: null, fileUrl: 'k.jpg' });
    await expect(service.file('deal1', 'x', logist)).rejects.toBeInstanceOf(NotFoundException);
    prisma.deal.findUnique.mockResolvedValue(dealRow());
    prisma.verificationDocument.findUnique.mockResolvedValueOnce({ id: 'pass1', type: 'VEHICLE_PASSPORT', status: 'PENDING', driverId: null, vehicleId: 'v1', fileUrl: 'k.jpg' });
    await expect(service.file('deal1', 'pass1', logist)).resolves.toEqual({ stream: 'S', contentType: 'image/jpeg' });
    expect(uploads.getDocumentStream).toHaveBeenCalledWith('k.jpg');
  });

  it('историю открытий видит только водитель этой сделки', async () => {
    const { prisma, service } = setup(dealRow());
    prisma.auditLog.findMany.mockResolvedValue([{ createdAt: new Date('2030-01-01T10:00:00Z'), action: 'DRIVER_DOCS_VIEWED', actor: { name: 'Li', companyMember: { fullName: 'Ли Вэй' } } }]);
    await expect(service.accessLog('deal1', { user: { id: 'u' }, driver: { id: 'other' } } as any)).rejects.toBeInstanceOf(ForbiddenException);
    const log = await service.accessLog('deal1', { user: { id: 'u' }, driver: { id: 'd1' } } as any);
    expect(log).toEqual([{ at: new Date('2030-01-01T10:00:00Z'), action: 'DRIVER_DOCS_VIEWED', by: 'Ли Вэй' }]);
  });
});
