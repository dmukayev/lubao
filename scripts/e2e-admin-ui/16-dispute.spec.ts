// Сценарий 16 (046 п.5): спор об отмене после «В пути» виден в «Требует
// внимания», админ открывает сделку и закрывает спор — «Вернуть в «В пути»».
import { expect, test } from '@playwright/test';
import { adminToken, api, login, openRoute, scrollPaneTo, Steps, typeInto } from './helpers';

test('спор об отмене: «Требует внимания» → карточка сделки → решение', async ({ page }, info) => {
  const desktop = info.project.name === 'desktop-1280';
  const steps = new Steps(page, `admin_dispute_${info.project.name}`);
  const token = await adminToken();
  let dealId = '';

  await steps.step('спор-через-API', async () => {
    const ref = (await api('GET', '/reference-data')).json;
    const almaty = ref.points.find((p: { name: { ru: string } }) => p.name.ru === 'Алматы');
    const tent = ref.bodyTypes.find((b: { code: string }) => b.code === 'TENT');
    const kz = ref.countries.find((c: { code: string }) => c.code === 'KZ');
    const phone = desktop ? '+77010000092' : '+77010000091';
    await api('POST', '/auth/phone/request-code', { body: { phone } });
    const driver = (await api('POST', '/auth/phone/verify', { body: { phone, code: '1111', deviceName: 'e2e', platform: 'ios' } })).json.accessToken;
    await api('PATCH', '/drivers/me', { token: driver, body: { fullName: 'Тест Спорный', homeCityId: almaty.cityId, anyCountry: true, directionCountryIds: [], permitIds: [], bodyTypeId: tent.id, capacityTons: 20 } });
    const owner = (await api('POST', '/auth/company/login', { body: { email: 'e2e-owner@lubao-test.kz', password: 'E2eLubao2026!', deviceName: 'e2e', platform: 'ios' } })).json.accessToken;
    const cargo = (await api('POST', '/cargos', { token: owner, body: { pointId: almaty.id, destinationCountryId: kz.id, bodyTypeId: tent.id, price: 3046, currency: 'USD', readyDate: '2030-04-01' } })).json;
    const resp = (await api('POST', `/cargos/${cargo.id}/responses`, { token: driver, body: {} })).json;
    await api('PATCH', `/responses/${resp.id}`, { token: owner, body: { status: 'SELECTED' } });
    dealId = (await api('GET', '/deals/mine', { token: driver })).json.find((d: { cargoId: string }) => d.cargoId === cargo.id).id;
    for (const status of ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT']) {
      await api('PATCH', `/admin/deals/${dealId}/status`, { token, body: { status, reason: 'E2E 046' } });
    }
    expect((await api('PATCH', `/deals/${dealId}/cancel`, { token: owner, body: { reasonCode: 'CARGO_NOT_READY' } })).json.status).toBe('CANCEL_REQUESTED');
    expect((await api('POST', `/deals/${dealId}/cancel-request/dispute`, { token: driver, body: { reason: 'E2E: груз в пути' } })).json.status).toBe('DISPUTED');
  });

  await steps.step('вход', async () => {
    await login(page);
  });

  await steps.step('спор-в-требует-внимания', async () => {
    await openRoute(page, '/dashboard');
    const row = page.getByText(/Споры об отмене: Тест Спорный/).first();
    await scrollPaneTo(page, row, Math.round((page.viewportSize()?.width ?? 1280) / 2));
    await expect(row).toBeVisible();
  });

  await steps.step('карточка-сделки-вернуть-в-путь', async () => {
    await openRoute(page, `/deals/${dealId}`);
    // Flutter склеивает карточку в одну группу — ищем по её имени.
    await expect(page.getByRole('group', { name: /Возражение: E2E: груз в пути/ }).first()).toBeVisible();
    await page.getByRole('button', { name: 'Вернуть в «В пути»' }).click();
    const dialog = page.getByRole('alertdialog');
    await typeInto(page, dialog.getByRole('textbox').first(), 'E2E: груз едет, отмены нет');
    await dialog.getByRole('button', { name: 'Вернуть в «В пути»' }).click();
    await expect(dialog).toBeHidden();
    await expect.poll(async () => (await api('GET', `/admin/deals/${dealId}`, { token })).json.status).toBe('IN_TRANSIT');
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });
});
