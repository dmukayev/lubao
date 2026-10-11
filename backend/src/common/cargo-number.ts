/// 062: короткий номер груза — «482 915» (группы по 3, так легче диктовать).
export function formatCargoNumber(number: number): string {
  return String(number).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
}

/// Номер сделки — номер груза + машина: «482 915-1».
export function formatDealNumber(cargoNumber: number, seq: number): string {
  return `${formatCargoNumber(cargoNumber)}-${seq}`;
}

/// Поиск по номеру: «482 915», «482915», «№ 482 915-1» → номер груза и
/// (если есть) машина; не похоже на номер — null.
export function parseCargoNumberQuery(raw: string): { number: number; seq: number | null } | null {
  const m = raw.replace(/[\s№#]|No\.?|编号/gi, '').match(/^(\d{6,7})(?:-(\d{1,3}))?$/);
  if (!m) return null;
  return { number: Number(m[1]), seq: m[2] != null ? Number(m[2]) : null };
}
