import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { assertIdentifierCryptoConfigured, decryptIdentifier, encryptIdentifier, hashIdentifier, isSensitiveIdentifierType, maskIdentifier } from './crypto';
import { IdentifierTypeValue, normalizeIdentifier } from './normalize';

type OwnerType = 'DRIVER' | 'COMPANY' | 'VEHICLE';

export interface MatchResult {
  /// Совпадение с чёрным списком — проверка не может быть молча
  /// подтверждена (задача 031, п.15).
  blocked: { reason: string; blockedAt: Date } | null;
  /// Тот же идентификатор уже подтверждён у другого активного владельца —
  /// просто предупреждение (для госномера это нормально при перепродаже
  /// машины).
  duplicateOwner: { ownerType: OwnerType; ownerId: string } | null;
}

/// Задача 031, этап C — идентификаторы (ИИН, номер прав, VIN, госномер,
/// БИН/统一社会信用代码, телефон) и чёрный список по ним, а не по аккаунту.
/// Распознавание (этап D) и админка (этап E) используют этот сервис как
/// единственную точку входа для подтверждения/проверки/блокировки.
@Injectable()
export class IdentifiersService {
  constructor(private readonly prisma: PrismaService) {
    assertIdentifierCryptoConfigured();
  }

  /// Что сейчас известно про значение ДО подтверждения — вызывается при
  /// регистрации (телефон), после распознавания (этап D) и при ручном
  /// вводе админом, до того как что-либо записано в identifiers.
  async checkMatches(type: IdentifierTypeValue, rawValue: string, exclude?: { ownerType: OwnerType; ownerId: string }): Promise<MatchResult> {
    const normalized = normalizeIdentifier(type, rawValue);
    const valueHash = hashIdentifier(normalized);

    const [blocked, duplicate] = await Promise.all([
      this.prisma.blockedIdentifier.findFirst({
        where: { type, valueHash, liftedAt: null },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.identifier.findFirst({
        where: {
          type,
          valueHash,
          ...(exclude ? { NOT: { ownerType: exclude.ownerType, ownerId: exclude.ownerId } } : {}),
        },
      }),
    ]);

    return {
      blocked: blocked ? { reason: blocked.reason, blockedAt: blocked.createdAt } : null,
      duplicateOwner: duplicate ? { ownerType: duplicate.ownerType as OwnerType, ownerId: duplicate.ownerId } : null,
    };
  }

  /// Подтверждение значения админом (при одобрении документа — этап A/E —
  /// или вручную): перезаписывает предыдущее подтверждённое значение этого
  /// типа у этого владельца.
  /// `tx` — задача 032, п.10 (038): при одобрении документа запись
  /// идентификатора идёт в той же транзакции, что и сам документ.
  async confirmIdentifier(
    params: {
      type: IdentifierTypeValue;
      rawValue: string;
      ownerType: OwnerType;
      ownerId: string;
      sourceDocumentId?: string | null;
      confirmedByUserId: string;
    },
    tx?: Prisma.TransactionClient,
  ) {
    const normalized = normalizeIdentifier(params.type, params.rawValue);
    const valueHash = hashIdentifier(normalized);
    const valueMasked = maskIdentifier(params.type, normalized);
    const valueEncrypted = isSensitiveIdentifierType(params.type) ? encryptIdentifier(normalized) : null;

    return (tx ?? this.prisma).identifier.upsert({
      where: { ownerType_ownerId_type: { ownerType: params.ownerType, ownerId: params.ownerId, type: params.type } },
      update: {
        valueHash,
        valueMasked,
        valueEncrypted,
        sourceDocumentId: params.sourceDocumentId ?? null,
        confirmedByUserId: params.confirmedByUserId,
        confirmedAt: new Date(),
      },
      create: {
        type: params.type,
        valueHash,
        valueMasked,
        valueEncrypted,
        ownerType: params.ownerType,
        ownerId: params.ownerId,
        sourceDocumentId: params.sourceDocumentId ?? null,
        confirmedByUserId: params.confirmedByUserId,
        confirmedAt: new Date(),
      },
    });
  }

  async listForOwner(ownerType: OwnerType, ownerId: string) {
    return this.prisma.identifier.findMany({ where: { ownerType, ownerId }, orderBy: { type: 'asc' } });
  }

  /// Задача 032, п.2 — финальная проверка перед «Подтвердить»: среди ВСЕХ
  /// уже подтверждённых идентификаторов этого владельца есть ли активная
  /// (не снятая) блокировка. В отличие от проверки в момент одобрения
  /// ОДНОГО документа (reviewVerificationDocument), здесь видно совпадение,
  /// даже если заблокированный идентификатор подтвердился другим,
  /// давно одобренным документом — обойти обычной кнопкой «Подтвердить»
  /// больше нельзя.
  async findActiveBlocksForOwner(ownerType: OwnerType, ownerId: string): Promise<Array<{ type: IdentifierTypeValue; valueMasked: string; reason: string }>> {
    const confirmed = await this.listForOwner(ownerType, ownerId);
    if (confirmed.length === 0) return [];
    const blocks = await Promise.all(
      confirmed.map(async (identifier) => {
        const blocked = await this.prisma.blockedIdentifier.findFirst({
          where: { type: identifier.type, valueHash: identifier.valueHash, liftedAt: null },
          orderBy: { createdAt: 'desc' },
        });
        return blocked ? { type: identifier.type as IdentifierTypeValue, valueMasked: identifier.valueMasked, reason: blocked.reason } : null;
      }),
    );
    return blocks.filter((b): b is { type: IdentifierTypeValue; valueMasked: string; reason: string } => b !== null);
  }

  /// История блокировок этого владельца (задача 031, п.24 — карточка
  /// «Идентификаторы») — только блоки, завязанные НА НЕГО (sourceOwnerType/
  /// sourceOwnerId), не все блоки с совпадающим значением у кого угодно.
  async listBlockHistory(ownerType: OwnerType, ownerId: string) {
    return this.prisma.blockedIdentifier.findMany({
      where: { sourceOwnerType: ownerType, sourceOwnerId: ownerId },
      orderBy: { createdAt: 'desc' },
      include: {
        blockedBy: { select: { name: true, email: true } },
        liftedBy: { select: { name: true, email: true } },
      },
    });
  }

  /// Полное значение — только по явной кнопке, с записью в журнал
  /// (задача 031, п.16). Не-чувствительные типы не шифруются — для них
  /// нормализованное значение совпадает с маской, раскрывать нечего.
  async revealIdentifier(identifierId: string, adminUserId: string): Promise<string | null> {
    const row = await this.prisma.identifier.findUnique({ where: { id: identifierId } });
    if (!row || !row.valueEncrypted) return null;

    return this.decryptAndAudit(row.valueEncrypted, adminUserId, 'IDENTIFIER_REVEALED', 'Identifier', identifierId, {
      type: row.type,
      ownerType: row.ownerType,
      ownerId: row.ownerId,
    });
  }

  /// Та же пара «расшифровать + записать в журнал», что и у
  /// [revealIdentifier], но для значения, которое ещё не подтверждено как
  /// identifiers-строка — распознанное, но не одобренное поле документа
  /// (задача 032, п.4). `entityType`/`entityId`/`metadata` описывают, ЧТО
  /// именно раскрыли, чтобы audit_log было по чему искать.
  async decryptAndAudit(
    valueEncrypted: string,
    adminUserId: string,
    action: string,
    entityType: string,
    entityId: string,
    metadata: Prisma.InputJsonValue,
  ): Promise<string> {
    const value = decryptIdentifier(valueEncrypted);
    await this.prisma.auditLog.create({
      data: { actorUserId: adminUserId, action, entityType, entityId, metadata },
    });
    return value;
  }

  /// Блокирует все подтверждённые идентификаторы владельца (по умолчанию —
  /// все; types сужает список для галочек в будущей админ-форме, задача
  /// 031, п.14). Идемпотентно — уже активно заблокированное значение не
  /// дублируется.
  async blockOwnerIdentifiers(params: {
    ownerType: OwnerType;
    ownerId: string;
    reason: string;
    blockedByUserId: string;
    types?: IdentifierTypeValue[];
  }) {
    const identifiers = await this.prisma.identifier.findMany({
      where: { ownerType: params.ownerType, ownerId: params.ownerId, ...(params.types ? { type: { in: params.types } } : {}) },
    });
    if (identifiers.length === 0) return [];

    const created = [];
    for (const identifier of identifiers) {
      const alreadyBlocked = await this.prisma.blockedIdentifier.findFirst({
        where: { type: identifier.type, valueHash: identifier.valueHash, liftedAt: null },
      });
      if (alreadyBlocked) continue;
      created.push(
        await this.prisma.blockedIdentifier.create({
          data: {
            type: identifier.type,
            valueHash: identifier.valueHash,
            valueMasked: identifier.valueMasked,
            reason: params.reason,
            blockedByUserId: params.blockedByUserId,
            sourceOwnerType: params.ownerType,
            sourceOwnerId: params.ownerId,
          },
        }),
      );
    }
    return created;
  }

  /// Снимает блокировки, заведённые из-за этого конкретного владельца
  /// (задача 031, п.14 — «разблокировка снимает и их»). Не трогает записи,
  /// заблокированные независимо для другого владельца с тем же значением.
  async liftOwnerIdentifierBlocks(params: { ownerType: OwnerType; ownerId: string; reason: string; liftedByUserId: string }) {
    return this.prisma.blockedIdentifier.updateMany({
      where: { sourceOwnerType: params.ownerType, sourceOwnerId: params.ownerId, liftedAt: null },
      data: { liftedAt: new Date(), liftedByUserId: params.liftedByUserId, liftReason: params.reason },
    });
  }

  /// Гараж целиком (задача 031, п.14 — «VIN/госномера машин») — все
  /// Vehicle-идентификаторы водителя, не только сам водитель.
  async blockDriverAndVehicles(params: { driverId: string; vehicleIds: string[]; reason: string; blockedByUserId: string }) {
    const [driverBlocked, ...vehicleBlocked] = await Promise.all([
      this.blockOwnerIdentifiers({ ownerType: 'DRIVER', ownerId: params.driverId, reason: params.reason, blockedByUserId: params.blockedByUserId }),
      ...params.vehicleIds.map((vehicleId) =>
        this.blockOwnerIdentifiers({ ownerType: 'VEHICLE', ownerId: vehicleId, reason: params.reason, blockedByUserId: params.blockedByUserId }),
      ),
    ]);
    return [...driverBlocked, ...vehicleBlocked.flat()];
  }

  async liftDriverAndVehicles(params: { driverId: string; vehicleIds: string[]; reason: string; liftedByUserId: string }) {
    await Promise.all([
      this.liftOwnerIdentifierBlocks({ ownerType: 'DRIVER', ownerId: params.driverId, reason: params.reason, liftedByUserId: params.liftedByUserId }),
      ...params.vehicleIds.map((vehicleId) =>
        this.liftOwnerIdentifierBlocks({ ownerType: 'VEHICLE', ownerId: vehicleId, reason: params.reason, liftedByUserId: params.liftedByUserId }),
      ),
    ]);
  }
}
