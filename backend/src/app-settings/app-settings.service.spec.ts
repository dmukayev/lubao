import { AppSettingsService } from './app-settings.service';

describe('AppSettingsService', () => {
  it('get returns null for a missing key', async () => {
    const prisma = { appSetting: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AppSettingsService(prisma as any);
    await expect(service.get('defaultPointCityId')).resolves.toBeNull();
  });

  it('get returns the stored value', async () => {
    const prisma = { appSetting: { findUnique: jest.fn().mockResolvedValue({ key: 'k', value: 'v' }) } };
    const service = new AppSettingsService(prisma as any);
    await expect(service.get('k')).resolves.toBe('v');
  });

  it('set upserts by key', async () => {
    const prisma = { appSetting: { upsert: jest.fn().mockResolvedValue(undefined) } };
    const service = new AppSettingsService(prisma as any);
    await service.set('defaultPointCityId', 'city-1');
    expect(prisma.appSetting.upsert).toHaveBeenCalledWith({
      where: { key: 'defaultPointCityId' },
      create: { key: 'defaultPointCityId', value: 'city-1' },
      update: { value: 'city-1' },
    });
  });

  it('all returns a key-value map', async () => {
    const prisma = {
      appSetting: { findMany: jest.fn().mockResolvedValue([{ key: 'a', value: '1' }, { key: 'b', value: '2' }]) },
    };
    const service = new AppSettingsService(prisma as any);
    await expect(service.all()).resolves.toEqual({ a: '1', b: '2' });
  });
});
