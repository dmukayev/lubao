import { defineConfig } from '@playwright/test';

// Админка — Flutter Web с включённой семантикой (--dart-define=E2E=true):
// кнопки и поля есть в DOM с ролями и подписями. Два прогона: компьютер
// (1280) и телефон (390); сначала компьютер — он меняет данные, телефон
// проверяет, что те же экраны открываются и согласованы на узкой ширине.
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
    { name: 'mobile-390', use: { viewport: { width: 390, height: 844 }, hasTouch: false } },
  ],
});
