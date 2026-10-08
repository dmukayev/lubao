// Сценарий 10: сводка — плитки и строки «Требует внимания» совпадают со
// списками, в которые ведут (число на плитке = число строк в списке).
import { expect, test, type Page } from '@playwright/test';
import { api, adminToken, login, openRoute, scrollPaneTo, Steps } from './helpers';

async function listCount(page: Page, kind: 'drivers' | 'companies' | 'cargos'): Promise<number> {
  const desktop = (page.viewportSize()?.width ?? 0) >= 800;
  if (desktop) return (await page.getByRole('row').count()) - 1;
  const pattern = { drivers: /\+7\d{10}/, companies: /@/, cargos: /→/ }[kind];
  return page.getByRole('button', { name: pattern }).count();
}

test('сводка: плитки и «Требует внимания» ведут в согласованные списки', async ({ page }, info) => {
  const steps = new Steps(page, `admin_summary_${info.project.name}`);
  const token = await adminToken();
  const stats = (await api('GET', '/admin/stats?period=today', { token })).json;
  const attention = (await api('GET', '/admin/attention', { token })).json;

  await steps.step('вход-и-сводка', async () => {
    await login(page);
    await expect(page.getByRole('button', { name: new RegExp(`^${stats.drivers} Водители`) })).toBeVisible();
    await expect(page.getByRole('button', { name: new RegExp(`^${stats.companies} Компании`) })).toBeVisible();
    await expect(page.getByRole('button', { name: new RegExp(`^${stats.openComplaints} Открытые жалобы`) })).toBeVisible();
    await expect(page.getByRole('button', { name: new RegExp(`^${stats.pendingDocs} Документы на проверке`) })).toBeVisible();
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });

  await steps.step('плитка-водители', async () => {
    await page.getByRole('button', { name: new RegExp(`^${stats.drivers} Водители`) }).click();
    await expect(page.getByRole('heading', { name: 'Водители' })).toBeVisible();
    await page.waitForTimeout(1500);
    expect(await listCount(page, 'drivers')).toBe(stats.drivers);
  });

  await steps.step('плитка-компании', async () => {
    await openRoute(page, '/dashboard');
    await page.getByRole('button', { name: new RegExp(`^${stats.companies} Компании`) }).click();
    await expect(page.getByRole('heading', { name: 'Компании' })).toBeVisible();
    await page.waitForTimeout(1500);
    expect(await listCount(page, 'companies')).toBe(stats.companies);
  });

  await steps.step('плитка-активные-грузы', async () => {
    await openRoute(page, '/dashboard');
    await page.getByRole('button', { name: new RegExp(`^${stats.cargosPublished} Активные грузы`) }).click();
    await expect(page.getByRole('heading', { name: 'Грузы' })).toBeVisible();
    await page.waitForTimeout(1500);
    expect(await listCount(page, 'cargos')).toBe(stats.cargosPublished);
  });

  await steps.step('плитка-документы-на-проверке', async () => {
    await openRoute(page, '/dashboard');
    await page.getByRole('button', { name: new RegExp(`^${stats.pendingDocs} Документы на проверке`) }).click();
    await expect(page.getByRole('heading', { name: 'Документы на проверку' })).toBeVisible();
    await page.waitForTimeout(1500);
    // Очередь — по людям: каждый из API виден в списке, число документов
    // в очереди (водители) не больше числа на плитке.
    const queue = ((await api('GET', '/admin/verification/queue', { token })).json ?? []) as Array<{ subjectName: string; pendingCount: number }>;
    for (const item of queue) {
      await expect(page.getByRole('button', { name: new RegExp(item.subjectName) })).toBeVisible();
    }
    expect(queue.reduce((sum, i) => sum + i.pendingCount, 0)).toBeLessThanOrEqual(stats.pendingDocs);
  });

  await steps.step('плитка-открытые-жалобы', async () => {
    await openRoute(page, '/dashboard');
    await page.getByRole('button', { name: new RegExp(`^${stats.openComplaints} Открытые жалобы`) }).click();
    await expect(page.getByRole('heading', { name: 'Жалобы' })).toBeVisible();
    await page.waitForTimeout(1500);
    const counts = (await api('GET', '/admin/complaints/counts', { token })).json;
    await expect(page.getByRole('button', { name: new RegExp(`Новые · ${counts.newCount}`) })).toBeVisible();
    await expect(page.getByRole('button', { name: new RegExp(`В работе · ${counts.inReviewCount}`) })).toBeVisible();
    expect(counts.newCount + counts.inReviewCount).toBe(stats.openComplaints);
  });

  await steps.step('требует-внимания-ведёт-в-списки', async () => {
    await openRoute(page, '/dashboard');
    if (attention.openComplaints > 0) {
      await page.getByRole('button', { name: new RegExp(`Открытых жалоб: ${attention.openComplaints}`) }).click();
      await expect(page.getByRole('heading', { name: 'Жалобы' })).toBeVisible();
    }
    await openRoute(page, '/dashboard');
    if (attention.pendingVerificationCount > 0) {
      await page.getByRole('button', { name: new RegExp(`На проверке: ${attention.pendingVerificationCount}`) }).click();
      await expect(page.getByRole('heading', { name: 'Документы на проверку' })).toBeVisible();
    }
  });

  // Задача 040, п.9: разрез сводки по городам — анонсы / грузы / сделки.
  // Последним шагом: на узком экране прокрутка вниз уводит плитки из
  // семантики Flutter, и следующие шаги их не находят.
  await steps.step('сводка-по-городам', async () => {
    await openRoute(page, '/dashboard');
    const rows = ((await api('GET', '/admin/stats/by-city', { token })).json ?? []) as Array<{ name: { ru: string } }>;
    expect(rows.length).toBeGreaterThan(0);
    const width = page.viewportSize()?.width ?? 1280;
    // На 390 px колесо в эмуляции телефона дальше ленты событий страницу не
    // крутит (на устройстве — свайп); блок проверяем данными, вид — на 1280.
    if (width < 600) return;
    await scrollPaneTo(page, page.getByText('По городам', { exact: true }), Math.round(width / 2));
    // Flutter склеивает таблицу в один семантический узел — ищем подстрокой.
    await expect(page.getByText(rows[0].name.ru).first()).toBeVisible();
  });
});
