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
  // 047 п.8: цены по маршрутам.
  ['route-prices', '/route-prices'],
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
      // 042 п.3: блок «Каналы кода входа» — три канала со стрелками порядка и
      // переключателями (Flutter склеивает тексты карточки в один узел —
      // проверяем по кнопкам и переключателям).
      if (name === 'settings') {
        await expect(page.getByRole('button', { name: 'Ниже' }).first()).toBeVisible();
        // 050: четыре способа входа — бот Telegram и три канала кода.
        expect(await page.getByRole('button', { name: 'Ниже' }).count()).toBe(4);
        expect(await page.getByRole('button', { name: 'Выше' }).count()).toBe(4);
        expect(await page.getByRole('switch').count()).toBeGreaterThanOrEqual(3);
        // 042 п.4: курсы НБ РК — правка USD и CNY (на 1280 карточка в кадре).
        if ((page.viewportSize()?.width ?? 0) >= 800) {
          expect(await page.getByRole('button', { name: 'Изменить курс' }).count()).toBe(2);
        }
      }
    });
  }
});
