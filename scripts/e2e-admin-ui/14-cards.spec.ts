// Сценарий 14: карточки водителя, компании, груза и сделки открываются без
// белого экрана; правка имени водителя не меняет госномер.
import { expect, test, type Page } from '@playwright/test';
import { adminToken, api, login, openRoute, Steps, tapAt, typeInto } from './helpers';

async function openFirst(page: Page, desktop: boolean, rowName: RegExp, buttonName: RegExp) {
  if (desktop) await tapAt(page, page.getByRole('row', { name: rowName }).first());
  else await page.getByRole('button', { name: buttonName }).first().click();
}

test('карточки открываются; правка имени не трогает госномер', async ({ page }, info) => {
  const desktop = info.project.name === 'desktop-1280';
  const steps = new Steps(page, `admin_cards_${info.project.name}`);
  const token = await adminToken();

  await steps.step('вход', async () => {
    await login(page);
  });

  await steps.step('карточка-водителя', async () => {
    await openRoute(page, '/drivers');
    await openFirst(page, desktop, /Эдуард (Тестов|Переименованный)/, /Эдуард (Тестов|Переименованный)/);
    await expect(page.getByRole('button', { name: 'Назад' })).toBeVisible();
    await expect(page.getByRole('group', { name: /Эдуард (Тестов|Переименованный)/ }).first()).toBeVisible();
    await expect(page.locator('body')).toContainText(/E2E001KZ/);
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });

  await steps.step('карточка-компании', async () => {
    await openRoute(page, '/companies');
    await openFirst(page, desktop, /E2E Test Logistics/, /E2E Test Logistics/);
    await expect(page.getByRole('button', { name: 'Назад' })).toBeVisible();
    await expect(page.getByRole('group', { name: /E2E Test Logistics/ }).first()).toBeVisible();
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });

  await steps.step('карточка-груза', async () => {
    await openRoute(page, '/cargos');
    await openFirst(page, desktop, /Хоргос → Алматы/, /Хоргос → Алматы/);
    await expect(page.getByRole('button', { name: 'Назад' })).toBeVisible();
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });

  await steps.step('карточка-сделки', async () => {
    const deals = (await api('GET', '/admin/deals', { token })).json;
    expect(deals.items.length).toBeGreaterThan(0);
    await openRoute(page, '/deals');
    await page.waitForTimeout(1500);
    if (desktop) await tapAt(page, page.getByRole('row').nth(1));
    else await page.getByRole('button', { name: /→/ }).first().click();
    await expect(page.getByRole('button', { name: 'Назад' })).toBeVisible();
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });

  if (!desktop) return;

  await steps.step('правка-имени-не-меняет-госномер', async () => {
    await openRoute(page, '/drivers');
    await tapAt(page, page.getByRole('row', { name: /Эдуард Тестов/ }).first());
    await expect(page.locator('body')).toContainText(/E2E001KZ/);
    await page.getByRole('button', { name: 'Редактировать' }).click();
    const name = page.getByRole('textbox', { name: 'Ф.И.О.' });
    await typeInto(page, name, 'Эдуард Переименованный');
    await typeInto(page, page.getByRole('textbox', { name: 'Причина' }), 'E2E: проверка правки имени');
    await page.getByRole('button', { name: 'Сохранить' }).click();
    await expect(page.getByRole('group', { name: /Эдуард Переименованный/ }).first()).toBeVisible();
    await expect(page.locator('body')).toContainText(/E2E001KZ/);
  });
});
