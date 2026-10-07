// Сценарий 12: чёрный список — админ блокирует водителя «по идентификаторам»,
// новый водитель с тем же ИИН в проверке получает ⛔, обычное «Подтвердить»
// неактивно (остаётся «вопреки совпадению» с причиной).
import { expect, test } from '@playwright/test';
import { api, adminToken, login, openRoute, scrollPaneTo, scrollPaneTop, Steps, tapAt, typeInto } from './helpers';

test('блокировка по ИИН и ⛔ у нового водителя с тем же ИИН', async ({ page }, info) => {
  const desktop = info.project.name === 'desktop-1280';
  const steps = new Steps(page, `admin_blacklist_${info.project.name}`);
  const token = await adminToken();

  await steps.step('вход', async () => {
    await login(page);
  });

  if (desktop) {
    await steps.step('блокировка-водителя-с-идентификаторами', async () => {
      await openRoute(page, '/drivers');
      await tapAt(page, page.getByRole('row', { name: /Ержан Блоков/ }).first());
      await page.getByRole('button', { name: 'Блокировать' }).click();
      const dialog = page.getByRole('alertdialog');
      await expect(dialog).toBeVisible();
      await expect(dialog.getByRole('checkbox', { name: 'ИИН' })).toBeChecked();
      await typeInto(page, dialog.getByRole('textbox', { name: 'Причина' }), 'E2E: мошенничество с документами');
      await dialog.getByRole('button', { name: 'Блокировать' }).click();
      await expect(dialog).toBeHidden();
      await expect.poll(async () => {
        const res = (await api('GET', '/admin/attention', { token })).json;
        return res.blacklistMatches;
      }, { timeout: 20_000 }).toBeGreaterThanOrEqual(0);
      await expect(page.getByRole('button', { name: 'Разблокировать' })).toBeVisible();
    });
  }

  await steps.step('новый-водитель-в-проверке-⛔', async () => {
    await openRoute(page, '/verification');
    await page.getByRole('button', { name: /Руслан Дублёров/ }).click();
    await page.waitForTimeout(1500);
    await expect(page.getByRole('group', { name: /Руслан Дублёров.*Чёрный список/ })).toBeVisible();
    const confirm = page.getByRole('button', { name: 'Подтвердить водителя' });
    await expect(confirm).toBeDisabled();
    await expect(page.getByRole('button', { name: 'Подтвердить вопреки совпадению' })).toBeVisible();
    await expect(page.getByText(/Совпадение с чёрным списком/).first()).toBeVisible();
  });

  // 043 п.4: экран «Чёрный список» — ручная блокировка с причиной, значение
  // только маской, снятие с причиной.
  const manualIin = desktop ? '990101300011' : '990101300022';
  await steps.step('чёрный-список-ручная-блокировка', async () => {
    await openRoute(page, '/blacklist');
    await page.getByRole('button', { name: 'Добавить в чёрный список' }).click();
    const dialog = page.getByRole('alertdialog');
    await expect(dialog).toBeVisible();
    await typeInto(page, dialog.getByRole('textbox', { name: 'Значение' }), manualIin);
    await typeInto(page, dialog.getByRole('textbox', { name: 'Причина' }), 'E2E: ручная блокировка ИИН');
    await dialog.getByRole('button', { name: 'Сохранить' }).click();
    await expect(dialog).toBeHidden();
    // Текст карточки Flutter сливает в один узел доступности — результат
    // проверяем через API, вид строки — скриншот шага.
    await expect.poll(async () => {
      const rows = (await api('GET', '/admin/blacklist?active=true', { token })).json as Array<{ reason: string; valueMasked: string }>;
      const row = rows.find((r) => r.reason === 'E2E: ручная блокировка ИИН');
      return row ? row.valueMasked.includes(manualIin) : null;
    }, { timeout: 15_000 }).toBe(false);
    await page.waitForTimeout(800);
  });

  await steps.step('чёрный-список-снятие', async () => {
    const rows = await api('GET', '/admin/blacklist?active=true', { token });
    const before = rows.json.filter((r: { reason: string }) => r.reason === 'E2E: ручная блокировка ИИН').length;
    await page.getByRole('button', { name: 'Снять блокировку' }).first().click();
    const dialog = page.getByRole('alertdialog');
    await typeInto(page, dialog.getByRole('textbox', { name: 'Причина' }), 'E2E: ошибка оператора');
    await dialog.getByRole('button', { name: 'Снять блокировку' }).click();
    expect(before).toBeGreaterThan(0);
    // Список свежими сверху — снята именно ручная запись этого прогона.
    const manualActive = async () =>
      (await api('GET', '/admin/blacklist?active=true', { token })).json.filter((r: { reason: string }) => r.reason === 'E2E: ручная блокировка ИИН').length;
    await expect.poll(manualActive, { timeout: 15_000 }).toBe(before - 1);
  });
});

