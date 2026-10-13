// Сценарий 19 (068): паллеты скрыты по умолчанию; в «Справочники → Типы кузова»
// у кузова галочка «Паллеты» — включает поле без новой версии приложения.
// В конце галочка возвращается как была: остальные сценарии идут без паллет.
import { expect, test } from '@playwright/test';
import { adminToken, api, login, openRoute, scrollPaneTo, Steps, typeInto } from './helpers';

test('справочник: галочка «Паллеты» у типа кузова', async ({ page }, info) => {
  const steps = new Steps(page, `admin_body_type_pallets_${info.project.name}`);
  const token = await adminToken();
  const tentOf = async () => (await api('GET', '/reference-data')).json.bodyTypes.find((b: { code: string }) => b.code === 'TENT');
  const tent = await tentOf();
  expect(tent.showPallets).toBe(false);

  try {
    await steps.step('вход', async () => {
      await login(page);
    });

    await steps.step('профиль-кузова-галочка-паллеты', async () => {
      await openRoute(page, '/reference');
      const edit = page.getByRole('button', { name: new RegExp(`Редактировать: ${tent.name.ru}`) });
      await scrollPaneTo(page, edit, Math.round((page.viewportSize()?.width ?? 1280) / 2));
      await edit.first().click();
      await page.getByText('Профиль и поля').first().click();
      const dialog = page.getByRole('alertdialog');
      const pallets = dialog.getByRole('checkbox', { name: /Паллеты/ });
      await expect(pallets).toBeVisible();
      await expect(dialog.getByText(/учитывать его в подборе/)).toBeVisible();
      await pallets.click();
      await typeInto(page, dialog.getByRole('textbox').last(), 'E2E 068');
      await dialog.getByRole('button', { name: 'Сохранить' }).click();
      await expect(dialog).toBeHidden();
      await expect.poll(async () => (await tentOf()).showPallets).toBe(true);
      await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
    });
  } finally {
    // Вернуть как было — паллеты снова скрыты.
    await api('PATCH', `/admin/reference/body-types/${tent.id}/profile`, { token, body: { profile: tent.profile, fields: tent.fields, showPallets: false, reason: 'E2E 068: вернуть' } });
  }
});
