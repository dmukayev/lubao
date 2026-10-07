#!/usr/bin/env python3
"""Синтетические документы для e2e и ручной проверки распознавания.

Всё вымышлено: ФИО, ИИН/БИН (контрольная сумма верна), USCC (GB 32100),
номера, адреса. Картинки «как с телефона»: лёгкий поворот, перспектива,
неровный свет, шум, JPEG. Результат — test-data/synthetic/ (можно
коммитить и использовать в автотестах, в отличие от test-data/private/).

Запуск: python3 scripts/synthetic-docs.py   (нужен Pillow)
Шрифты: Onest из lubao_core; для китайского — SYNTH_CJK_FONT или STHeiti (macOS).
"""
import os
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'test-data' / 'synthetic'
FONT = str(ROOT / 'packages/lubao_core/assets/fonts/Onest-Variable.ttf')
CJK_FONT = os.environ.get('SYNTH_CJK_FONT', '/System/Library/Fonts/STHeiti Medium.ttc')

# --- контрольные суммы (те же правила, что backend/src/recognition/checksums.ts)

def iin_check(first11: str) -> str:
    d = [int(c) for c in first11]
    for w in ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2]):
        r = sum(a * b for a, b in zip(d, w)) % 11
        if r != 10:
            return str(r)
    raise ValueError('нет контрольной цифры — смените серийный номер')

USCC_ALPHABET = '0123456789ABCDEFGHJKLMNPQRTUWXY'
USCC_WEIGHTS = [1, 3, 9, 27, 19, 26, 16, 17, 20, 29, 25, 13, 8, 24, 10, 30, 28]

def uscc_check(first17: str) -> str:
    s = sum(USCC_ALPHABET.index(c) * w for c, w in zip(first17, USCC_WEIGHTS)) % 31
    return USCC_ALPHABET[0 if s == 0 else 31 - s]

# Вымышленные данные — используются и в e2e (см. integration_test/synthetic_docs.dart).
DRIVER_IIN = '880412300' + '57' + iin_check('88041230057')    # 12.04.1988, мужчина
COMPANY_BIN = '200540' + '01234' + iin_check('20054001234')   # юрлицо, рег. 05.2020
COMPANY_USCC = '91650100MA7TEKD0' + '1'
COMPANY_USCC += uscc_check(COMPANY_USCC)

# --- рисование

def font(size, cjk=False):
    return ImageFont.truetype(CJK_FONT if cjk else FONT, size)

