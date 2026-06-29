import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_repository/pizza_repository.dart';
import 'package:pizza_repository/src/models/model.dart';

void main() {
  group('Macros', () {
    test('supports value equality', () {
      expect(
        Macros(calories: 100, proteins: 10, fats: 10, carbs: 10),
        equals(Macros(calories: 100, proteins: 10, fats: 10, carbs: 10)),
      );
    });

    test('copyWith creates a new instance with updated values', () {
      final macros = Macros(calories: 100, proteins: 10, fats: 10, carbs: 10);
      expect(
        macros.copyWith(calories: 200),
        equals(Macros(calories: 200, proteins: 10, fats: 10, carbs: 10)),
      );
    });
  });

  group('Price', () {
    test('supports value equality', () {
      expect(
        Price(sizePrices: {'S': 10.0}),
        equals(Price(sizePrices: {'S': 10.0})),
      );
    });

    test('copyWith creates a new instance with updated values', () {
      final price = Price(sizePrices: {'S': 10.0});
      expect(
        price.copyWith(sizePrices: {'M': 12.0}),
        equals(Price(sizePrices: {'M': 12.0})),
      );
    });
  });

  group('Pizza', () {
    final macros = Macros(calories: 100, proteins: 10, fats: 10, carbs: 10);
    final price = Price(sizePrices: {'S': 10.0});

    test('supports value equality', () {
      expect(
        Pizza(
          pizzaId: '1',
          picture: 'pic',
          name: 'name',
          description: 'desc',
          isVeg: true,
          spicy: 1,
          price: price,
          macros: macros,
        ),
        equals(
          Pizza(
            pizzaId: '1',
            picture: 'pic',
            name: 'name',
            description: 'desc',
            isVeg: true,
            spicy: 1,
            price: price,
            macros: macros,
          ),
        ),
      );
    });

    test('copyWith creates a new instance with updated values', () {
      final pizza = Pizza(
        pizzaId: '1',
        picture: 'pic',
        name: 'name',
        description: 'desc',
        isVeg: true,
        spicy: 1,
        price: price,
        macros: macros,
      );
      expect(
        pizza.copyWith(name: 'new name'),
        equals(
          Pizza(
            pizzaId: '1',
            picture: 'pic',
            name: 'new name',
            description: 'desc',
            isVeg: true,
            spicy: 1,
            price: price,
            macros: macros,
          ),
        ),
      );
    });
  });
}
