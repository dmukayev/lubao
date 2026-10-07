import { Locale } from '@prisma/client';
import * as path from 'path';
import PDFDocument = require('pdfkit');

const FONT_DIR = path.join(process.cwd(), 'assets', 'fonts');
const LATIN_CYR = path.join(FONT_DIR, 'Onest-Variable.ttf');
const CJK = path.join(FONT_DIR, 'NotoSansSC-Lubao.otf');
const HAS_CJK = /[⺀-鿿豈-﫿＀-￯]/;

type Labels = Record<
  'title' | 'driver' | 'fullName' | 'iin' | 'license' | 'licenseNumber' | 'expiry' | 'tractor' | 'trailer' | 'rigid' | 'plate' | 'vin' | 'pending' | 'noPhoto' | 'unsupported' | 'issued' | 'selfie' | 'identity' | 'passport',
  string
>;

const LABELS: Record<Locale, Labels> = {
  ru: {
    title: 'Документы на рейс', driver: 'Водитель', fullName: 'ФИО', iin: 'ИИН', license: 'Водительское удостоверение', licenseNumber: 'Номер',
    expiry: 'Действует до', tractor: 'Тягач', trailer: 'Прицеп', rigid: 'Грузовик', plate: 'Госномер', vin: 'VIN', pending: 'Машина ещё на проверке',
    noPhoto: 'Фото нет', unsupported: 'Фото в этом формате — откройте в приложении', issued: 'Выдано', selfie: 'Фото водителя', identity: 'Удостоверение личности', passport: 'Техпаспорт',
  },
  kk: {
    title: 'Рейске арналған құжаттар', driver: 'Жүргізуші', fullName: 'Аты-жөні', iin: 'ЖСН', license: 'Жүргізуші куәлігі', licenseNumber: 'Нөмірі',
    expiry: 'Жарамды мерзімі', tractor: 'Тартқыш', trailer: 'Тіркеме', rigid: 'Жүк көлігі', plate: 'Мемлекеттік нөмір', vin: 'VIN', pending: 'Көлік әлі тексерілуде',
    noPhoto: 'Фото жоқ', unsupported: 'Бұл форматтағы фото — қосымшада ашыңыз', issued: 'Берілді', selfie: 'Жүргізушінің фотосы', identity: 'Жеке куәлік', passport: 'Техпаспорт',
  },
  zh: {
    title: '运输单据', driver: '司机', fullName: '姓名', iin: '个人识别号 (IIN)', license: '驾驶证', licenseNumber: '证号',
    expiry: '有效期至', tractor: '牵引车', trailer: '挂车', rigid: '货车', plate: '车牌号', vin: 'VIN', pending: '车辆尚在审核中',
    noPhoto: '无照片', unsupported: '该格式照片请在应用中查看', issued: '出具给', selfie: '司机照片', identity: '身份证', passport: '行驶证',
  },
  en: {
    title: 'Documents for the haul', driver: 'Driver', fullName: 'Full name', iin: 'IIN', license: "Driver's licence", licenseNumber: 'Number',
    expiry: 'Valid until', tractor: 'Tractor unit', trailer: 'Trailer', rigid: 'Truck', plate: 'Plate', vin: 'VIN', pending: 'Vehicle is still being verified',
    noPhoto: 'No photo', unsupported: 'Photo in this format — open it in the app', issued: 'Issued to', selfie: 'Driver photo', identity: 'ID card', passport: 'Registration',
  },
};

export interface PdfImage {
  buffer: Buffer;
  contentType: string;
}

export interface DriverDocumentsPdfInput {
  locale: Locale;
  route: string;
  readyDate: string | null;
  driver: { fullName: string; iin: string | null };
  license: { number: string | null; expiryDate: string | null; documentId: string | null };
  selfieId: string | null;
  identityId: string | null;
  vehicles: Array<{ kind: string; plateNumber: string | null; vin: string | null; brand: string | null; isVerified: boolean; passportId: string | null }>;
  issuedTo: string;
  companyName: string;
  issuedAt: Date;
  images: Map<string, PdfImage>;
}

