/// 057 п.13: размер картинки — из заголовка, до разбора всего файла (защита
/// от «картинки-бомбы»: маленький файл, гигантские размеры → память).
export const MAX_AVATAR_PIXELS = 40_000_000;

export type ImageHeader =
  | { kind: 'png' | 'jpeg'; width: number; height: number }
  | { kind: 'heic' | 'webp' }
  | { kind: 'unknown' };

export function readImageHeader(b: Buffer): ImageHeader {
  // PNG: сигнатура + IHDR (ширина/высота — big-endian на 16..23).
  if (b.length >= 24 && b.readUInt32BE(0) === 0x89504e47 && b.readUInt32BE(4) === 0x0d0a1a0a) {
    return { kind: 'png', width: b.readUInt32BE(16), height: b.readUInt32BE(20) };
  }
  // JPEG: идём по маркерам до SOFn (кроме DHT C4, JPG C8, DAC CC).
  if (b.length >= 4 && b[0] === 0xff && b[1] === 0xd8) {
    let i = 2;
    while (i + 9 < b.length) {
      if (b[i] !== 0xff) {
        i++;
        continue;
      }
      const marker = b[i + 1];
      if (marker === 0xd8 || marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7) || marker === 0xff) {
        i += marker === 0xff ? 1 : 2;
        continue;
      }
      const len = b.readUInt16BE(i + 2);
      if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc) {
        return { kind: 'jpeg', height: b.readUInt16BE(i + 5), width: b.readUInt16BE(i + 7) };
      }
      if (len < 2) break;
      i += 2 + len;
    }
    return { kind: 'unknown' };
  }
  // HEIC: ISO BMFF «ftyp» + бренд heic/heix/mif1/msf1; WEBP: RIFF....WEBP.
  if (b.length >= 12 && b.toString('ascii', 4, 8) === 'ftyp' && /^(heic|heix|hevc|mif1|msf1|avif)$/.test(b.toString('ascii', 8, 12))) return { kind: 'heic' };
  if (b.length >= 12 && b.toString('ascii', 0, 4) === 'RIFF' && b.toString('ascii', 8, 12) === 'WEBP') return { kind: 'webp' };
  return { kind: 'unknown' };
}
