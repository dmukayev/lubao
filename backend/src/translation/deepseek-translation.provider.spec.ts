const createMock = jest.fn();

jest.mock('openai', () => {
  // Пакет openai экспортирует и CJS default, и module.exports сам —
  // `import OpenAI from 'openai'` компилируется ts-jest в обращение
  // через `.default`, поэтому мок должен иметь такую же форму.
  const ctor = jest.fn().mockImplementation(() => ({
    chat: { completions: { create: createMock } },
  }));
  return { __esModule: true, default: ctor };
});

import { DeepSeekTranslationProvider } from './deepseek-translation.provider';

describe('DeepSeekTranslationProvider (задача 010, п.1)', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env = { ...originalEnv, DEEPSEEK_API_KEY: 'test-key', DEEPSEEK_MODEL: 'deepseek-chat' };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('throws at construction if DEEPSEEK_API_KEY is missing', () => {
    delete process.env.DEEPSEEK_API_KEY;
    expect(() => new DeepSeekTranslationProvider()).toThrow('DEEPSEEK_API_KEY');
  });

  it('throws at construction if DEEPSEEK_MODEL is missing (не хардкодить имя модели)', () => {
    delete process.env.DEEPSEEK_MODEL;
    expect(() => new DeepSeekTranslationProvider()).toThrow('DEEPSEEK_MODEL');
  });

  it('calls the configured model with a 5s timeout, json_object format, and the glossary in the system prompt', async () => {
    createMock.mockResolvedValue({ choices: [{ message: { content: '{"zh":"你好"}' } }], usage: { total_tokens: 10 } });
    const provider = new DeepSeekTranslationProvider();

    await provider.translate('Привет', 'ru', ['zh']);

    expect(createMock).toHaveBeenCalledWith(
      expect.objectContaining({
        model: 'deepseek-chat',
        response_format: { type: 'json_object' },
        messages: expect.arrayContaining([
          expect.objectContaining({ role: 'system', content: expect.stringContaining('растаможка') }),
          expect.objectContaining({ role: 'user', content: expect.stringContaining('Привет') }),
        ]),
      }),
      { timeout: 5000 },
    );
  });

  it('returns only the requested target languages, ignoring extras in the model response', async () => {
    createMock.mockResolvedValue({
      choices: [{ message: { content: '{"zh":"你好","en":"hello","kk":"сәлем"}' } }],
      usage: { total_tokens: 12 },
    });
    const provider = new DeepSeekTranslationProvider();

    const result = await provider.translate('Привет', 'ru', ['zh']);

    expect(result.translations).toEqual({ zh: '你好' });
    expect(result.tokensUsed).toBe(12);
  });

  it('returns empty translations without calling the API when source equals the only target', async () => {
    const provider = new DeepSeekTranslationProvider();

    const result = await provider.translate('Привет', 'ru', ['ru']);

    expect(result.translations).toEqual({});
    expect(createMock).not.toHaveBeenCalled();
  });

  it('returns empty translations if the model responds with invalid JSON', async () => {
    createMock.mockResolvedValue({ choices: [{ message: { content: 'not json' } }], usage: { total_tokens: 5 } });
    const provider = new DeepSeekTranslationProvider();

    const result = await provider.translate('Привет', 'ru', ['zh']);

    expect(result.translations).toEqual({});
  });
});
