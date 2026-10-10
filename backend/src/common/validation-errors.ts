import { BadRequestException, ValidationError } from '@nestjs/common';

/// Поле, не прошедшее проверку DTO, — приложение показывает его по-человечески
/// («Длина внутри, м — не больше 20»), а не общее «Проверьте данные».
export type FieldViolation = { field: string; rule: string; limit?: number };

const LIMIT_RULES = new Set(['max', 'min', 'maxLength', 'minLength', 'arrayMaxSize', 'arrayMinSize']);

export function flattenValidationErrors(errors: ValidationError[], parent = ''): { messages: string[]; fields: FieldViolation[] } {
  const messages: string[] = [];
  const fields: FieldViolation[] = [];
  for (const error of errors) {
    const field = parent ? `${parent}.${error.property}` : error.property;
    // Сначала «не число / не строка», потом пределы: «abc» — это не «больше 20».
    const constraints = Object.entries(error.constraints ?? {}).sort(([a], [b]) => Number(LIMIT_RULES.has(a)) - Number(LIMIT_RULES.has(b)));
    for (const [rule, message] of constraints) {
      messages.push(message);
      // Предел — число в тексте class-validator («must not be greater than 20»,
      // «must be shorter than or equal to 64 characters»).
      const limit = LIMIT_RULES.has(rule) ? Number(message.match(/(-?\d+(?:\.\d+)?)(?!.*\d)/)?.[1]) : NaN;
      fields.push(Number.isFinite(limit) ? { field, rule, limit } : { field, rule });
    }
    if (error.children?.length) {
      const nested = flattenValidationErrors(error.children, field);
      messages.push(...nested.messages);
      fields.push(...nested.fields);
    }
  }
  return { messages, fields };
}

/// `message` — как раньше (массив строк class-validator), плюс `code` и `fields`.
export function validationExceptionFactory(errors: ValidationError[]) {
  const { messages, fields } = flattenValidationErrors(errors);
  return new BadRequestException({ statusCode: 400, error: 'Bad Request', code: 'VALIDATION_FAILED', message: messages, fields });
}
