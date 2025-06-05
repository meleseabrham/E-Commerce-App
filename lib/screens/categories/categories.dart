import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';

class ClothingCategoryPage extends StatelessWidget {
  const ClothingCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> products = [
      Product(
        id: 'shirt1',
        name: 'Traditional Shirt',
        price: 450.0,
        image: 'assets/cloth/shirt.jpg',
        description: 'Handwoven cotton shirt',
      ),
      Product(
        id: 'scarf1',
        name: 'Scarf',
        price: 350.0,
        image: 'assets/cloth/scarf.jpg',
        description: 'Traditional Ethiopian design',
      ),
      Product(
        id: 'dress1',
        name: 'Dress',
        price: 600.0,
        image: 'assets/cloth/dress.jpg',
        description: 'Ethiopian cultural dress',
      ),
      Product(
        id: 'hat1',
        name: 'Hat',
        price: 250.0,
        image: 'assets/cloth/hat.jpg',
        description: 'Traditional Ethiopian hat',
      ),
    ];

    return _buildCategoryPage("Clothing", products);
  }
}

class FoodBeverageCategoryPage extends StatelessWidget {
  const FoodBeverageCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> products = [
      Product(
        id: 'coffee1',
        name: 'Coffee Beans',
        price: 120.0,
        image: 'assets/food/coffee.jpg',
        description: 'Premium Ethiopian coffee',
      ),
      Product(
        id: 'teff1',
        name: 'Teff Flour',
        price: 85.0,
        image: 'assets/food/teff.jpg',
        description: 'Organic gluten-free teff',
      ),
      Product(
        id: 'honey1',
        name: 'Honey',
        price: 65.0,
        image: 'assets/food/honey.jpg',
        description: 'Natural wild honey',
      ),
      Product(
        id: 'spices1',
        name: 'Spices Pack',
        price: 95.0,
        image: 'assets/food/spices.jpg',
        description: 'Traditional spice collection',
      ),
    ];

    return _buildCategoryPage("Food & Beverages", products);
  }
}

class HandicraftCategoryPage extends StatelessWidget {
  const HandicraftCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> products = [
      Product(
        id: 'basket1',
        name: 'Basket',
        price: 280.0,
        image: 'assets/handcraft/basket.jpg',
        description: 'Handwoven Ethiopian basket',
      ),
      Product(
        id: 'pottery1',
        name: 'Pottery',
        price: 320.0,
        image: 'assets/handcraft/pottery.jpg',
        description: 'Traditional clay pottery',
      ),
      Product(
        id: 'wood1',
        name: 'Wood Carving',
        price: 450.0,
        image: 'assets/handcraft/woodcarving.jpg',
        description: 'Hand-carved wooden art',
      ),
      Product(
        id: 'bag1',
        name: 'Leather Bag',
        price: 390.0,
        image: 'assets/handcraft/leatherbag.jpg',
        description: 'Genuine leather bag',
      ),
    ];

    return _buildCategoryPage("Handicrafts", products);
  }
}

class JewelryCategoryPage extends StatelessWidget {
  const JewelryCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> products = [
      Product(
        id: 'cross1',
        name: 'Silver Cross',
        price: 600.0,
        image: 'assets/jewelry/jewelry.jpg',
        description: 'Handcrafted Ethiopian cross',
      ),
      Product(
        id: 'necklace1',
        name: 'Gold Necklace',
        price: 1200.0,
        image: 'assets/jewelry/necklace.jpg',
        description: '24k gold necklace',
      ),
      Product(
        id: 'bracelet1',
        name: 'Bead Bracelet',
        price: 180.0,
        image: 'assets/jewelry/bracelet.jpg',
        description: 'Colorful bead bracelet',
      ),
      Product(
        id: 'earrings1',
        name: 'Earrings Set',
        price: 350.0,
        image: 'assets/jewelry/earrings.jpg',
        description: 'Silver traditional earrings',
      ),
    ];

    return _buildCategoryPage("Jewelry", products);
  }
}

class ElectronicsCategoryPage extends StatelessWidget {
  const ElectronicsCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> products = [
      Product(
        id: 'phone1',
        name: 'Smartphone',
        price: 4500.0,
        image: 'assets/electronic/phone.jpg',
        description: 'Latest Android smartphone',
      ),
      Product(
        id: 'laptop1',
        name: 'Laptop',
        price: 12000.0,
        image: 'assets/electronic/laptop.jpg',
        description: 'High performance laptop',
      ),
      Product(
        id: 'headphones1',
        name: 'Headphones',
        price: 650.0,
        image: 'assets/electronic/headphones.jpg',
        description: 'Noise cancelling headphones',
      ),
      Product(
        id: 'watch1',
        name: 'Smart Watch',
        price: 1800.0,
        image: 'assets/electronic/watch.jpg',
        description: 'Fitness tracking watch',
      ),
    ];

