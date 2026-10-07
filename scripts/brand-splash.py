#!/usr/bin/env python3
"""Заставка: знак (design/brand/mark-512.png) + «Lubao» шрифтом Onest.
Кладёт PNG в ресурсы iOS (LaunchImage @1x/2x/3x) и Android (drawable-*dpi/splash.png).
Без flutter_native_splash (задача 043 п.7). Запуск: python3 scripts/brand-splash.py (нужен Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
MARK = Image.open(ROOT / 'design/brand/mark-512.png').convert('RGBA')
FONT = ROOT / 'packages/lubao_core/assets/fonts/Onest-Variable.ttf'
ORANGE = (0xE8, 0x74, 0x2E, 255)

def splash(scale: float) -> Image.Image:
    """Логические 160×160: знак 120 и подпись 36 вплотную под ним (у mark-512 свои поля)."""
    w, h = round(160 * scale), round(160 * scale)
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    m = round(120 * scale)
    img.alpha_composite(MARK.resize((m, m), Image.LANCZOS), ((w - m) // 2, 0))
    font = ImageFont.truetype(str(FONT), round(36 * scale))
    try:
        font.set_variation_by_axes([800])
    except Exception:
        pass
    d = ImageDraw.Draw(img)
    text = 'Lubao'
    tw = d.textlength(text, font=font)
    d.text(((w - tw) / 2, round(106 * scale)), text, font=font, fill=ORANGE)
    return img

ios = ROOT / 'apps/lubao_app/ios/Runner/Assets.xcassets/LaunchImage.imageset'
for name, s in [('LaunchImage.png', 1), ('LaunchImage@2x.png', 2), ('LaunchImage@3x.png', 3)]:
    splash(s).save(ios / name)
android = ROOT / 'apps/lubao_app/android/app/src/main/res'
for dpi, s in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    out = android / f'drawable-{dpi}'
    out.mkdir(exist_ok=True)
    splash(s).save(out / 'splash.png')
print('ok')
