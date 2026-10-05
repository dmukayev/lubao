import { withTimeout } from './with-timeout';

describe('withTimeout (задача 029, п.8)', () => {
  it('resolves with the underlying value when it settles before the deadline', async () => {
    await expect(withTimeout(Promise.resolve('ok'), 1000, 'timed out')).resolves.toBe('ok');
  });

  it('rejects with the underlying error when it rejects before the deadline', async () => {
    await expect(withTimeout(Promise.reject(new Error('boom')), 1000, 'timed out')).rejects.toThrow('boom');
  });

  it('rejects with the timeout message once the deadline passes without the promise settling', async () => {
    jest.useFakeTimers();
    const never = new Promise(() => {});

    const result = withTimeout(never, 1000, 'timed out');
    const assertion = expect(result).rejects.toThrow('timed out'); // прикрепляем обработчик ДО того, как сработает таймер
    await jest.advanceTimersByTimeAsync(1000);
    await assertion;

    jest.useRealTimers();
  });
});