    return _buildCategoryPage("Electronics", products);
  }
}

Widget _buildCategoryPage(String title, List<Product> products) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    ),
  );
}

class Categories {
  static List<Product> foodProducts = [
    Product(
      id: 'food1',
      name: 'Ethiopian Coffee',
      price: 15.99,
      image: 'assets/food/coffee.jpg',
      description: 'Premium Ethiopian coffee beans, freshly roasted.',
    ),
    Product(
      id: 'food2',
      name: 'Teff Flour',
      price: 12.99,
      image: 'assets/food/teff.jpg',
      description: 'High-quality teff flour for making injera.',
    ),
    Product(
      id: 'food3',
      name: 'Pure Honey',
      price: 19.99,
      image: 'assets/food/honey.jpg',
      description: 'Natural Ethiopian honey, raw and unfiltered.',
    ),
    Product(
      id: 'food4',
      name: 'Ethiopian Spices',
      price: 9.99,
      image: 'assets/food/spices.jpg',
      description: 'Traditional Ethiopian spice blend.',
    ),
  ];

  static List<Product> clothingProducts = [
    Product(
      id: 'cloth1',
      name: 'Traditional Shirt',
      price: 29.99,
      image: 'assets/cloth/shirt.jpg',
      description: 'Handwoven traditional Ethiopian shirt.',
    ),
    Product(
      id: 'cloth2',
      name: 'Ethiopian Scarf',
      price: 24.99,
      image: 'assets/cloth/scarf.jpg',
      description: 'Beautiful Ethiopian cotton scarf.',
    ),
    Product(
      id: 'cloth3',
      name: 'Traditional Dress',
      price: 79.99,
      image: 'assets/cloth/dress.jpg',
      description: 'Elegant Ethiopian traditional dress.',
    ),
    Product(
      id: 'cloth4',
      name: 'Traditional Hat',
      price: 19.99,
      image: 'assets/cloth/hat.jpg',
      description: 'Authentic Ethiopian traditional hat.',
    ),
  ];

  static List<Product> handcraftProducts = [
    Product(
      id: 'craft1',
      name: 'Woven Basket',
      price: 34.99,
      image: 'assets/handcraft/basket.jpg',
      description: 'Traditional Ethiopian woven basket.',
    ),
    Product(
      id: 'craft2',
      name: 'Clay Pottery',
      price: 39.99,
      image: 'assets/handcraft/pottery.jpg',
      description: 'Handmade Ethiopian clay pottery.',
    ),
    Product(
      id: 'craft3',
      name: 'Wood Carving',
      price: 49.99,
      image: 'assets/handcraft/woodcarving.jpg',
      description: 'Intricate Ethiopian wood carving.',
    ),
    Product(
      id: 'craft4',
      name: 'Leather Bag',
      price: 59.99,
      image: 'assets/handcraft/leatherbag.jpg',
      description: 'Traditional Ethiopian leather bag.',
    ),
  ];

  static List<Product> jewelryProducts = [
    Product(
      id: 'jewel1',
      name: 'Cross Pendant',
      price: 89.99,
      image: 'assets/jewelry/jewelry.jpg',
      description: 'Traditional Ethiopian cross pendant.',
    ),
    Product(
      id: 'jewel2',
      name: 'Necklace',
      price: 129.99,
      image: 'assets/jewelry/necklace.jpg',
      description: 'Handcrafted Ethiopian necklace.',
    ),
    Product(
      id: 'jewel3',
      name: 'Bracelet',
      price: 69.99,
      image: 'assets/jewelry/bracelet.jpg',
      description: 'Traditional Ethiopian bracelet.',
    ),
    Product(
      id: 'jewel4',
      name: 'Earrings',
      price: 49.99,
      image: 'assets/jewelry/earrings.jpg',
      description: 'Ethiopian traditional earrings.',
    ),
  ];

  static List<Product> electronicProducts = [
    Product(
      id: 'elec1',
      name: 'Smartphone',
      price: 299.99,
      image: 'assets/electronic/phone.jpg',
      description: 'Latest smartphone model.',
    ),
    Product(
      id: 'elec2',
      name: 'Laptop',
      price: 899.99,
      image: 'assets/electronic/laptop.jpg',
      description: 'High-performance laptop.',
    ),
    Product(
      id: 'elec3',
      name: 'Headphones',
      price: 79.99,
      image: 'assets/electronic/headphones.jpg',
      description: 'Premium wireless headphones.',
    ),
    Product(
      id: 'elec4',
      name: 'Smart Watch',
      price: 149.99,
      image: 'assets/electronic/watch.jpg',
      description: 'Feature-rich smart watch.',
    ),
  ];
} 