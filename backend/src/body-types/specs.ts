import { BadRequestException } from '@nestjs/common';
import type { BodyField } from '../../prisma/body-type-profiles';

export type SpecsTarget = 'vehicle' | 'cargo' | 'preferred';
export type Specs = Record<string, number | string | boolean | string[]>;

/// Поля типа кузова из справочника (JSON) — с защитой от мусора в данных админки.
export function bodyFields(json: unknown): BodyField[] {
  return Array.isArray(json) ? (json.filter((f) => f && typeof f.key === 'string' && typeof f.kind === 'string') as BodyField[]) : [];
}

function fieldsFor(fields: BodyField[], target: SpecsTarget): BodyField[] {
  if (target === 'cargo') return fields.filter((f) => f.forCargo);
  if (target === 'preferred') return fields.filter((f) => f.forVehicle && f.primary);
  return fields.filter((f) => f.forVehicle);
}

/// Проверка и нормализация `specs` по полям типа кузова (048 п.2): только
/// известные ключи для машины/груза, типы, диапазоны, варианты; обязательные —
/// кроме «предпочтения» из регистрации (там всё необязательно). Ошибки — списком.
export function validateSpecs(fieldsJson: unknown, input: unknown, target: SpecsTarget): Specs {
  const fields = fieldsFor(bodyFields(fieldsJson), target);
  const raw = input && typeof input === 'object' && !Array.isArray(input) ? (input as Record<string, unknown>) : {};
  const out: Specs = {};
  const errors: string[] = [];
  for (const f of fields) {
    const value = raw[f.key];
    if (value === undefined || value === null || value === '') {
      if (f.required && target !== 'preferred') errors.push(`${f.key}: required`);
      continue;
    }
    switch (f.kind) {
      case 'number': {
        const n = typeof value === 'number' ? value : Number(value);
        if (!Number.isFinite(n)) errors.push(`${f.key}: number expected`);
        else if ((f.min != null && n < f.min) || (f.max != null && n > f.max)) errors.push(`${f.key}: out of range ${f.min ?? ''}..${f.max ?? ''}`);
        else out[f.key] = n;
        break;
      }
      case 'bool':
        if (typeof value !== 'boolean') errors.push(`${f.key}: boolean expected`);
        else out[f.key] = value;
        break;
      case 'enum': {
        const codes = (f.options ?? []).map((o) => o.code);
        if (typeof value !== 'string' || !codes.includes(value)) errors.push(`${f.key}: one of ${codes.join(',')}`);
        else out[f.key] = value;
        break;
      }
      case 'multi': {
        const codes = (f.options ?? []).map((o) => o.code);
        const list = Array.isArray(value) ? value : [value];
        if (list.length === 0 || !list.every((v) => typeof v === 'string' && codes.includes(v))) errors.push(`${f.key}: subset of ${codes.join(',')}`);
        else out[f.key] = [...new Set(list as string[])];
        break;
      }
    }
  }
  if (errors.length) throw new BadRequestException({ code: 'INVALID_SPECS', message: 'Invalid body specs', errors });
  return out;
}

/// Объёмный кузов: колонки 033/037 — проекция specs (и наоборот для старых клиентов).
export const VOLUME_COLUMN_KEYS = ['capacityTons', 'volumeM3', 'palletsEuro', 'innerLengthM', 'innerWidthM', 'innerHeightM'] as const;
