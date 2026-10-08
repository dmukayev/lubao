// 049 п.13: приёмник скриншотов и шагов с Android-эмулятора. Каталог Мака
// эмулятор не видит, а `flutter test` удаляет приложение после прогона —
// тест шлёт файлы сюда по HTTP (через `adb reverse`).
//   PUT  /<относительный путь> — записать файл; POST /<путь> — дописать строку.
import { createServer } from 'node:http';
import { mkdirSync, writeFileSync, appendFileSync } from 'node:fs';
import { dirname, join, normalize } from 'node:path';

const [root, port] = [process.argv[2], Number(process.argv[3] ?? 3301)];
createServer((req, res) => {
  const rel = normalize(decodeURIComponent((req.url ?? '/').split('?')[0])).replace(/^(\.\.(\/|\\|$))+/, '');
  const target = join(root, rel);
  if (!target.startsWith(root)) { res.writeHead(400).end(); return; }
  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    mkdirSync(dirname(target), { recursive: true });
    const body = Buffer.concat(chunks);
    if (req.method === 'PUT') writeFileSync(target, body);
    else if (req.method === 'POST') appendFileSync(target, body);
    else { res.writeHead(405).end(); return; }
    res.writeHead(204).end();
  });
}).listen(port, '127.0.0.1', () => console.log(`shot sink → ${root} :${port}`));
