import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { IsBoolean, IsOptional } from 'class-validator';
import { BooleanQuery } from './boolean-query.decorator';

class Fixture {
  @IsOptional()
  @BooleanQuery()
  @IsBoolean()
  flag?: boolean;
}

describe('BooleanQuery — задача 029, п.1 (admin-фильтры были перевёрнуты)', () => {
  it('"false" becomes false, not true (the actual bug: @Type(() => Boolean) turned any non-empty string truthy)', () => {
    const result = plainToInstance(Fixture, { flag: 'false' });
    expect(result.flag).toBe(false);
  });

  it('"true" becomes true', () => {
    const result = plainToInstance(Fixture, { flag: 'true' });
    expect(result.flag).toBe(true);
  });

  it('"0"/"1" are accepted as false/true', () => {
    expect(plainToInstance(Fixture, { flag: '0' }).flag).toBe(false);
    expect(plainToInstance(Fixture, { flag: '1' }).flag).toBe(true);
  });

  it('an absent query param stays undefined (no filter applied), not coerced to false', () => {
    const result = plainToInstance(Fixture, {});
    expect(result.flag).toBeUndefined();
  });
});
