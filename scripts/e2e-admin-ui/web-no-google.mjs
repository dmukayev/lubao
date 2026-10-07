// 020 часть А / 043 п.8: веб логиста не делает ни одного запроса к Google
// (gstatic/googleapis в Китае заблокированы). Открываем собранный веб в
// Chrome с китайской локалью — иероглифы на экране, — собираем хосты всех
// запросов; любой google-хост — провал.
//   node web-no-google.mjs <url> [скриншот.png]
import { chromium } from '@playwright/test';

const [url, shot] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await (await browser.newContext({ locale: 'zh-CN' })).newPage();
const hosts = new Map();
page.on('request', (r) => {
  const host = new URL(r.url()).host;
  hosts.set(host, (hosts.get(host) ?? 0) + 1);
});
await page.goto(url);
await page.waitForFunction(() => !document.getElementById('lubao-splash'), null, { timeout: 30_000 });
await page.waitForTimeout(3000);
if (shot) await page.screenshot({ path: shot });
await browser.close();
const google = [...hosts.keys()].filter((h) => /gstatic|googleapis|google\./.test(h));
console.log(`хосты: ${JSON.stringify(Object.fromEntries(hosts))}`);
if (google.length) {
  console.log(`FAIL запросы к Google: ${google.join(', ')}`);
  process.exit(1);
}
console.log('ok ни одного запроса к gstatic/googleapis');
