// Сценарий 18 (066 п.5): две жалобы водителей на непроверенную компанию —
// публикация на паузе; «Требует внимания» → карточка компании → «Снять паузу».
import { expect, test } from '@playwright/test';
import { adminToken, api, login, openRoute, scrollPaneTo, Steps, typeInto } from './helpers';

test('пауза публикации после жалоб: «Требует внимания» → карточка компании → снять паузу', async ({ page }, info) => {
  const desktop = info.project.name === 'desktop-1280';
  const steps = new Steps(page, `admin_company_pause_${info.project.name}`);
  const token = await adminToken();
  let companyId = '';

  await steps.step('жалобы-через-API', async () => {
    const ref = (await api('GET', '/reference-data')).json;
    const almaty = ref.points.find((p: { name: { ru: string } }) => p.name.ru === 'Алматы');
    const tent = ref.bodyTypes.find((b: { code: string }) => b.code === 'TENT');
    const kz = ref.countries.find((c: { code: string }) => c.code === 'KZ');
    const co = (await api('POST', '/auth/company/register', { body: { email: `e2e-pause-${info.project.name}-${Date.now()}@lubao-test.kz`, password: 'E2eLubao2026!', ownerName: 'Тест Пауза', companyName: `Pause Test ${desktop ? 'D' : 'M'}`, countryId: kz.id, offerVersion: '2026-10-08' } })).json;
    await api('PATCH', '/companies/me/contact', { token: co.accessToken, body: { contactPhone: '+77010000070' } });
    const cargo = (await api('POST', '/cargos', { token: co.accessToken, body: { pointId: almaty.id, destinationCountryId: kz.id, bodyTypeId: tent.id, categoryId: ref.cargoCategories.find((c: { code: string }) => c.code === 'OTHER').id, price: 1066, currency: 'USD', readyDate: '2030-04-01' } })).json;
    companyId = cargo.companyId;
    for (const phone of desktop ? ['+77010000071', '+77010000072'] : ['+77010000073', '+77010000074']) {
      await api('POST', '/auth/phone/request-code', { body: { phone } });
      const driver = (await api('POST', '/auth/phone/verify', { body: { phone, code: '1111', deviceName: 'e2e', platform: 'ios' } })).json.accessToken;
      await api('PATCH', '/drivers/me', { token: driver, body: { fullName: 'Тест Жалобный', homeCityId: almaty.cityId, anyCountry: true, directionCountryIds: [], permitIds: [], bodyTypeId: tent.id, capacityTons: 20 } });
      expect((await api('POST', `/cargos/${cargo.id}/complaint`, { token: driver, body: { reason: 'Тест 066: не выходит на связь' } })).status).toBeLessThan(300);
    }
    expect((await api('GET', `/admin/companies/${companyId}`, { token })).json.publishingPausedAt).toBeTruthy();
  });

  await steps.step('вход', async () => {
    await login(page);
  });

  await steps.step('пауза-в-требует-внимания', async () => {
    await openRoute(page, '/dashboard');
    const row = page.getByText(/На паузе после жалоб: \d+/).first();
    await scrollPaneTo(page, row, Math.round((page.viewportSize()?.width ?? 1280) / 2));
    await expect(row).toBeVisible();
  });

  await steps.step('карточка-компании-снять-паузу', async () => {
    await openRoute(page, `/companies/${companyId}`);
    await expect(page.getByText(/Публикация на паузе: жалобы водителей — 2/).first()).toBeVisible();
    await page.getByRole('button', { name: 'Снять паузу' }).click();
    const dialog = page.getByRole('alertdialog');
    await typeInto(page, dialog.getByRole('textbox').first(), 'E2E: поговорили с компанией');
    await dialog.getByRole('button', { name: 'Снять паузу' }).click();
    await expect(dialog).toBeHidden();
    await expect.poll(async () => (await api('GET', `/admin/companies/${companyId}`, { token })).json.publishingPausedAt).toBeNull();
    await expect(page.getByText(/Публикация на паузе/)).toHaveCount(0);
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });
});
