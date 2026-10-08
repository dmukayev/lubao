import { CargoBody, DriverBody, cargoFitsBody } from './profile-fit';

// 048 п.5, п.8: отсев ленты по профилю кузова.
const tent: DriverBody = { profile: 'VOLUME', capacityTons: 20, volumeM3: 90, palletsEuro: 33, specs: { capacityTons: 20 } };
const tank: DriverBody = { profile: 'TANK', capacityTons: null, volumeM3: null, palletsEuro: null, specs: { liters: 30000, product: 'FOOD' } };
const cargo = (over: Partial<CargoBody>): CargoBody => ({ profiles: ['VOLUME'], weightKg: null, volumeM3: null, palletCount: null, specs: null, ...over });

describe('cargoFitsBody', () => {
  it('груз «цистерна, 20 000 л» виден цистерне и не виден тенту', () => {
    const tankCargo = cargo({ profiles: ['TANK'], specs: { cargoProduct: 'FOOD', cargoLiters: 20000 } });
    expect(cargoFitsBody(tankCargo, tank)).toBe(true);
    expect(cargoFitsBody(tankCargo, tent)).toBe(false);
  });

  it('цистерна: больше литров или другой продукт — не подходит', () => {
    expect(cargoFitsBody(cargo({ profiles: ['TANK'], specs: { cargoProduct: 'FOOD', cargoLiters: 40000 } }), tank)).toBe(false);
    expect(cargoFitsBody(cargo({ profiles: ['TANK'], specs: { cargoProduct: 'FUEL', cargoLiters: 1000 } }), tank)).toBe(false);
  });

  it('объёмный: вес, м³ и паллеты как раньше; у цистерны паллеты не проверяются', () => {
    expect(cargoFitsBody(cargo({ weightKg: 25000 }), tent)).toBe(false);
    expect(cargoFitsBody(cargo({ volumeM3: 100 }), tent)).toBe(false);
    expect(cargoFitsBody(cargo({ palletCount: 30 }), tent)).toBe(true);
  });

  it('автовоз — по числу машин, контейнеровоз — по типу контейнера', () => {
    const cars: DriverBody = { profile: 'CAR_CARRIER', capacityTons: null, volumeM3: null, palletsEuro: null, specs: { carSlots: 8 } };
    expect(cargoFitsBody(cargo({ profiles: ['CAR_CARRIER'], specs: { carCount: 6 } }), cars)).toBe(true);
    expect(cargoFitsBody(cargo({ profiles: ['CAR_CARRIER'], specs: { carCount: 10 } }), cars)).toBe(false);
    const box: DriverBody = { profile: 'CONTAINER', capacityTons: null, volumeM3: null, palletsEuro: null, specs: { containerTypes: ['20', '40'] } };
    expect(cargoFitsBody(cargo({ profiles: ['CONTAINER'], specs: { containerType: '45' } }), box)).toBe(false);
    expect(cargoFitsBody(cargo({ profiles: ['CONTAINER'], specs: { containerType: '40' } }), box)).toBe(true);
  });

  it('груз для нескольких кузовов виден любому из них; профиль машины неизвестен — не прячем', () => {
    expect(cargoFitsBody(cargo({ profiles: ['PLATFORM', 'VOLUME'] }), tent)).toBe(true);
    expect(cargoFitsBody(cargo({ profiles: ['TANK'] }), { ...tent, profile: null })).toBe(true);
  });
});
