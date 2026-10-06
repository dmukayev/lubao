// Сценарий 13: жалоба — «Новые» → «В работе» (не исчезает) → решение с ответом
// автору → «Закрытые».
import { expect, test } from '@playwright/test';
import { adminToken, login, openRoute, Steps, typeInto } from './helpers';

test('жалоба: Новые → В работе → решение → Закрытые', async ({ page }, info) => {
  const steps = new Steps(page, `admin_complaint_${info.project.name}`);
  await adminToken();
  const desktop = info.project.name === 'desktop-1280';

  await steps.step('вход-и-список', async () => {
    await login(page);
    await openRoute(page, '/complaints');
    await expect(page.getByRole('heading', { name: 'Жалобы' })).toBeVisible();
  });

  if (!desktop) {
    await steps.step('закрытые-на-телефоне', async () => {
      await page.getByRole('button', { name: /Закрытые · 1/ }).click();
      await expect(page.getByRole('button', { name: /E2E: синтетическая жалоба/ })).toBeVisible();
    });
    return;
  }

  await steps.step('жалоба-в-новых', async () => {
    await expect(page.getByRole('button', { name: /Новые · 1/ })).toBeVisible();
    await page.getByRole('button', { name: /E2E: синтетическая жалоба/ }).click();
    await expect(page.getByRole('button', { name: 'Взять в работу' })).toBeVisible();
  });

  await steps.step('взять-в-работу', async () => {
    await page.getByRole('button', { name: 'Взять в работу' }).click();
    await expect(page.getByRole('button', { name: /Новые · 0/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /В работе · 1/ })).toBeVisible();
    // «В работе» — жалоба не исчезает, а переезжает во вкладку.
    await page.getByRole('button', { name: /В работе · 1/ }).click();
    await expect(page.getByRole('button', { name: /E2E: синтетическая жалоба/ })).toBeVisible();
  });

  await steps.step('решение-без-ответа-недоступно', async () => {
    await page.getByRole('button', { name: /E2E: синтетическая жалоба/ }).click();
    await page.getByRole('button', { name: 'Принять решение' }).click();
    const dialog = page.getByRole('alertdialog');
    await expect(dialog.getByRole('button', { name: 'Сохранить' })).toBeDisabled();
  });

  await steps.step('решение-с-ответом', async () => {
    const dialog = page.getByRole('alertdialog');
    await typeInto(page, dialog.getByRole('textbox', { name: 'Ответ автору жалобы' }), 'E2E: проверено, нарушений нет');
    await expect(dialog.getByRole('button', { name: 'Сохранить' })).toBeEnabled();
    await dialog.getByRole('button', { name: 'Сохранить' }).click();
    await expect(dialog).toBeHidden();
    await expect(page.getByRole('button', { name: /Закрытые · 1/ })).toBeVisible();
    await page.getByRole('button', { name: /Закрытые · 1/ }).click();
    await expect(page.getByRole('button', { name: /E2E: синтетическая жалоба/ })).toBeVisible();
  });
});
