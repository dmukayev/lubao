// Задача 073: вход в админку с неверным паролем — «Неверный email или пароль»,
// а не «Что-то пошло не так»; потом верный пароль входит.
import { expect, test } from '@playwright/test';
import { ADMIN, login, Steps, typeInto } from './helpers';

test('вход: неверный пароль — понятный текст', async ({ page }, info) => {
  const steps = new Steps(page, `admin_login_errors_${info.project.name}`);
  await steps.step('неверный-пароль', async () => {
    await page.goto('/');
    await page.getByRole('textbox', { name: 'Email' }).waitFor({ timeout: 60_000 });
    await page.waitForTimeout(1500);
    await typeInto(page, page.getByRole('textbox', { name: 'Email' }), ADMIN.email);
    await typeInto(page, page.getByRole('textbox', { name: 'Пароль' }), 'wrong-password-1');
    await page.getByRole('button', { name: 'Войти' }).click();
    await expect(page.getByText('Неверный email или пароль').first()).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });
  await steps.step('верный-пароль-входит', async () => {
    await login(page);
  });
});
