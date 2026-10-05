/// Задача 033 — «Свой размер»: объём и паллеты считаются из Д/Ш/В,
/// водитель ничего не перемножает.

const EURO_LONG_M = 1.2;
const EURO_SHORT_M = 0.8;

/// В раскладке «короткой стороной вдоль» ряды идут с шагом 0.8 без зазора —
/// посадка ровно впритык (13.6 / 0.8 = ровно 17) физически невозможна,
/// поэтому индустрия считает 33 паллеты для стандартных 13.6 м, а не 34.
/// 5 см — минимальный монтажный зазор на длину кузова для этой раскладки.
const TIGHT_FIT_CLEARANCE_M = 0.05;

export function calculatePalletsEuro(innerLengthM: number, innerWidthM: number): number {
  if (innerLengthM <= 0 || innerWidthM <= 0) return 0;
  const standard = Math.floor(innerLengthM / EURO_LONG_M) * Math.floor(innerWidthM / EURO_SHORT_M);
  const rotated = Math.floor((innerLengthM - TIGHT_FIT_CLEARANCE_M) / EURO_SHORT_M) * Math.floor(innerWidthM / EURO_LONG_M);
  return Math.max(standard, rotated, 0);
}

export function calculateVolumeM3(innerLengthM: number, innerWidthM: number, innerHeightM: number): number {
  if (innerLengthM <= 0 || innerWidthM <= 0 || innerHeightM <= 0) return 0;
  return Math.round(innerLengthM * innerWidthM * innerHeightM * 10) / 10;
}
