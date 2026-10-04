import { PERSON_NAME_REGEX } from './person-name.validator';

describe('PERSON_NAME_REGEX', () => {
  it.each(['Ерлан Қасымов', 'Ли Вэй', '李伟', "John O'Neil"])('accepts "%s"', (value) => {
    expect(PERSON_NAME_REGEX.test(value)).toBe(true);
  });

  it.each([
    ['digits', 'Ерлан2'],
    ['too short', 'A'],
    ['too long', 'A'.repeat(81)],
    ['empty', ''],
  ])('rejects %s', (_label, value) => {
    expect(PERSON_NAME_REGEX.test(value)).toBe(false);
  });
});
