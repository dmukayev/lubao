import { BodyTypeProfile } from '@prisma/client';

type Specs = Record<string, unknown> | null | undefined;

export interface DriverBody {
  profile: BodyTypeProfile | null;
  capacityTons: number | null;
  volumeM3: number | null;
  palletsEuro: number | null;
  specs: Specs;
}

export interface CargoBody {
  profiles: BodyTypeProfile[];
  weightKg: unknown;
  volumeM3: unknown;
  palletCount: number | null;
  specs: Specs;
}

const num = (v: unknown) => (v == null || v === '' ? null : Number(v));

/// Подходит ли груз машине водителя (048 п.5): кузов — по профилю (тенту не
/// показываем груз для цистерны); вес — всегда; м³/паллеты — только объёмным;
/// литры и продукт — цистерне; число машин — автовозу; тип — контейнеровозу.
/// Чего-то не знаем (машина без параметров) — не прячем.
export function cargoFitsBody(cargo: CargoBody, body: DriverBody): boolean {
  if (body.profile && cargo.profiles.length && !cargo.profiles.includes(body.profile)) return false;
  const weight = num(cargo.weightKg);
  if (weight != null && body.capacityTons != null && weight > body.capacityTons * 1000) return false;
  const profile = body.profile ?? 'VOLUME';
  const c = cargo.specs ?? {};
  const v = body.specs ?? {};
  switch (profile) {
    case 'VOLUME': {
      const volume = num(cargo.volumeM3);
      if (volume != null && body.volumeM3 != null && volume > body.volumeM3) return false;
      if (cargo.palletCount != null && body.palletsEuro != null && cargo.palletCount > body.palletsEuro) return false;
      return true;
    }
    case 'TANK': {
      if (c.cargoProduct && v.product && c.cargoProduct !== v.product) return false;
      const liters = num(c.cargoLiters);
      const capacity = num(v.liters);
      return !(liters != null && capacity != null && liters > capacity);
    }
    case 'CAR_CARRIER': {
      const cars = num(c.carCount);
      const slots = num(v.carSlots);
      return !(cars != null && slots != null && cars > slots);
    }
    case 'CONTAINER': {
      const types = Array.isArray(v.containerTypes) ? (v.containerTypes as string[]) : null;
      return !(typeof c.containerType === 'string' && types && !types.includes(c.containerType));
    }
    default:
      return true;
  }
}
