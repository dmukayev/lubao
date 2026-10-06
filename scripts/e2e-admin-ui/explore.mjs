// Разведчик админки (dev-инструмент, не часть прогона): входит и печатает
// accessibility-дерево Flutter-семантики по шагам, чтобы писать спеки.
//   W=390 STEPS='[{"goto":"/drivers"},{"click":"Эдуард","role":"row"},{"dump":true}]' node explore.mjs
// Нужны backend на :3100 и статика админки на :3200 (см. scripts/e2e.sh).
import { chromium } from '@playwright/test';
const width = Number(process.env.W ?? 1280);
const steps = JSON.parse(process.env.STEPS ?? '[]');
const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader', '--use-gl=angle', '--use-angle=swiftshader'] });
const page = await browser.newPage({ viewport: { width, height: 1000 } });
page.on('response', r => { if (r.url().includes('3100') && r.request().method()!=='GET') console.log('RESP', r.status(), r.url()); });
async function typeInto(loc, text) { for (let a = 0; a < 4; a++) { await loc.click(); await page.waitForTimeout(400); await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.press('Backspace'); await loc.pressSequentially(text, { delay: 30 }); await page.waitForTimeout(200); if ((await loc.inputValue().catch(() => text)) === text) return; } }
for (let attempt = 0; attempt < 3; attempt++) {
  await page.goto('http://localhost:3200/');
  await page.getByRole('textbox', { name: 'Email' }).waitFor();
  await page.waitForTimeout(2000);
  await typeInto(page.getByRole('textbox', { name: 'Email' }), 'e2e-admin@lubao-test.kz');
  await typeInto(page.getByRole('textbox', { name: 'Пароль' }), 'E2eLubao2026!');
  await page.waitForTimeout(800);
  await page.getByRole('button', { name: 'Войти' }).click();
  try { await page.getByRole('heading', { name: 'Обзор' }).waitFor({ timeout: 10000 }); break; } catch { console.log('retry login', attempt); console.log((await page.locator('body').ariaSnapshot()).slice(0,400)); }
}
for (const st of steps) {
  if (st.goto) { await page.goto('http://localhost:3200/#' + st.goto); await page.waitForTimeout(3000); }
  if (st.click) {
    const loc = page.getByRole(st.role ?? 'button', { name: new RegExp(st.click) }).first();
    if (st.role === 'row' || st.mouse) { const b = await loc.boundingBox(); await page.mouse.click(b.x + b.width / 2, b.y + b.height / 2); }
    else await loc.click();
    await page.waitForTimeout(2500);
  }
  if (st.scroll) { await page.mouse.move(700, 500); await page.mouse.wheel(0, st.scroll); await page.waitForTimeout(1500); }
  if (st.wait) await page.waitForTimeout(st.wait);
  if (st.dump) { console.log('=== dump ' + (st.name ?? '')); console.log((await page.locator('body').ariaSnapshot()).split('\n').map(l => l.slice(0, 260)).join('\n')); }
  if (st.shot) await page.screenshot({ path: st.shot });
}
await browser.close();
