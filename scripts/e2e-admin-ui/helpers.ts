import { expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

export const API = process.env.E2E_API_URL ?? 'http://localhost:3100';
export const ADMIN = { email: 'e2e-admin@lubao-test.kz', password: 'E2eLubao2026!' };
const SHOT_DIR = process.env.E2E_SHOT_DIR ?? path.resolve('shots');
const DEVICE = process.env.E2E_DEVICE ?? 'device';

/// Шаг сценария: скриншот после него (и при падении) + строка в steps.jsonl —
/// тот же формат, что у Flutter-сценариев, поэтому один отчёт.
export class Steps {
  private n = 0;
  constructor(private page: Page, private scenario: string) {}

  async step(name: string, body: () => Promise<void>): Promise<void> {
    this.n += 1;
    const id = `${String(this.n).padStart(2, '0')}-${name}`;
    try {
      await body();
    } catch (error) {
      const shot = await this.shoot(`${id}-FAIL`);
      this.record(id, false, shot, String(error).split('\n').slice(0, 3).join(' '));
      throw error;
    }
    this.record(id, true, await this.shoot(id), null);
  }

  private async shoot(name: string): Promise<string | null> {
    try {
      const file = path.join(SHOT_DIR, DEVICE, this.scenario, `${name}.png`);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      await this.page.screenshot({ path: file });
      return file;
    } catch {
      return null;
    }
  }

  private record(step: string, ok: boolean, shot: string | null, error: string | null) {
    const file = path.join(SHOT_DIR, DEVICE, 'steps.jsonl');
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.appendFileSync(file, JSON.stringify({ scenario: this.scenario, step, ok, shot, error }) + '\n');
  }
}

export async function api(method: string, p: string, opts: { token?: string; body?: unknown } = {}) {
  const res = await fetch(`${API}${p}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...(opts.token ? { Authorization: `Bearer ${opts.token}` } : {}) },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  const text = await res.text();
  let json: any = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {}
  return { status: res.status, json };
}

export async function adminToken(): Promise<string> {
  const res = await api('POST', '/auth/admin/login', { body: { ...ADMIN, deviceName: 'e2e', platform: 'web' } });
  return res.json.accessToken;
}

/// Flutter Web включает семантику (E2E=true) лениво: открываем и ждём, пока
/// появятся роли.
export async function openAdmin(page: Page) {
  await page.goto('/');
  await page.waitForSelector('flt-semantics, [role="textbox"], input', { timeout: 60_000 });
}

export async function login(page: Page) {
  await openAdmin(page);
  const email = page.getByRole('textbox').first();
  await expect(email).toBeVisible({ timeout: 60_000 });
  await email.fill(ADMIN.email);
  await page.getByRole('textbox').nth(1).fill(ADMIN.password);
  await page.getByRole('button', { name: /Войти/ }).click();
}
