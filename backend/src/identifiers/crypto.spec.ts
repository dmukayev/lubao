import { decryptIdentifier, encryptIdentifier, hashIdentifier, maskIdentifier } from './crypto';

const OLD_ENV = process.env;

describe('identifiers crypto — задача 031, этап C, п.11/16', () => {
  beforeEach(() => {
    process.env = {
      ...OLD_ENV,
      IDENTIFIER_PEPPER: 'test-pepper',
      IDENTIFIER_KEY: 'a'.repeat(64), // 32 bytes hex
    };
  });

  afterEach(() => {
    process.env = OLD_ENV;
  });

  describe('hashIdentifier', () => {
    it('is deterministic for the same value and pepper', () => {
      expect(hashIdentifier('850712300123')).toBe(hashIdentifier('850712300123'));
    });

    it('differs for different values', () => {
      expect(hashIdentifier('850712300123')).not.toBe(hashIdentifier('850712300124'));
    });

    it('differs when the pepper changes (the whole point of a pepper)', () => {
      const first = hashIdentifier('850712300123');
      process.env.IDENTIFIER_PEPPER = 'different-pepper';
      expect(hashIdentifier('850712300123')).not.toBe(first);
    });

    it('throws if IDENTIFIER_PEPPER is not configured', () => {
      delete process.env.IDENTIFIER_PEPPER;
      expect(() => hashIdentifier('x')).toThrow('IDENTIFIER_PEPPER is not configured');
    });
  });

  describe('encryptIdentifier / decryptIdentifier', () => {
    it('round-trips a value', () => {
      const packed = encryptIdentifier('850712300123');
      expect(decryptIdentifier(packed)).toBe('850712300123');
    });

    it('produces a different ciphertext each time (random IV) even for the same value', () => {
      expect(encryptIdentifier('850712300123')).not.toBe(encryptIdentifier('850712300123'));
    });

    it('throws if IDENTIFIER_KEY is not configured', () => {
      delete process.env.IDENTIFIER_KEY;
      expect(() => encryptIdentifier('x')).toThrow('IDENTIFIER_KEY is not configured');
    });
  });

  describe('maskIdentifier', () => {
    it('masks the middle of a sensitive type (IIN), keeping head and tail visible', () => {
      expect(maskIdentifier('IIN', '850712300123')).toBe('8507••••0123');
    });

    it('fully masks a short sensitive value', () => {
      expect(maskIdentifier('DRIVER_LICENSE_NO', 'AB1234')).toBe('••••••');
    });

    it('does not mask non-sensitive types — plate numbers are already public', () => {
      expect(maskIdentifier('PLATE', '123ABC02')).toBe('123ABC02');
      expect(maskIdentifier('PHONE', '+77011234501')).toBe('+77011234501');
    });
  });
});
