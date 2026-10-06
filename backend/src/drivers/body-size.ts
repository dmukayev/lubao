/// Задача 033 — «Свой размер»: объём и паллеты считаются из Д/Ш/В,
/// водитель ничего не перемножает.

const EURO_LONG_M = 1.2;
const EURO_SHORT_M = 0.8;

/// В раскладке «короткой стороной вдоль» ряды идут с шагом 0.8 без зазора —
/// посадка ровно впритык (13.6 / 0.8 = ровно 17) физически невозможна,
/// поэтому индустрия считает 33 паллеты для стандартных 13.6 м, а не 34.
/// 5 см — минимальный монтажный зазор на длину кузова для этой раскладки.
const TIGHT_FIT_CLEARANCE_M = 0.05;

/// Плавающая точка: 2.4 / 0.8 = 2.999999…96, и floor терял целый ряд
/// паллет при ширине 2,40 м (задача 038, п.5). Эпсилон меньше любого
/// осмысленного зазора (1 нм), но съедает ошибку представления double.
const FLOAT_EPSILON = 1e-9;

function floorDiv(a: number, b: number): number {
  return Math.floor(a / b + FLOAT_EPSILON);
}

export function calculatePalletsEuro(innerLengthM: number, innerWidthM: number): number {
  if (innerLengthM <= 0 || innerWidthM <= 0) return 0;
  const standard = floorDiv(innerLengthM, EURO_LONG_M) * floorDiv(innerWidthM, EURO_SHORT_M);
  const rotated = floorDiv(innerLengthM - TIGHT_FIT_CLEARANCE_M, EURO_SHORT_M) * floorDiv(innerWidthM, EURO_LONG_M);
  return Math.max(standard, rotated, 0);
}

export function calculateVolumeM3(innerLengthM: number, innerWidthM: number, innerHeightM: number): number {
  if (innerLengthM <= 0 || innerWidthM <= 0 || innerHeightM <= 0) return 0;
  return Math.round(innerLengthM * innerWidthM * innerHeightM * 10) / 10;
}
