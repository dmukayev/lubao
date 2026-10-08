import { BODY_TYPE_PROFILES } from '../../prisma/body-type-profiles';
import { validateSpecs } from './specs';

// 048 п.2, п.8: specs машины/груза проверяются по полям типа кузова.
const TANK = BODY_TYPE_PROFILES.TANK.fields;
const TENT = BODY_TYPE_PROFILES.TENT.fields;
const CONTAINER = BODY_TYPE_PROFILES.CONTAINER.fields;
const CARS = BODY_TYPE_PROFILES.CARCARRIER.fields;

describe('validateSpecs', () => {
  it('цистерна: литры и продукт обязательны, лишнее (паллеты) отбрасывается', () => {
    expect(validateSpecs(TANK, { liters: 30000, product: 'FOOD', sections: 3, palletsEuro: 33 }, 'vehicle')).toEqual({ liters: 30000, product: 'FOOD', sections: 3 });
    expect(() => validateSpecs(TANK, { liters: 30000 }, 'vehicle')).toThrow();
    try {
      validateSpecs(TANK, { liters: 5, product: 'MILK' }, 'vehicle');
    } catch (e: any) {
      expect(e.response.errors).toEqual(['liters: out of range 1000..60000', 'product: one of FUEL,FOOD,CHEMICAL,GAS']);
    }
  });

  it('тент: грузоподъёмность обязательна, м³ и паллеты — числа', () => {
    expect(validateSpecs(TENT, { capacityTons: '20', volumeM3: 90, palletsEuro: 33 }, 'vehicle')).toEqual({ capacityTons: 20, volumeM3: 90, palletsEuro: 33 });
    expect(() => validateSpecs(TENT, { volumeM3: 'много', capacityTons: 20 }, 'vehicle')).toThrow();
  });

  it('контейнеровоз: несколько типов контейнеров; груз — один тип', () => {
    expect(validateSpecs(CONTAINER, { containerTypes: ['20', '40', '40'] }, 'vehicle')).toEqual({ containerTypes: ['20', '40'] });
    expect(validateSpecs(CONTAINER, { containerType: '45', containerCount: 1 }, 'cargo')).toEqual({ containerType: '45', containerCount: 1 });
    expect(() => validateSpecs(CONTAINER, { containerTypes: ['50'] }, 'vehicle')).toThrow();
  });

  it('предпочтение из регистрации — только «основа» и всё необязательно; у автовоза без тоннажа', () => {
    expect(validateSpecs(CARS, { carSlots: 8, closed: true, capacityTons: 20 }, 'preferred')).toEqual({ carSlots: 8 });
    expect(validateSpecs(CARS, {}, 'preferred')).toEqual({});
    expect(validateSpecs(TANK, { liters: 20000, product: 'FUEL', sections: 2 }, 'preferred')).toEqual({ liters: 20000, product: 'FUEL' });
  });

  it('груз автовоза: число машин обязательно, тип — из списка', () => {
    expect(validateSpecs(CARS, { carCount: 6, carType: 'SUV' }, 'cargo')).toEqual({ carCount: 6, carType: 'SUV' });
    expect(() => validateSpecs(CARS, { carType: 'SUV' }, 'cargo')).toThrow();
  });
});
