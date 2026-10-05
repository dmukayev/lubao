import 'reflect-metadata';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { AdminReasonDto, BlockUserDto, ResolveComplaintDto } from './admin.dto';

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
