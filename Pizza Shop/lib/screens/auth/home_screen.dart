import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza/home/blocs/get_pizza_bloc/get_pizza_bloc.dart';
import 'package:pizza_repository/pizza_repository.dart';

import '../../home/views/details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> selectedSizes = [];

  @override
  void initState() {
    super.initState();
    // Trigger pizza loading when screen initializes
    context.read<GetPizzaBloc>().add(GetPizzas());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Row(
          children: [
            Image.asset(
              "assets/1.png",
              height: 30,
              width: 30,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              "PIZZA",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 30,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.cart),
            tooltip: 'Cart',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.arrow_right_to_line),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: BlocBuilder<GetPizzaBloc, GetPizzaState>(
        builder: (context, state) {
          if (state is GetPizzaLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GetPizzaSuccess) {
            final pizzas = state.pizzas;

            // Initialize selected sizes if needed
            if (selectedSizes.isEmpty) {
              selectedSizes = List.generate(pizzas.length, (index) => 'M');
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.70,
                ),
                itemCount: pizzas.length,
                itemBuilder: (context, int index) {
                  final pizza = pizzas[index];
                  // Get price dynamically from the pizza object
                  final currentPrice = pizza.price.getPriceForSize(selectedSizes[index]);

                  return PizzaCard(
                    pizza: pizza,
                    currentPrice: currentPrice,
                    selectedSize: selectedSizes[index],
                    onSizeSelected: (size) {
                      setState(() {
                        selectedSizes[index] = size;
                      });
                    },
                  );
                },
              ),
            );
          } else if (state is GetPizzaFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load pizzas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GetPizzaBloc>().add(GetPizzas());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class PizzaCard extends StatelessWidget {
  final Pizza pizza;
  final double currentPrice;
  final String selectedSize;
  final Function(String) onSizeSelected;

  const PizzaCard({
    super.key,
    required this.pizza,
    required this.currentPrice,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  String _getSpiceLevelText(int spicy) {
    switch (spicy) {
      case 0:
        return 'MILD';
      case 1:
        return 'MEDIUM';
      case 2:
        return 'SPICY';
      case 3:
        return 'BALANCE';
      default:
        return 'MILD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spiceLevel = _getSpiceLevelText(pizza.spicy);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => DetailsScreen(pizza: pizza),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  pizza.picture,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 90,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 40),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: pizza.isVeg ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 6,
                      ),
                      child: Text(
                        pizza.isVeg ? "VEG" : "NON-VEG",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: _getSpiceColor(spiceLevel),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 6,
                      ),
                      child: Text(
                        _getSpiceEmoji(spiceLevel) + spiceLevel,
                        style: TextStyle(
                          color: _getSpiceTextColor(spiceLevel),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                pizza.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                pizza.description,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['S', 'M', 'L', 'XL'].map((size) {
                  return SizeOption(
                    size: size,
                    isSelected: selectedSize == size,
                    onSelected: () => onSizeSelected(size),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rs. ${currentPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle, color: Colors.red),
                    iconSize: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSpiceColor(String spiceLevel) {
    switch (spiceLevel) {
      case 'MILD':
        return Colors.green.withOpacity(0.2);
      case 'MEDIUM':
        return Colors.orange.withOpacity(0.2);
      case 'SPICY':
        return Colors.red.withOpacity(0.2);
      case 'BALANCE':
        return Colors.blue.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getSpiceTextColor(String spiceLevel) {
    switch (spiceLevel) {
      case 'MILD':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'SPICY':
        return Colors.red;
      case 'BALANCE':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getSpiceEmoji(String spiceLevel) {
    switch (spiceLevel) {
      case 'MILD':
        return '🌱';
      case 'MEDIUM':
        return '🌶️';
      case 'SPICY':
        return '🔥';
      case 'BALANCE':
        return '⚖️';
      default:
        return '';
    }
  }
}

class SizeOption extends StatelessWidget {
  final String size;
  final bool isSelected;
  final VoidCallback onSelected;

  const SizeOption({
    super.key,
    required this.size,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey.shade200,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}