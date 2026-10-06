// Разовый обход экранов админки (задача 034, п.17): каждый маршрут открывается
// без белого экрана и без «Что-то пошло не так», на ширине 1280 и 390.
import { expect, test } from '@playwright/test';
import { adminToken, login, openRoute, Steps } from './helpers';

const ROUTES: Array<[string, string]> = [
  ['dashboard', '/dashboard'],
  ['verification', '/verification'],
  ['complaints', '/complaints'],
  ['drivers', '/drivers'],
  ['companies', '/companies'],
  ['cargos', '/cargos'],
  ['deals', '/deals'],
  ['search', '/search'],
  ['more', '/more'],
  ['audit', '/audit'],
  ['settings', '/settings'],
  ['reference', '/reference'],
];

test('обход экранов админки: ни одного белого экрана', async ({ page }, info) => {
  const steps = new Steps(page, `admin_screens_${info.project.name}`);
  await adminToken();
  await steps.step('вход', async () => {
    await login(page);
  });
  for (const [name, route] of ROUTES) {
    await steps.step(name, async () => {
      await openRoute(page, route);
      await page.waitForTimeout(1500);
      // Любой экран: есть заголовок или поле/кнопка (семантика не пустая).
      const semantic = page.locator('flt-semantics').first();
      await expect(semantic).toBeAttached();
      await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
      expect(await page.locator('flt-semantics').count()).toBeGreaterThan(3);
    });
  }
});
