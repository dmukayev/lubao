import 'reflect-metadata';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import {
  AdminReasonDto,
  BlockUserDto,
  CreateBodySizePresetDto,
  CreateBodyTypeDto,
  CreatePermitDto,
  CreatePointDto,
  ResolveComplaintDto,
} from './admin.dto';

/// Задача 029, п.18 — пустая причина проходила валидацию (@IsString()
/// принимает ''). Проверяем на нескольких реальных DTO, у которых причина
/// обязательна, что теперь это не так.
describe('Admin reason/resolutionNote DTOs reject empty strings (задача 029, п.18)', () => {
  it('BlockUserDto rejects an empty reason', async () => {
    const errors = await validate(plainToInstance(BlockUserDto, { reason: '' }));
    expect(errors.length).toBeGreaterThan(0);
  });

  it('BlockUserDto rejects a reason over 1000 characters', async () => {
    const errors = await validate(plainToInstance(BlockUserDto, { reason: 'x'.repeat(1001) }));
    expect(errors.length).toBeGreaterThan(0);
  });

  it('BlockUserDto accepts a normal reason', async () => {
    const errors = await validate(plainToInstance(BlockUserDto, { reason: 'Грубость по телефону' }));
    expect(errors).toHaveLength(0);
  });

  it('AdminReasonDto rejects an empty reason', async () => {
    const errors = await validate(plainToInstance(AdminReasonDto, { reason: '' }));
    expect(errors.length).toBeGreaterThan(0);
  });

  it('ResolveComplaintDto rejects an empty resolutionNote', async () => {
    const errors = await validate(plainToInstance(ResolveComplaintDto, { resolution: 'DISMISSED', resolutionNote: '' }));
    expect(errors.length).toBeGreaterThan(0);
  });
});

/// Задача 038, п.4 — у `name` в Create*-DTO не было НИ ОДНОГО декоратора:
/// глобальный `whitelist: true` вырезал поле целиком, и создание любого
/// справочника падало 500 (TypeError на undefined.name в сервисе).
/// Проверяем «как ValidationPipe»: whitelist + validate.
describe('Create reference DTOs keep and validate the i18n name (задача 038, п.4)', () => {
  const validName = { kk: 'Тент', ru: 'Тент', zh: '篷布', en: 'Tent' };

  async function pipeLike<T extends object>(cls: new () => T, payload: object): Promise<{ dto: T; errors: unknown[] }> {
    const dto = plainToInstance(cls, payload) as T;
    const errors = await validate(dto, { whitelist: true });
    return { dto, errors };
  }

  it('CreateBodyTypeDto keeps name through whitelist and accepts a valid payload', async () => {
    const { dto, errors } = await pipeLike(CreateBodyTypeDto, { code: 'TENT', name: validName });
    expect(errors).toHaveLength(0);
    expect((dto as CreateBodyTypeDto).name).toMatchObject(validName);
  });

  it('CreateBodyTypeDto rejects a missing name instead of 500', async () => {
    const { errors } = await pipeLike(CreateBodyTypeDto, { code: 'TENT' });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('CreateBodyTypeDto rejects a non-object name', async () => {
    const { errors } = await pipeLike(CreateBodyTypeDto, { code: 'TENT', name: 'просто строка' });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('CreatePermitDto accepts a valid payload', async () => {
    const { dto, errors } = await pipeLike(CreatePermitDto, { code: 'TIR', name: validName });
    expect(errors).toHaveLength(0);
    expect((dto as CreatePermitDto).name).toMatchObject(validName);
  });

  it('CreatePointDto accepts a valid payload and rejects a missing name', async () => {
    const ok = await pipeLike(CreatePointDto, { cityId: 'city-1', name: validName });
    expect(ok.errors).toHaveLength(0);
    const bad = await pipeLike(CreatePointDto, { cityId: 'city-1' });
    expect(bad.errors.length).toBeGreaterThan(0);
  });

  it('CreateBodySizePresetDto accepts a valid payload and validates nested name fields', async () => {
    const ok = await pipeLike(CreateBodySizePresetDto, { code: 'MEGA', name: validName, innerLengthM: 13.6 });
    expect(ok.errors).toHaveLength(0);
    const bad = await pipeLike(CreateBodySizePresetDto, { code: 'MEGA', name: { kk: 1, ru: 2, zh: 3 } });
    expect(bad.errors.length).toBeGreaterThan(0);
  });
});
