import { ValidationOptions, registerDecorator } from 'class-validator';

/// Буквы любого алфавита (\p{L}), пробел, дефис, апостроф, точка; 2-80
/// символов; без цифр. Зеркало клиентского валидатора —
/// packages/lubao_core/lib/src/utils/person_name.dart — держать идентичным.
export const PERSON_NAME_REGEX = /^[\p{L}\s\-'.]{2,80}$/u;

export function IsPersonName(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isPersonName',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate: (value: unknown) => typeof value === 'string' && PERSON_NAME_REGEX.test(value),
        defaultMessage: () => `${propertyName} must be 2-80 letters (any alphabet), spaces, hyphens, apostrophes or periods`,
      },
    });
  };
}
