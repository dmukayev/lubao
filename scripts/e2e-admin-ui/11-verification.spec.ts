// Сценарий 11: проверка документов — водитель из очереди: блок «Распознано»
// с полями → одобрить документы → «Подтвердить водителя» → водитель
// «Проверен»; машина (техпаспорт) одобряется отдельно; компания → «Подтвердить
// компанию» → у логиста разблокируется публикация (проверяется в приложении).
import { expect, test, type Page } from '@playwright/test';
import { api, adminToken, login, openRoute, scrollPaneTo, scrollPaneTop, Steps, typeInto } from './helpers';

async function confirmWithReason(page: Page, reason: string) {
  const dialog = page.getByRole('alertdialog');
  await expect(dialog).toBeVisible();
  await typeInto(page, dialog.getByRole('textbox').first(), reason);
  await dialog.getByRole('button', { name: 'Готово' }).click();
  await expect(dialog).toBeHidden();
}

test('проверка: новый водитель, машина и компания подтверждаются из очереди', async ({ page }, info) => {
  test.skip(info.project.name !== 'desktop-1280', 'подтверждения меняют данные — один раз, на компьютере');
  const steps = new Steps(page, 'admin_verification');
  const token = await adminToken();

  await steps.step('вход-и-очередь', async () => {
    await login(page);
    await openRoute(page, '/verification');
    await expect(page.getByRole('button', { name: /Сергей Новиков/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /Эдуард Тестов/ })).toBeVisible();
  });

  await steps.step('водитель-распознано', async () => {
    await page.getByRole('button', { name: /Сергей Новиков/ }).click();
    // Открыт может оказаться документ без распознавания (селфи) — выбираем права.
    await scrollPaneTo(page, page.getByRole('button', { name: 'Права', exact: true }));
    await page.getByRole('button', { name: 'Права', exact: true }).click();
    await scrollPaneTop(page);
    const recognized = page.getByRole('group', { name: /Распознано/ });
    await scrollPaneTo(page, recognized);
    await expect(recognized).toBeVisible();
    await expect(recognized).toHaveAttribute('aria-label', /ИИН/);
    await expect(recognized).toContainText('9503••••2008');
    await expect(page.getByRole('button', { name: 'Подтвердить водителя' })).toBeDisabled();
  });

  await steps.step('одобрить-права-и-селфи', async () => {
    await page.getByRole('button', { name: 'Одобрить' }).click();
    await scrollPaneTo(page, page.getByRole('button', { name: 'Селфи', exact: true }));
    await page.getByRole('button', { name: 'Селфи', exact: true }).click();
    await scrollPaneTop(page);
    await page.getByRole('button', { name: 'Одобрить' }).click();
    await expect(page.getByRole('button', { name: 'Подтвердить водителя' })).toBeEnabled();
  });

  await steps.step('подтвердить-водителя', async () => {
    await page.getByRole('button', { name: 'Подтвердить водителя' }).click();
    await confirmWithReason(page, 'E2E: документы совпали с профилем');
    await expect.poll(async () => {
      const list = (await api('GET', '/admin/drivers?search=Сергей', { token })).json;
      return list.items.find((d: any) => d.fullName === 'Сергей Новиков')?.isVerified;
    }, { timeout: 20_000 }).toBe(true);
  });

  await steps.step('водитель-проверен-в-списке', async () => {
    await openRoute(page, '/drivers');
    await expect(page.getByRole('row', { name: /Сергей Новиков.*Проверен/ })).toBeVisible();
  });

  await steps.step('машина-техпаспорт-одобряется', async () => {
    await openRoute(page, '/verification');
    await page.getByRole('button', { name: /Эдуард Тестов/ }).click();
    await scrollPaneTo(page, page.getByRole('button', { name: /Техпаспорт/ }));
    await page.getByRole('button', { name: /Техпаспорт/ }).first().click();
    await scrollPaneTop(page);
    await page.getByRole('button', { name: 'Одобрить' }).click();
    await page.getByRole('button', { name: 'Подтвердить водителя' }).click();
    await expect.poll(async () => {
      const q = (await api('GET', '/admin/verification/queue', { token })).json as Array<{ subjectName: string }>;
      return q.some((i) => i.subjectName === 'Эдуард Тестов');
    }, { timeout: 20_000 }).toBe(false);
  });

  await steps.step('компания-подтверждается', async () => {
    await openRoute(page, '/verification');
    await page.getByRole('button', { name: 'Компании' }).click();
    await page.getByRole('button', { name: /Urumqi Test Logistics/ }).click();
    await page.getByRole('button', { name: 'Одобрить' }).click();
    await page.getByRole('button', { name: /Подтвердить компанию/ }).click();
    await confirmWithReason(page, 'E2E: свидетельство в порядке');
    await expect.poll(async () => {
      const list = (await api('GET', '/admin/companies?search=Urumqi', { token })).json;
      return list.items.find((c: any) => c.name === 'Urumqi Test Logistics')?.isVerified;
    }, { timeout: 20_000 }).toBe(true);
  });
});

test('проверка на узком экране: очередь открывается, действия доступны', async ({ page }, info) => {
  test.skip(info.project.name !== 'mobile-390', 'только телефон');
  const steps = new Steps(page, 'admin_verification_mobile');
  await steps.step('очередь', async () => {
    await login(page);
    await openRoute(page, '/verification');
    await expect(page.getByRole('heading', { name: 'Документы на проверку' })).toBeVisible();
    await expect(page.getByText('Что-то пошло не так')).toHaveCount(0);
  });
});
