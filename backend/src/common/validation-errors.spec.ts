import { ValidationPipe } from '@nestjs/common';
import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { validationExceptionFactory } from './validation-errors';

class Dto {
  @IsOptional() @IsNumber() @Min(0) @Max(20) innerLengthM?: number;
  @IsOptional() @IsString() @MaxLength(5) plateNumber?: string;
}

describe('ошибка проверки полей — с полем, правилом и пределом', () => {
  const pipe = new ValidationPipe({ whitelist: true, transform: true, exceptionFactory: validationExceptionFactory });
  const run = (value: unknown) => pipe.transform(value, { type: 'body', metatype: Dto }).then(() => null, (e) => e.getResponse());

  it('длина 50 при пределе 20 → field innerLengthM, rule max, limit 20', async () => {
    const body = await run({ innerLengthM: 50 });
    expect(body.code).toBe('VALIDATION_FAILED');
    expect(body.fields).toEqual([{ field: 'innerLengthM', rule: 'max', limit: 20 }]);
    expect(body.message).toEqual(['innerLengthM must not be greater than 20']);
  });

  it('отрицательное — min 0; длинная строка — maxLength 5', async () => {
    expect((await run({ innerLengthM: -1 })).fields).toEqual([{ field: 'innerLengthM', rule: 'min', limit: 0 }]);
    expect((await run({ plateNumber: '1234567' })).fields).toEqual([{ field: 'plateNumber', rule: 'maxLength', limit: 5 }]);
  });

  it('не число — правило без предела', async () => {
    expect((await run({ innerLengthM: 'abc' })).fields[0]).toEqual({ field: 'innerLengthM', rule: 'isNumber' });
  });
});
