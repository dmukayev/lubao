import { ArrivalStatus } from '@prisma/client';
import { localDateOnly, localHour, toDateOnly } from '../common/date-only';

/// Правило свежести анонса (задача 040, decisions.md «Точка → город»):
/// отсчёт — от «Я на месте», а не от анонса.
///  1. PLANNED молчит до дня приезда.
///  2. В день приезда — одно напоминание «Доехали?»; день кончился, а
///     «на месте» не нажато — анонс гаснет.
///  3. ON_SITE — «Ещё ищете груз?» через 12 ч после последнего ответа; нет
///     ответа ещё 12 ч — гаснет. Предел — срок ожидания водителя (waitDays).
export const STILL_LOOKING_EVERY_MS = 12 * 60 * 60 * 1000;
const DAY_CHECK_FROM_HOUR = 8;

export type FreshnessArrival = {
  status: ArrivalStatus;
  plannedDay: Date;
  arrivedAt: Date | null;
  lastConfirmedAt: Date | null;
  dayAskedAt: Date | null;
  staleAskedAt: Date | null;
  waitDays: number;
};

export type FreshnessAction = 'NONE' | 'ASK_DAY' | 'ASK_STILL_LOOKING' | 'EXPIRE';

export function decideFreshness(a: FreshnessArrival, now: Date): FreshnessAction {
  if (a.status === 'PLANNED') {
    const today = localDateOnly(now);
    const day = toDateOnly(a.plannedDay);
    if (day < today) return 'EXPIRE';
    if (day === today && !a.dayAskedAt && localHour(now) >= DAY_CHECK_FROM_HOUR) return 'ASK_DAY';
    return 'NONE';
  }

  if (a.status === 'ON_SITE') {
    const since = a.arrivedAt ?? a.plannedDay;
    if (now.getTime() - since.getTime() >= a.waitDays * 24 * 60 * 60 * 1000) return 'EXPIRE';

    const lastAnswer = a.lastConfirmedAt ?? since;
    const askedAfterAnswer = a.staleAskedAt != null && a.staleAskedAt.getTime() >= lastAnswer.getTime();
    if (askedAfterAnswer) {
      return now.getTime() - a.staleAskedAt!.getTime() >= STILL_LOOKING_EVERY_MS ? 'EXPIRE' : 'NONE';
    }
    return now.getTime() - lastAnswer.getTime() >= STILL_LOOKING_EVERY_MS ? 'ASK_STILL_LOOKING' : 'NONE';
  }

  return 'NONE';
}
