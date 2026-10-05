import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Cargo, Company } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ResponsesService } from '../responses/responses.service';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';
import { CloseCargoDto } from './dto/close-cargo.dto';

type CargoWithCompany = Cargo & { company: Company & { country: { code: string } }; publishedBy?: { id: string; name: string | null; phone: string | null } | null };

interface CargoContact {
  id: string;
  name: string | null;
  phone: string | null;
  wechatId: string | null;
}

@Injectable()
export class CargosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly responses: ResponsesService,
  ) {}

  /// Водитель звонит/пишет конкретному логисту, опубликовавшему груз, а не
  /// «компании» (decisions.md «Компания: проверка, роли, контакты», задача
  /// 012) — своё имя/телефон/WeChat у каждого сотрудника (CompanyMember.
  /// fullName/contactPhone/wechatId), не общий телефон компании. У грузов
  /// до задачи 017 нет `publishedByUserId` — откатываемся на владельца
  /// компании (самый старый `OWNER`). Пока сотрудник не заполнил «Мой
  /// профиль» — показываем то, что есть (User.name/phone), а не пусто.
  private async resolveContact(cargo: CargoWithCompany): Promise<CargoContact | null> {
    if (cargo.publishedBy) {
      const member = await this.prisma.companyMember.findFirst({ where: { userId: cargo.publishedBy.id } });
      return {
        id: cargo.publishedBy.id,
        name: member?.fullName ?? cargo.publishedBy.name,
        phone: member?.contactPhone ?? cargo.publishedBy.phone,
        wechatId: member?.wechatId ?? null,
      };
    }
    const owner = await this.prisma.companyMember.findFirst({
      where: { companyId: cargo.companyId, role: 'OWNER' },
      orderBy: { createdAt: 'asc' },
      include: { user: { select: { id: true, name: true, phone: true } } },
    });
    if (!owner) return null;
    return {
      id: owner.user.id,
      name: owner.fullName ?? owner.user.name,
      phone: owner.contactPhone ?? owner.user.phone,
      wechatId: owner.wechatId,
    };
  }

  async toDto(cargo: CargoWithCompany) {
    const companyCompletedDeals = await this.prisma.deal.count({
      where: { companyId: cargo.companyId, status: 'DELIVERED' },
    });
    const contact = await this.resolveContact(cargo);

    return {
      id: cargo.id,
      companyId: cargo.companyId,
      companyName: cargo.company.name,
      companyIsVerified: cargo.company.isVerified,
      companyRatingAvg: Number(cargo.company.ratingAvg),
      companyRatingCount: cargo.company.ratingCount,
      companyCompletedDeals,
      contactUserId: contact?.id ?? null,
      contactName: contact?.name ?? null,
      contactPhone: contact?.phone ?? null,
      contactWechatId: contact?.wechatId ?? null,
      // WhatsApp заблокирован в Китае — водителю показываем чат Lubao
      // вместо кнопки, которая всё равно не дойдёт до логиста (decisions.md
      // «Звонки — обычные, через телефон», 2026-10-05).
      isWhatsappBlocked: cargo.company.country.code === 'CN',
      pointId: cargo.pointId,
      destinationCountryId: cargo.destinationCountryId,
      destinationCityId: cargo.destinationCityId,
      bodyTypeId: cargo.bodyTypeId,
      weightKg: cargo.weightKg ? Number(cargo.weightKg) : null,
      volumeM3: cargo.volumeM3 ? Number(cargo.volumeM3) : null,
      photoUrls: cargo.photoUrls,
      price: Number(cargo.price),
      currency: cargo.currency,
      readyDate: cargo.readyDate,
      description: cargo.description,
      status: cargo.status,
      publishedAt: cargo.publishedAt,
      expiresAt: cargo.expiresAt,
      closeOutcome: cargo.closeOutcome,
      closedAt: cargo.closedAt,
    };
  }

  private get includeForDto() {
    return { company: { include: { country: { select: { code: true } } } }, publishedBy: { select: { id: true, name: true, phone: true } } } as const;
  }

  async feed() {
    // company.isBlocked (задача 026, п.5) — груз блокированной компании не
    // трогаем (статус/история не меняются), просто скрываем из ленты
    // водителя, пока компанию не разблокируют.
    const cargos = await this.prisma.cargo.findMany({
      where: { status: 'PUBLISHED', company: { isBlocked: false } },
      include: this.includeForDto,
      orderBy: { readyDate: 'asc' },
    });
    return Promise.all(cargos.map((c) => this.toDto(c)));
  }

  async mine(companyId: string) {
    const cargos = await this.prisma.cargo.findMany({
      where: { companyId },
      include: this.includeForDto,
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(cargos.map((c) => this.toDto(c)));
  }

  async byId(id: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id }, include: this.includeForDto });
    if (!cargo) throw new NotFoundException('Cargo not found');
    return this.toDto(cargo);
  }

  private async findEntity(id: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id }, include: this.includeForDto });
    if (!cargo) throw new NotFoundException('Cargo not found');
    return cargo;
  }

  async create(companyId: string, userId: string, companyIsVerified: boolean, dto: CreateCargoDto) {
    // Задача 012, п.4 — непроверенная компания может смотреть водителей на
    // точке и писать им, но не публиковать грузы (decisions.md «Компания:
    // проверка, роли, контакты»).
    if (!companyIsVerified) throw new ForbiddenException('COMPANY_NOT_VERIFIED');

    const point = await this.prisma.point.findFirstOrThrow({ where: { isActive: true } });
    const readyDate = new Date(dto.readyDate);
    const expiresAt = new Date(readyDate.getTime() + 48 * 60 * 60 * 1000);

    const cargo = await this.prisma.cargo.create({
      data: {
        companyId,
        publishedByUserId: userId,
        pointId: point.id,
        destinationCountryId: dto.destinationCountryId,
        destinationCityId: dto.destinationCityId,
        bodyTypeId: dto.bodyTypeId,
        weightKg: dto.weightKg,
        volumeM3: dto.volumeM3,
        photoUrls: dto.photoUrls ?? [],
        price: dto.price,
        currency: dto.currency,
        readyDate,
        description: dto.description,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        expiresAt,
      },
      include: this.includeForDto,
    });
    return this.toDto(cargo);
  }

  async assertOwnedBy(cargoId: string, companyId: string) {
    const cargo = await this.findEntity(cargoId);
    if (cargo.companyId !== companyId) {
      throw new NotFoundException('Cargo not found');
    }
    return cargo;
  }

  /// Задача 012, п.6 — логист видит все грузы компании (чтобы подменить
  /// коллегу), но редактирует/закрывает только свои; владелец — любые.
  /// decisions.md «Компания: проверка, роли, контакты».
  async assertCanEdit(cargoId: string, companyId: string, userId: string, role: string) {
    const cargo = await this.assertOwnedBy(cargoId, companyId);
    if (role !== 'OWNER' && cargo.publishedByUserId !== userId) {
      throw new ForbiddenException('Only the owner or the logist who published this cargo can edit it');
    }
    return cargo;
  }

  async update(companyId: string, userId: string, role: string, id: string, dto: UpdateCargoDto) {
    const existing = await this.assertCanEdit(id, companyId, userId, role);

    const readyDate = dto.readyDate ? new Date(dto.readyDate) : existing.readyDate;
    const expiresAt =
      dto.readyDate != null ? new Date(readyDate.getTime() + 48 * 60 * 60 * 1000) : existing.expiresAt;

    const cargo = await this.prisma.cargo.update({
      where: { id },
      data: {
        destinationCountryId: dto.destinationCountryId,
        destinationCityId: dto.destinationCityId,
        bodyTypeId: dto.bodyTypeId,
        weightKg: dto.weightKg,
        volumeM3: dto.volumeM3,
        photoUrls: dto.photoUrls,
        price: dto.price,
        currency: dto.currency,
        readyDate,
        expiresAt,
        description: dto.description,
      },
      include: this.includeForDto,
    });
    return this.toDto(cargo);
  }

  /// Кандидаты на «Нашёл в Lubao» (задача 017, п.6) — водители, с кем уже
  /// был хоть какой-то контакт по этому грузу: отклик, звонок/WhatsApp или
  /// переписка. Объединяем по `driverId`, помечаем источник для UI.
  async closeCandidates(companyId: string, cargoId: string) {
    await this.assertOwnedBy(cargoId, companyId);

    const [responses, contactEvents, chats] = await Promise.all([
      this.prisma.response.findMany({ where: { cargoId }, select: { driverId: true, driver: { select: { fullName: true } } } }),
      this.prisma.contactEvent.findMany({ where: { cargoId }, select: { driverId: true, driver: { select: { fullName: true } } } }),
      this.prisma.chat.findMany({ where: { cargoId }, select: { driverId: true, driver: { select: { fullName: true } } } }),
    ]);

    const byDriver = new Map<string, { driverId: string; driverName: string }>();
    for (const r of [...responses, ...contactEvents, ...chats]) {
      byDriver.set(r.driverId, { driverId: r.driverId, driverName: r.driver.fullName });
    }
    return [...byDriver.values()];
  }

  /// Закрыть груз только через выбор исхода (задача 017, п.6) — заменяет
  /// старое «удаление» без причины. «Нашёл в Lubao» выбирает водителя и
  /// создаёт сделку тем же путём, что и приглашение/выбор отклика
  /// (`ResponsesService`) — не дублируем логику транзакции.
  async closeCargo(companyId: string, userId: string, role: string, id: string, dto: CloseCargoDto) {
    const cargo = await this.assertCanEdit(id, companyId, userId, role);
    if (cargo.status !== 'PUBLISHED') throw new BadRequestException('This cargo is already closed');

    if (dto.outcome === 'FOUND_IN_APP') {
      if (!dto.driverId) throw new BadRequestException('driverId is required for outcome=FOUND_IN_APP');
      // Если ответ этого водителя уже SELECTED (сделку создали обычным путём
      // раньше, через отклик/приглашение) — сделка уже есть, повторный
      // inviteDriver только упадёт конфликтом. Закрываем груз без повтора.
      const existingResponse = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId: id, driverId: dto.driverId } } });
      if (existingResponse?.status !== 'SELECTED') {
        await this.responses.inviteDriver(id, dto.driverId, companyId);
      }
    }

    await this.prisma.cargo.update({
      where: { id },
      data: { status: 'CANCELLED', closeOutcome: dto.outcome, closedAt: new Date() },
    });
  }
}
