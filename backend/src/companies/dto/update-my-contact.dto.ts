import { IsOptional, IsString, Length } from 'class-validator';
import { IsPersonName } from '../../common/validators/person-name.validator';

/// «Мой профиль» — контакты СОТРУДНИКА (не компании), которые видит
/// водитель по грузу, который этот сотрудник опубликовал (задача 012,
/// decisions.md «Компания: проверка, роли, контакты»). И владелец, и
/// логист правят это у себя через PATCH /companies/me/contact.
export class UpdateMyContactDto {
  @IsPersonName()
  fullName!: string;

  /// Телефон для водителей — любой код страны (+86, +7…), не привязан к
  /// формату User.phone (который используется для входа по SMS у
  /// водителей, у компаний вход по email).
  @IsOptional()
  @IsString()
  @Length(5, 30)
  contactPhone?: string;

  @IsOptional()
  @IsString()
  @Length(1, 60)
  wechatId?: string;
}
