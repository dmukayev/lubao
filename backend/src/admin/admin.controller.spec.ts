import { SmsService } from '../sms/sms.service';
import { ForbiddenException } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { RequestContext } from '../common/request-context';

/// Задача 028, п.25: «Все admin-эндпоинты — ADMIN only (тест на 403 для
/// DRIVER/COMPANY)». Вместо ручного списка из полсотни методов (который
/// неизбежно разъедется с контроллером при следующей задаче) — перебираем
/// ВСЕ методы прототипа через reflection: `assertAdmin(ctx)` у каждого
/// метода — первая строка тела, до обращения к любому другому параметру,
/// так что вызов с не-ADMIN контекстом и фиктивными (undefined) остальными
/// аргументами должен упасть с `ForbiddenException`, не трогая `AdminService`.
describe('AdminController — every endpoint is ADMIN only (задача 028, п.25)', () => {
  const methodNames = Object.getOwnPropertyNames(AdminController.prototype).filter((name) => name !== 'constructor');

  function nonAdminContext(role: 'DRIVER' | 'COMPANY'): RequestContext {
    return { user: { id: 'u1', role } as never, driver: null, companyMember: null, sessionId: 's1' };
  }

  async function expectForbidden(invoke: () => unknown) {
    try {
      const result = invoke();
      await result;
      throw new Error('Expected the call to throw/reject with ForbiddenException, but it did not');
    } catch (e) {
      expect(e).toBeInstanceOf(ForbiddenException);
    }
  }

  it('lists at least the endpoints this task added, so the reflection list itself cannot silently shrink', () => {
    expect(methodNames).toEqual(
      expect.arrayContaining(['updateDriver', 'updateCompany', 'setMemberRole', 'removeMember', 'cargoDetail', 'dealDetail', 'resolveComplaint', 'updatePoint', 'updateCity']),
    );
  });

  it.each(['DRIVER', 'COMPANY'] as const)('every controller method throws ForbiddenException for role=%s', async (role) => {
    const adminService = {} as AdminService; // ни один метод не должен быть вызван
    const appSettings = {} as AppSettingsService;
    const controller = new AdminController(adminService, appSettings, {} as SmsService, {} as never) as unknown as Record<string, (...args: unknown[]) => unknown>;
    const ctx = nonAdminContext(role);

    for (const name of methodNames) {
      await expectForbidden(() => controller[name](ctx, undefined, undefined, undefined, undefined, undefined));
    }
  });
});
