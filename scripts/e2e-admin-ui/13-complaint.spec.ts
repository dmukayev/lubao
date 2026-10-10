// Сценарий 13: жалоба — «Новые» → «В работе» (не исчезает) → решение с ответом
// автору → «Закрытые».
import { expect, test } from '@playwright/test';
import { adminToken, api, login, openRoute, Steps, typeInto } from './helpers';

test('жалоба: Новые → В работе → решение → Закрытые', async ({ page }, info) => {
  const steps = new Steps(page, `admin_complaint_${info.project.name}`);
  const token = await adminToken();
  // Счётчики вкладок — от текущего состояния: другие сценарии (046) тоже оставляют жалобы.
  const counts = (await api('GET', '/admin/complaints/counts', { token })).json as { newCount: number; inReviewCount: number; closedCount: number };
  const desktop = info.project.name === 'desktop-1280';

  await steps.step('вход-и-список', async () => {
    await login(page);
    await openRoute(page, '/complaints');
    await expect(page.getByRole('heading', { name: 'Жалобы' })).toBeVisible();
  });

  if (!desktop) {
    await steps.step('закрытые-на-телефоне', async () => {
      await page.getByRole('button', { name: new RegExp(`Закрытые · ${counts.closedCount}`) }).click();
      await expect(page.getByRole('button', { name: /E2E: синтетическая жалоба/ })).toBeVisible();
    });
    return;
  }

  await steps.step('жалоба-в-новых', async () => {
    await expect(page.getByRole('button', { name: new RegExp(`Новые · ${counts.newCount}`) })).toBeVisible();
    await page.getByRole('button', { name: /E2E: синтетическая жалоба/ }).click();
    await expect(page.getByRole('button', { name: 'Взять в работу' })).toBeVisible();
  });

  await steps.step('взять-в-работу', async () => {
    await page.getByRole('button', { name: 'Взять в работу' }).click();
    await expect(page.getByRole('button', { name: new RegExp(`Новые · ${counts.newCount - 1}`) })).toBeVisible();
    await expect(page.getByRole('button', { name: new RegExp(`В работе · ${counts.inReviewCount + 1}`) })).toBeVisible();
    // «В работе» — жалоба не исчезает, а переезжает во вкладку.
    await page.getByRole('button', { name: new RegExp(`В работе · ${counts.inReviewCount + 1}`) }).click();
    await expect(page.getByRole('button', { name: /E2E: синтетическая жалоба/ })).toBeVisible();
  });

  // «Сохранить» нажимается всегда; без ответа автору — причина под полем, окно не закрывается.
  await steps.step('решение-без-ответа-подсказка', async () => {
    await page.getByRole('button', { name: /E2E: синтетическая жалоба/ }).click();
    await page.getByRole('button', { name: 'Принять решение' }).click();
    const dialog = page.getByRole('alertdialog');
    await dialog.getByRole('button', { name: 'Сохранить' }).click();
    await expect(dialog.getByText('Напишите ответ автору — он его увидит')).toBeVisible();
    await expect(dialog).toBeVisible();
  });

  await steps.step('решение-с-ответом', async () => {
    const dialog = page.getByRole('alertdialog');
    await typeInto(page, dialog.getByRole('textbox', { name: 'Ответ автору жалобы' }), 'E2E: проверено, нарушений нет');
    await expect(dialog.getByRole('button', { name: 'Сохранить' })).toBeEnabled();
    await dialog.getByRole('button', { name: 'Сохранить' }).click();
    await expect(dialog).toBeHidden();
    await expect(page.getByRole('button', { name: new RegExp(`Закрытые · ${counts.closedCount + 1}`) })).toBeVisible();
    await page.getByRole('button', { name: new RegExp(`Закрытые · ${counts.closedCount + 1}`) }).click();
    await expect(page.getByRole('button', { name: /E2E: синтетическая жалоба/ })).toBeVisible();
  });
});
