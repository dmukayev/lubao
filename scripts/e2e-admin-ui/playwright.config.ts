import { defineConfig } from '@playwright/test';

// Админка — Flutter Web с включённой семантикой (--dart-define=E2E=true):
// кнопки и поля есть в DOM с ролями и подписями. Сценарии идут по порядку,
// каждый шаг пишет скриншот и строку в steps.jsonl (см. helpers.ts).
export default defineConfig({
  testDir: '.',
  testMatch: /.*\.spec\.ts/,
  fullyParallel: false,
  workers: 1,
  timeout: 120_000,
  expect: { timeout: 15_000 },
  reporter: [['list']],
  use: {
    baseURL: process.env.E2E_ADMIN_URL ?? 'http://localhost:3200',
    launchOptions: { args: ['--enable-unsafe-swiftshader', '--use-gl=angle', '--use-angle=swiftshader'] },
  },
});