def phone_photo(card: Image.Image, seed: int, canvas=(1200, 1600)) -> Image.Image:
    """Карточка на столе: поворот, перспектива, свет, шум."""
    rnd = random.Random(seed)
    bg = Image.new('RGB', canvas, (rnd.randint(120, 150), rnd.randint(100, 120), rnd.randint(80, 95)))
    card = card.convert('RGBA').rotate(rnd.uniform(-4, 4), expand=True, resample=Image.BICUBIC)
    x = (canvas[0] - card.width) // 2 + rnd.randint(-30, 30)
    y = (canvas[1] - card.height) // 2 + rnd.randint(-40, 40)
    shadow = Image.new('RGBA', card.size, (0, 0, 0, 90))
    shadow.putalpha(card.getchannel('A').point(lambda a: 90 if a else 0))
    bg.paste(shadow, (x + 12, y + 14), shadow.filter(ImageFilter.GaussianBlur(10)))
    bg.paste(card, (x, y), card)
    w, h = bg.size
    d = rnd.randint(15, 35)
    bg = bg.transform(bg.size, Image.QUAD, (d, 0, 0, h, w, h - d, w - d // 2, d // 2), resample=Image.BICUBIC)
    # Неровный свет: затемнение к одному углу.
    grad = Image.linear_gradient('L').resize(bg.size).rotate(rnd.choice([30, 120, 210, 300]))
    bg = Image.composite(bg, Image.new('RGB', bg.size, (30, 30, 30)), grad.point(lambda v: 170 + v * 85 // 255))
    noise = Image.effect_noise(bg.size, 18).convert('RGB')
    bg = Image.blend(bg, noise, 0.06).filter(ImageFilter.GaussianBlur(0.6))
    return bg

def save(img: Image.Image, name: str):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, 'JPEG', quality=82)
    print('→', (OUT / name).relative_to(ROOT))

def driver_license():
    """Права РК нового образца (поля по Венской конвенции: 1, 2, 3, 4a–4d, 5, 9)."""
    card = Image.new('RGB', (1000, 630), (236, 228, 214))
    dr = ImageDraw.Draw(card)
    dr.rectangle((0, 0, 1000, 90), fill=(170, 200, 220))
    dr.text((30, 18), 'ҚАЗАҚСТАН РЕСПУБЛИКАСЫ  ЖҮРГІЗУШІ КУӘЛІГІ', font=font(30), fill=(20, 40, 80))
    dr.text((30, 54), 'ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ', font=font(26), fill=(20, 40, 80))
    dr.rectangle((30, 120, 270, 430), fill=(205, 205, 210), outline=(150, 150, 150), width=2)
    dr.ellipse((95, 160, 205, 290), fill=(170, 150, 135))
    dr.rectangle((80, 300, 220, 430), fill=(90, 100, 120))
    rows = [
        ('1.', 'ТЕСТОВ'),
        ('2.', 'ЕРЛАН БОЛАТОВИЧ'),
        ('3.', '12.04.1988'),
        ('4a.', '15.05.2019   4b. 15.05.2029'),
        ('4c.', 'МВД РК'),
        ('4d.', DRIVER_IIN),
        ('5.', 'KZ 0812345'),
        ('9.', 'B, C, CE'),
    ]
    for i, (k, v) in enumerate(rows):
        dr.text((300, 120 + i * 58), k, font=font(30), fill=(60, 60, 60))
        dr.text((370, 120 + i * 58), v, font=font(34), fill=(15, 15, 15))
    save(phone_photo(card, 11), 'kz-driver-license.jpg')

def selfie():
    img = Image.new('RGB', (900, 1200), (200, 210, 220))
    dr = ImageDraw.Draw(img)
    dr.rectangle((0, 800, 900, 1200), fill=(60, 70, 90))
    dr.ellipse((250, 250, 650, 750), fill=(205, 170, 140))
    dr.ellipse((340, 420, 380, 460), fill=(40, 30, 30))
    dr.ellipse((520, 420, 560, 460), fill=(40, 30, 30))
    dr.arc((380, 520, 520, 640), 20, 160, fill=(120, 60, 60), width=8)
    dr.chord((230, 180, 670, 450), 180, 360, fill=(50, 40, 35))
    save(img.filter(ImageFilter.GaussianBlur(1.2)), 'selfie.jpg')

def kz_company_registration():
    """Справка о государственной регистрации юрлица (eGov) — вымышленное ТОО."""
    page = Image.new('RGB', (900, 1200), (250, 250, 247))
    dr = ImageDraw.Draw(page)
    lines = [
        (40, 'АНЫҚТАМА', 34), (40, 'СПРАВКА', 34),
        (24, 'о государственной регистрации юридического лица', 26),
        (40, '', 20),
        (24, 'БИН', 26), (0, COMPANY_BIN, 34),
        (24, 'Наименование', 26), (0, 'ТОО Тестовый Логистик Сервис', 32),
        (24, 'Дата государственной регистрации', 26), (0, '18.05.2020', 32),
        (24, 'Местонахождение', 26), (0, 'г. Алматы, ул. Вымышленная, 101', 30),
        (24, 'Руководитель', 26), (0, 'ТЕСТОВА АЙГУЛЬ МАРАТОВНА', 30),
        (40, '', 20),
        (24, 'Справка является документом, подтверждающим', 22),
        (0, 'государственную регистрацию юридического лица', 22),
    ]
    y = 60
    for gap, text, size in lines:
        y += gap
        if text:
            dr.text((70, y), text, font=font(size), fill=(20, 20, 20))
            y += size + 12
    dr.rectangle((620, 960, 840, 1160), outline=(30, 30, 30), width=3)
    for i in range(0, 200, 16):
        for j in range(0, 200, 16):
            if (i * 7 + j * 3) % 5 < 2:
                dr.rectangle((624 + i, 964 + j, 636 + i, 976 + j), fill=(30, 30, 30))
    save(phone_photo(page, 21, canvas=(1200, 1600)), 'kz-company-registration.jpg')

def cn_business_license():
    """营业执照 — вымышленная компания, USCC с верной контрольной цифрой."""
    page = Image.new('RGB', (1000, 1300), (252, 248, 240))
    dr = ImageDraw.Draw(page)
    dr.rectangle((20, 20, 980, 1280), outline=(190, 60, 50), width=10)
    dr.text((330, 70), '营 业 执 照', font=font(64, cjk=True), fill=(190, 40, 40))
    dr.text((80, 190), '统一社会信用代码', font=font(30, cjk=True), fill=(20, 20, 20))
    dr.text((80, 235), COMPANY_USCC, font=font(40), fill=(20, 20, 20))
    rows = [
        ('名　　称', '乌鲁木齐测试物流有限公司'),
        ('类　　型', '有限责任公司'),
        ('法定代表人', '张测试'),
        ('注册资本', '伍佰万元整'),
        ('成立日期', '2020年05月18日'),
        ('住　　所', '新疆乌鲁木齐市虚构路88号'),
        ('经营范围', '道路货物运输；国际货运代理'),
    ]
    for i, (k, v) in enumerate(rows):
        dr.text((80, 340 + i * 100), k, font=font(32, cjk=True), fill=(60, 60, 60))
        dr.text((300, 340 + i * 100), v, font=font(34, cjk=True), fill=(15, 15, 15))
    dr.text((560, 1110), '登记机关', font=font(30, cjk=True), fill=(60, 60, 60))
    dr.ellipse((700, 1040, 900, 1240), outline=(200, 50, 50), width=6)
    save(phone_photo(page, 31, canvas=(1300, 1700)), 'cn-business-license.jpg')

if __name__ == '__main__':
    driver_license()
    selfie()
    kz_company_registration()
    cn_business_license()
    print('ИИН водителя', DRIVER_IIN, '· БИН', COMPANY_BIN, '· USCC', COMPANY_USCC)
