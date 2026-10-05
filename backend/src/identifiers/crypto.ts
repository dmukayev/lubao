import * as crypto from 'crypto';
import { IdentifierTypeValue } from './normalize';

/// Задача 031, этап C, п.11/16 — valueHash для поиска совпадений без
/// хранения открытого текста; valueEncrypted — обратимое шифрование,
/// только для ИИН/номера прав (п.16: полное значение — по кнопке в
/// админке, с записью в audit_log); остальные типы не настолько
/// чувствительны и хранятся в открытую как valueMasked.
const SENSITIVE_TYPES = new Set<IdentifierTypeValue>(['IIN', 'DRIVER_LICENSE_NO']);

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

/// Задача 031, этап F, п.27 — без ключей сервер не должен стартовать
/// (тот же принцип, что и у JWT_ACCESS_SECRET в TokenService): дешевле
/// упасть при деплое, чем молча хранить идентификаторы без защиты.
export function assertIdentifierCryptoConfigured(): void {
  requiredEnv('IDENTIFIER_PEPPER');
  requiredEnv('IDENTIFIER_KEY');
}

export function isSensitiveIdentifierType(type: IdentifierTypeValue): boolean {
  return SENSITIVE_TYPES.has(type);
}

export function hashIdentifier(normalizedValue: string): string {
  const pepper = requiredEnv('IDENTIFIER_PEPPER');
  return crypto.createHmac('sha256', pepper).update(normalizedValue).digest('hex');
}

/// AES-256-GCM — ключ 32 байта из hex в IDENTIFIER_KEY. Пакуем
/// iv(12б):authTag(16б):ciphertext в одну base64-строку, чтобы хранить
/// одной колонкой.
export function encryptIdentifier(normalizedValue: string): string {
  const key = Buffer.from(requiredEnv('IDENTIFIER_KEY'), 'hex');
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const ciphertext = Buffer.concat([cipher.update(normalizedValue, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return Buffer.concat([iv, authTag, ciphertext]).toString('base64');
}

export function decryptIdentifier(packed: string): string {
  const key = Buffer.from(requiredEnv('IDENTIFIER_KEY'), 'hex');
  const buf = Buffer.from(packed, 'base64');
  const iv = buf.subarray(0, 12);
  const authTag = buf.subarray(12, 28);
  const ciphertext = buf.subarray(28);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
}

/// ИИН/номер прав — первые и последние 4 символа, середина скрыта
/// («8507••••1234»); остальные типы (госномер, VIN, БИН/统一社会信用代码,
/// телефон) не настолько чувствительны и показываются полностью — они и
/// так публичны (номер на борту машины, телефон уже виден в профиле).
export function maskIdentifier(type: IdentifierTypeValue, normalizedValue: string): string {
  if (!isSensitiveIdentifierType(type)) return normalizedValue;
  const len = normalizedValue.length;
  if (len <= 6) return '•'.repeat(len);
  const visible = 4;
  const head = normalizedValue.slice(0, visible);
  const tail = normalizedValue.slice(len - visible);
  const maskedLen = Math.max(len - visible * 2, 4);
  return `${head}${'•'.repeat(maskedLen)}${tail}`;
}
