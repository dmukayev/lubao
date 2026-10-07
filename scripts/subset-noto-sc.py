#!/usr/bin/env python3
"""Урезанный Noto Sans SC для Flutter (020 часть А, 043 п.8).

Источник — NotoSansSC-Regular.otf из github.com/notofonts/noto-cjk
(Sans/SubsetOTF/SC, лицензия OFL). Набор: GB 2312 уровень 1 (3755 частотных
иероглифов) + все символы app_zh.arb и китайские строки сидов/уведомлений +
CJK-пунктуация и полноширинные формы. Перезапускать при новых строках в zh.

    python3 scripts/subset-noto-sc.py <путь к NotoSansSC-Regular.otf>
"""
import glob
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'packages/lubao_core/assets/fonts/NotoSansSC-Lubao.otf')


def charset() -> str:
    chars = set()
    for hi in range(0xB0, 0xD8):
        for lo in range(0xA1, 0xFF):
            try:
                chars.add(bytes([hi, lo]).decode('gb2312'))
            except UnicodeDecodeError:
                pass
    sources = [os.path.join(ROOT, 'packages/lubao_core/lib/l10n/app_zh.arb')]
    sources += glob.glob(os.path.join(ROOT, 'backend/prisma/*.ts'))
    sources += glob.glob(os.path.join(ROOT, 'backend/src/**/notification-events.ts'), recursive=True)
    for path in sources:
        with open(path, encoding='utf-8') as f:
            chars.update(f.read())
    chars.update(chr(c) for c in range(0x3000, 0x3040))
    chars.update(chr(c) for c in range(0xFF00, 0xFFF0))
    return ''.join(sorted(c for c in chars if ord(c) >= 0x2E80))


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    with tempfile.NamedTemporaryFile('w', suffix='.txt', encoding='utf-8', delete=False) as f:
        f.write(charset())
        text_file = f.name
    subprocess.run(
        ['pyftsubset', sys.argv[1], f'--text-file={text_file}', '--layout-features=*', '--no-hinting', f'--output-file={OUT}'],
        check=True,
    )
    os.unlink(text_file)
    print(f'{OUT}: {os.path.getsize(OUT) // 1024} КБ')


if __name__ == '__main__':
    main()
