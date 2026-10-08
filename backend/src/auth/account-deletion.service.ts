import { ConflictException, ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { DealStatus, IdentifierOwnerType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';

const ACTIVE_DEAL_STATUSES: DealStatus[] = ['SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'CANCEL_REQUESTED', 'DISPUTED'];

/// Имя-заглушка вместо ФИО удалённого водителя: `Driver.fullName` NOT NULL,
/// а сделки и отзывы остаются (043 п.1) — клиенты показывают его как есть.
export const DELETED_NAME = '—';

/// Удаление аккаунта самим пользователем (043 п.1, требование сторов и закона
/// о ПДн): имя/телефон/email → заглушки, документы (файлы и строки) и
/// идентификаторы удаляются, сделки/отзывы/чаты остаются обезличенными,
/// все сессии отзываются. Чёрный список (`blocked_identifiers`) не трогаем —
/// иначе удаление было бы способом обойти блокировку.
@Injectable()
export class AccountDeletionService {
  private readonly logger = new Logger(AccountDeletionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: UploadsService,
  ) {}

  async deleteAccount(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { driver: { include: { vehicles: { select: { id: true } } } }, companyMember: true },
    });
    if (!user || user.deletedAt) throw new NotFoundException('Account not found');
    if (user.role === 'ADMIN') throw new ForbiddenException('Admin accounts are removed by another admin');

    const driver = user.driver;
    const member = user.companyMember;
    const isOwner = member?.role === 'OWNER';

    if (isOwner) {
      const others = await this.prisma.companyMember.count({ where: { companyId: member.companyId, userId: { not: userId } } });
      if (others > 0) {
        throw new ConflictException({ code: 'OWNER_HAS_MEMBERS', message: 'Transfer ownership or remove employees first' });
      }
    }
    if (driver || isOwner) {
      const activeDeals = await this.prisma.deal.count({
        where: {
          status: { in: ACTIVE_DEAL_STATUSES },
          OR: [...(driver ? [{ driverId: driver.id }] : []), ...(isOwner ? [{ companyId: member.companyId }] : [])],
        },
      });
      if (activeDeals > 0) {
        throw new ConflictException({ code: 'ACTIVE_DEALS', message: 'Finish or cancel active deals first' });
      }
    }

    const vehicleIds = driver?.vehicles.map((v) => v.id) ?? [];
    const documentWhere: Prisma.VerificationDocumentWhereInput = {
      OR: [
        { userId },
        ...(driver ? [{ driverId: driver.id }] : []),
        ...(vehicleIds.length ? [{ vehicleId: { in: vehicleIds } }] : []),
        // Документы компании — только если удаляется её единственный участник.
        ...(isOwner ? [{ companyId: member.companyId }] : []),
      ],
    };
    const documents = await this.prisma.verificationDocument.findMany({ where: documentWhere, select: { id: true, fileUrl: true } });
    const documentIds = documents.map((d) => d.id);
    const identifierOwners: Prisma.IdentifierWhereInput[] = [
      ...(driver ? [{ ownerType: IdentifierOwnerType.DRIVER, ownerId: driver.id }] : []),
      ...(vehicleIds.length ? [{ ownerType: IdentifierOwnerType.VEHICLE, ownerId: { in: vehicleIds } }] : []),
      ...(isOwner ? [{ ownerType: IdentifierOwnerType.COMPANY, ownerId: member.companyId }] : []),
      ...(documentIds.length ? [{ sourceDocumentId: { in: documentIds } }] : []),
    ];
    const now = new Date();

    await this.prisma.$transaction(async (tx) => {
      if (identifierOwners.length) await tx.identifier.deleteMany({ where: { OR: identifierOwners } });
      if (documentIds.length) {
        await tx.documentRecognition.deleteMany({ where: { documentId: { in: documentIds } } });
        await tx.verificationDocument.deleteMany({ where: { id: { in: documentIds } } });
      }
      await tx.deviceToken.deleteMany({ where: { userId } });
      await tx.session.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: now } });
      await tx.user.update({
        where: { id: userId },
        data: { phone: null, email: null, passwordHash: null, name: null, emailVerifiedAt: null, isActive: false, deletedAt: now },
      });
      if (driver) {
        await tx.driver.update({
          where: { id: driver.id },
          data: { fullName: DELETED_NAME, isVerified: false, currentLat: null, currentLng: null, locationUpdatedAt: null },
        });
        await tx.vehicle.updateMany({ where: { driverId: driver.id }, data: { plateNumber: null, vin: null, isActive: false, isVerified: false } });
        await tx.arrival.updateMany({ where: { driverId: driver.id, status: { in: ['PLANNED', 'ON_SITE'] } }, data: { status: 'CANCELLED' } });
        await tx.response.updateMany({ where: { driverId: driver.id, status: { in: ['INVITED', 'PENDING'] } }, data: { status: 'CANCELLED' } });
      }
      if (member) {
        await tx.companyMember.update({ where: { id: member.id }, data: { fullName: null, contactPhone: null, wechatId: null } });
      }
      if (isOwner) {
        await tx.company.update({ where: { id: member.companyId }, data: { wecomWebhookUrl: null } });
        await tx.cargo.updateMany({
          where: { companyId: member.companyId, status: 'PUBLISHED' },
          data: { status: 'CANCELLED', closeOutcome: 'CARGO_CANCELLED', closedAt: now },
        });
      }
      await tx.auditLog.create({
        data: { actorUserId: userId, action: 'ACCOUNT_DELETED', entityType: 'User', entityId: userId, metadata: { role: user.role, documents: documentIds.length } },
      });
    });

    // Файлы — после коммита: если транзакция упала, документы должны остаться
    // целыми. Не удалившийся файл — в лог (только число, без ключей).
    let failed = 0;
    for (const doc of documents) {
      try {
        await this.uploads.removeDocument(doc.fileUrl);
      } catch {
        failed += 1;
      }
    }
    if (failed) this.logger.warn(`Account deletion: ${failed} document file(s) were not removed from storage`);
  }
}