/// PDF «Документы на рейс» (044 п.1): шапка — маршрут и дата, данные водителя
/// и машин, фото документов по страницам, в подвале — кому и когда выдано.
export function buildDriverDocumentsPdf(input: DriverDocumentsPdfInput): Promise<Buffer> {
  const t = LABELS[input.locale] ?? LABELS.ru;
  const doc = new PDFDocument({ size: 'A4', margin: 48, info: { Title: `${t.title} — Lubao`, Author: 'Lubao' } });
  doc.registerFont('main', LATIN_CYR);
  doc.registerFont('cjk', CJK);
  const chunks: Buffer[] = [];
  doc.on('data', (c: Buffer) => chunks.push(c));
  const done = new Promise<Buffer>((resolve, reject) => {
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });

  // Строка может мешать кириллицу и иероглифы (китайское название компании):
  // у каждого шрифта свой набор глифов — пишем кусками, каждый своим шрифтом.
  const runs = (value: string) => value.split(/([\u2E80-\u9FFF\uF900-\uFAFF\uFF00-\uFFEF]+)/).filter((part) => part.length > 0);
  const write = (value: string, size: number, opts: PDFKit.Mixins.TextOptions, at?: { x: number; y: number }) => {
    doc.fontSize(size);
    const parts = runs(value);
    parts.forEach((part, i) => {
      doc.font(HAS_CJK.test(part) ? 'cjk' : 'main');
      const options = { ...opts, continued: i < parts.length - 1 };
      if (i === 0 && at) doc.text(part, at.x, at.y, options);
      else doc.text(part, options);
    });
  };
  const text = (value: string, size = 11, opts: PDFKit.Mixins.TextOptions = {}) => write(value, size, opts);
  const row = (label: string, value: string | null) => text(`${label}: ${value ?? '—'}`);
  const footer = () => {
    const bottom = doc.page.height - doc.page.margins.bottom + 16;
    const line = `${t.issued}: ${input.issuedTo}, ${input.companyName} · ${input.issuedAt.toISOString().slice(0, 16).replace('T', ' ')} UTC · Lubao`;
    doc.fillColor('#5B6475');
    write(line, 8, { lineBreak: false }, { x: doc.page.margins.left, y: bottom });
    doc.fillColor('#0E1526');
  };
  const photoPage = (caption: string, id: string | null) => {
    doc.addPage();
    text(caption, 14);
    doc.moveDown(0.5);
    const image = id ? input.images.get(id) : undefined;
    if (!image) {
      text(t.noPhoto, 11);
    } else if (!/jpe?g|png/.test(image.contentType)) {
      text(t.unsupported, 11);
    } else {
      doc.image(image.buffer, { fit: [doc.page.width - 96, doc.page.height - 200], align: 'center' });
    }
    footer();
  };

  text(`${t.title}: ${input.route}${input.readyDate ? `, ${input.readyDate}` : ''}`, 16);
  text('Lubao', 9, { characterSpacing: 1 });
  doc.moveDown();
  text(t.driver, 13);
  row(t.fullName, input.driver.fullName);
  row(t.iin, input.driver.iin);
  doc.moveDown(0.5);
  text(t.license, 13);
  row(t.licenseNumber, input.license.number);
  row(t.expiry, input.license.expiryDate);
  for (const v of input.vehicles) {
    doc.moveDown(0.5);
    text(`${v.kind === 'TRAILER' ? t.trailer : v.kind === 'RIGID' ? t.rigid : t.tractor}${v.brand ? ` · ${v.brand}` : ''}`, 13);
    row(t.plate, v.plateNumber);
    row(t.vin, v.vin);
    if (!v.isVerified) text(`! ${t.pending}`, 11);
  }
  footer();

  photoPage(t.selfie, input.selfieId);
  if (input.identityId) photoPage(t.identity, input.identityId);
  photoPage(t.license, input.license.documentId);
  for (const v of input.vehicles) {
    photoPage(`${t.passport} · ${v.kind === 'TRAILER' ? t.trailer : v.kind === 'RIGID' ? t.rigid : t.tractor} ${v.plateNumber ?? ''}`.trim(), v.passportId);
  }
  doc.end();
  return done;
}
