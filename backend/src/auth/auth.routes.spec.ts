import { PATH_METADATA } from '@nestjs/common/constants';
import { AuthController } from './auth.controller';

// Пути, которые зашиты в приложение (lubao_core auth_repository.dart): переименование
// модуля уже однажды задело строку маршрута — клиент получал 404.
describe('AuthController — пути, на которые завязан клиент', () => {
  const path = (method: keyof AuthController) => Reflect.getMetadata(PATH_METADATA, AuthController.prototype[method]);

  it('согласие на ПДн, удаление аккаунта, язык', () => {
    expect(path('acceptPdConsent')).toBe('me/pd-consent');
    expect(path('deleteMe')).toBe('me');
    expect(path('setLocale')).toBe('me/locale');
  });
});
