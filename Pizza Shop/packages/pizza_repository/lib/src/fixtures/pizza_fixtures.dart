import '../models/models.dart';

final pizzas = [
  Pizza(
    pizzaId: '1',
    picture: 'assets/pizza1.png',
    name: 'Margherita',
    description: 'Classic cheese and tomato',
    isVeg: true,
    spicy: 1,
    price: Price(sizePrices: {'S': 8.0, 'M': 10.0, 'L': 12.0}),
    macros: Macros(calories: 250, proteins: 10, fats: 8, carbs: 30),
  ),
  Pizza(
    pizzaId: '2',
    picture: 'assets/pizza2.png',
    name: 'Pepperoni',
    description: 'Spicy pepperoni with cheese',
    isVeg: false,
    spicy: 2,
    price: Price(sizePrices: {'S': 9.0, 'M': 11.0, 'L': 13.0}),
    macros: Macros(calories: 300, proteins: 12, fats: 10, carbs: 35),
  ),
];
