import { defineConfig } from '@playwright/test';

// Админка — Flutter Web с включённой семантикой (--dart-define=E2E=true):
// кнопки и поля есть в DOM с ролями и подписями. Два прогона: компьютер
// (1280) — все сценарии, и телефон (390) — экраны на узкой ширине; сначала
// компьютер — он меняет данные.
const args = ['--enable-unsafe-swiftshader', '--use-gl=angle', '--use-angle=swiftshader'];

export default defineConfig({
  testDir: '.',
  testMatch: /.*\.spec\.ts/,
  fullyParallel: false,
  workers: 1,
  timeout: 240_000,
  expect: { timeout: 20_000 },
  reporter: [['list']],
  use: {
    baseURL: process.env.E2E_ADMIN_URL ?? 'http://localhost:3200',
    launchOptions: { args },
  },
  projects: [
    { name: 'desktop-1280', use: { viewport: { width: 1280, height: 900 } } },
    // На узкой ширине — то, что зависит от ширины: сводка, очередь проверки,
    // обход всех экранов (белые экраны, переполнения), вход. Сценарии с
    // изменением данных (ЧС, жалобы, споры, пауза, справочники) — один раз, на 1280.
    {
      name: 'mobile-390',
      testMatch: /(10-summary|11-verification|15-screens|17-login-errors)\.spec\.ts/,
      use: { viewport: { width: 390, height: 844 }, hasTouch: false },
    },
  ],
});
