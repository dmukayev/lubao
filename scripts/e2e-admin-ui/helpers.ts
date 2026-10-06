import { expect, type Locator, type Page } from '@playwright/test';
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

/// Ввод в поле Flutter Web: при нагрузке первые символы теряются, пока поле
/// получает фокус, — ждём, вводим и сверяем значение, при расхождении повторяем.
export async function typeInto(page: Page, loc: Locator, text: string) {
  for (let attempt = 0; attempt < 4; attempt++) {
    await loc.click();
    await page.waitForTimeout(400);
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.press('Backspace');
    await loc.pressSequentially(text, { delay: 30 });
    await page.waitForTimeout(200);
    if ((await loc.inputValue().catch(() => text)) === text) return;
  }
  throw new Error(`Не удалось ввести «${text}» в поле`);
}

/// Клик по элементу, который в семантике не кнопка (строка таблицы и т. п.):
/// поверх лежит flutter-view, поэтому кликаем по координатам.
export async function tapAt(page: Page, loc: Locator) {
  const box = await loc.boundingBox();
  if (!box) throw new Error('Нет рамки элемента для клика');
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
}

/// Вход админа; при сбое (медленная загрузка) перезагружаем страницу.
export async function login(page: Page) {
  for (let attempt = 0; attempt < 4; attempt++) {
    await page.goto('/');
    await page.getByRole('textbox', { name: 'Email' }).waitFor({ timeout: 60_000 });
    await page.waitForTimeout(1500);
    await typeInto(page, page.getByRole('textbox', { name: 'Email' }), ADMIN.email);
    await typeInto(page, page.getByRole('textbox', { name: 'Пароль' }), ADMIN.password);
    await page.getByRole('button', { name: 'Войти' }).click();
    try {
      await page.getByRole('heading', { name: 'Обзор' }).waitFor({ timeout: 15_000 });
      return;
    } catch {
      // повторяем
    }
  }
  throw new Error('Не удалось войти в админку');
}

/// Переход по внутреннему маршруту (hash-роутинг) без потери сессии.
export async function openRoute(page: Page, route: string) {
  await page.evaluate((r) => {
    window.location.hash = r;
  }, route);
  await page.waitForTimeout(2500);
}

/// Прокручивает правую панель (ленивый список), пока элемент не появится в семантике.
export async function scrollPaneTo(page: Page, loc: Locator, x = 800) {
  for (let i = 0; i < 12; i++) {
    if (await loc.first().isVisible().catch(() => false)) return;
    await page.mouse.move(x, 500);
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(700);
  }
  await expect(loc.first()).toBeVisible();
}

export async function scrollPaneTop(page: Page, x = 800) {
  await page.mouse.move(x, 500);
  await page.mouse.wheel(0, -6000);
  await page.waitForTimeout(1000);
}
