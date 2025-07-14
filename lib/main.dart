import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/categories/categories.dart';
import 'services/firebase_service.dart';
import 'providers/cart_provider.dart';
import 'theme/app_colors.dart';
import 'models/product.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Firebase
  await FirebaseService.initializeFirebase();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MeHal Gebeya',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
              background: Colors.white,
              error: AppColors.error,
            ),
            scaffoldBackgroundColor: Colors.white,
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: AppColors.textPrimary),
              bodyMedium: TextStyle(color: AppColors.textPrimary),
              titleLarge: TextStyle(color: AppColors.textPrimary),
              titleMedium: TextStyle(color: AppColors.textSecondary),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            cardTheme: CardThemeData(
              color: AppColors.surface,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withOpacity(0.1),
              labelStyle: TextStyle(color: AppColors.textPrimary),
              secondaryLabelStyle: TextStyle(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.darkSurface,
              background: AppColors.darkBackground,
              error: AppColors.error,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: AppColors.darkTextPrimary,
              onBackground: AppColors.darkTextPrimary,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
              bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
              titleLarge: TextStyle(color: AppColors.darkTextPrimary),
              titleMedium: TextStyle(color: AppColors.darkTextSecondary),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.darkSurface,
              foregroundColor: AppColors.darkTextPrimary,
              elevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.darkInputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.darkInputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.darkInputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              labelStyle: TextStyle(color: AppColors.darkTextSecondary),
              hintStyle: TextStyle(color: AppColors.darkTextSecondary.withOpacity(0.7)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
            cardTheme: CardThemeData(
              color: AppColors.darkCardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: AppColors.darkInputBackground,
              selectedColor: AppColors.primary.withOpacity(0.3),
              labelStyle: TextStyle(color: AppColors.darkTextPrimary),
              secondaryLabelStyle: TextStyle(color: AppColors.darkTextPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: AppColors.darkCardColor,
              contentTextStyle: TextStyle(color: AppColors.darkTextPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/home',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegistrationScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const HomeScreen(),
            '/account': (context) => const AccountScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/clothing': (context) => ClothingCategoryPage(),
            '/food': (context) => FoodBeverageCategoryPage(),
            '/handicrafts': (context) => HandicraftCategoryPage(),
            '/jewelry': (context) => JewelryCategoryPage(),
            '/electronics': (context) => ElectronicsCategoryPage(),
          },
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Product> products = [
    Product(
      id: '1',
      name: "Coffee Beans",
      price: 120.0,
      image: "assets/coffee.jpg",
      description: "Premium Ethiopian coffee beans",
    ),
    Product(
      id: '2',
      name: "Handwoven Scarf",
      price: 350.0,
      image: "assets/scarf.jpg",
      description: "Traditional Ethiopian design",
    ),
    Product(
      id: '3',
      name: "Teff Flour",
      price: 85.0,
      image: "assets/teff.jpg",
      description: "Organic gluten-free teff",
    ),
    Product(
      id: '4',
      name: "Silver Jewelry",
      price: 600.0,
      image: "assets/jewelry.jpg",
      description: "Handcrafted Ethiopian cross",
    ),
    Product(
      id: '5',
      name: "Honey",
      price: 65.0,
      image: "assets/food/honey.jpg",
      description: "Natural wild honey",
    ),
    Product(
      id: '6',
      name: "Ethiopian Spices",
      price: 45.0,
      image: "assets/food/spices.jpg",
      description: "Traditional spice blend",
    ),
    Product(
      id: '7',
      name: "Traditional Shirt",
      price: 450.0,
      image: "assets/cloth/shirt.jpg",
      description: "Hand-embroidered cotton shirt",
    ),
    Product(
      id: '8',
      name: "Scarf",
      price: 180.0,
      image: "assets/cloth/scarf.jpg",
      description: "Traditional Ethiopian scarf",
    ),
    Product(
      id: '9',
      name: "Dress",
      price: 850.0,
      image: "assets/cloth/dress.jpg",
      description: "Traditional Ethiopian dress",
    ),
    Product(
      id: '10',
      name: "Hat",
      price: 250.0,
      image: "assets/cloth/hat.jpg",
      description: "Traditional Ethiopian hat",
    ),
    Product(
      id: '11',
      name: "Basket",
      price: 120.0,
      image: "assets/handcraft/basket.jpg",
      description: "Hand-woven decorative basket",
    ),
    Product(
      id: '12',
      name: "Pottery",
      price: 180.0,
      image: "assets/handcraft/pottery.jpg",
      description: "Traditional clay pottery",
    ),
    Product(
      id: '13',
      name: "Wood Carving",
      price: 350.0,
      image: "assets/handcraft/woodcarving.jpg",
      description: "Hand-carved wooden art",
    ),
    Product(
      id: '14',
      name: "Leather Bag",
      price: 450.0,
      image: "assets/handcraft/leatherbag.jpg",
      description: "Handmade leather bag",
    ),
    Product(
      id: '15',
      name: "Necklace",
      price: 280.0,
      image: "assets/jewelry/necklace.jpg",
      description: "Traditional Ethiopian necklace",
    ),
    Product(
      id: '16',
      name: "Bracelet",
      price: 150.0,
      image: "assets/jewelry/bracelet.jpg",
      description: "Handcrafted silver bracelet",
    ),
    Product(
      id: '17',
      name: "Earrings",
      price: 120.0,
      image: "assets/jewelry/earrings.jpg",
      description: "Traditional silver earrings",
    ),
    Product(
      id: '18',
      name: "Phone",
      price: 12000.0,
      image: "assets/electronic/phone.jpg",
      description: "Latest smartphone model",
    ),
    Product(
      id: '19',
      name: "Laptop",
      price: 25000.0,
      image: "assets/electronic/laptop.jpg",
      description: "High-performance laptop",
    ),
    Product(
      id: '20',
      name: "Headphones",
      price: 800.0,
      image: "assets/electronic/headphones.jpg",
      description: "Wireless headphones",
    ),
    Product(
      id: '21',
      name: "Smart Watch",
      price: 1500.0,
      image: "assets/electronic/watch.jpg",
      description: "Feature-rich smartwatch",
    ),
  ];

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'M',
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'e',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                TextSpan(
                  text: 'H',
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'al Gebeya',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.primary,
        elevation: 0,

        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '3', 
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        width: 260,
        backgroundColor: Colors.teal[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(color: Colors.black),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.red, size: 30),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.black),
              title: Text(
                'Cart',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Consumer<CartProvider>(
                builder: (context, cart, child) => cart.itemCount > 0
                    ? Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.restaurant, color: Colors.black),
              title: Text(
                'Food & Beverages',
                style: TextStyle(
                  color: Colors.blueGrey, // Change to your desired color
                  fontSize: 17, // Optional: set font size
                  fontWeight: FontWeight.bold, // Optional: bold text
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/food');
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag, color: Colors.black),
              title: Text(
                'Clothing',
                style: TextStyle(
                  color: Colors.blueGrey, // Change to your desired color
                  fontSize: 17, // Optional: set font size
                  fontWeight: FontWeight.bold, // Optional: bold text
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/clothing');
              },
            ),
            ListTile(
              leading: Icon(Icons.handyman, color: Colors.black),

              title: Text(
                'Handicrafts',
                style: TextStyle(
                  color: Colors.blueGrey, // Change to your desired color
                  fontSize: 17, // Optional: set font size
                  fontWeight: FontWeight.bold, // Optional: bold text
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/handicrafts');
              },
            ),
            ListTile(
              leading: Icon(Icons.diamond, color: Colors.black),

              title: Text(
                'Jewelry',
                style: TextStyle(
                  color: Colors.blueGrey, // Change to your desired color
                  fontSize: 17, // Optional: set font size
                  fontWeight: FontWeight.bold, // Optional: bold text
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/jewelry');
              },
            ),

            ListTile(
              leading: Icon(Icons.devices, color: Colors.black),

              title: Text(
                'Electronics',
                style: TextStyle(
                  color: Colors.blueGrey, // Change to your desired color
                  fontSize: 17, // Optional: set font size
                  fontWeight: FontWeight.bold, // Optional: bold text
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/electronics');
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.black),

              title: Text(
                'Account',
                style: TextStyle(
                  color: Colors.blueGrey, // Change to your desired color
                  fontSize: 17, // Optional: set font size
                  fontWeight: FontWeight.bold, // Optional: bold text
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/account');
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Featured Products',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: EdgeInsets.all(10),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        onTap: (index) {
          if (index == 2) {
            Navigator.pushNamed(context, '/account');
          }
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showProductDetail(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  image: DecorationImage(
                    image: AssetImage(product.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Add to Cart'),
                onPressed: () => _addToCart(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(product);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartScreen()),
            );
          },
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(product.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(product.description, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Text('Add to Cart'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PaymentMethodsPage(product: product),
                              ),
                            );
                          },
                          child: Text('Buy Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodsPage extends StatefulWidget {
  final Product product;

  const PaymentMethodsPage({super.key, required this.product});

  @override
  _PaymentMethodsPageState createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  String? selectedPaymentMethod;

  bool showConfirmButton = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Methods')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildPaymentMethod(
                  context,
                  imagePath: 'assets/logo/cbe.jpg',
                  name: 'CBE',
                  color: Colors.purple,
                  method: 'CBE',
                ),
                _buildPaymentMethod(
                  context,
                  imagePath: 'assets/logo/tele.jpg',
                  name: 'Telebirr',
                  color: Colors.indigo,
                  method: 'Telebirr',
                ),
                _buildPaymentMethod(
                  context,
                  imagePath: 'assets/logo/chapa.jpg',
                  name: 'Chapa',
                  color: Colors.black,
                  method: 'Chapa',
                ),
              ],
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: TextStyle(fontSize: 18)),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            if (showConfirmButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _handlePaymentConfirmation(context);
                  },
                  child: Text(
                    'Confirm Payment',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(
    BuildContext context, {
    required String imagePath,
    required String name,
    required Color color,
    required String method,
  }) {
    bool isSelected = selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
          showConfirmButton = true;
        });
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: color, width: 1) : null,
            ),
            child: Image.asset(imagePath, width: 50, height: 50),
          ),
          SizedBox(height: 8),
          Text(name),
        ],
      ),
    );
  }

  void _handlePaymentConfirmation(BuildContext context) {
    if (selectedPaymentMethod == null) return;

    switch (selectedPaymentMethod) {
      case 'CBE':
        _showAccountInputDialog(
          context,
          title: 'Enter CBE Account Number',
          hintText: 'CBE account number',
          maxLength: 13,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account number';
            }
            if (value.length > 13) {
              return 'Account number must be 13 digits or less';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Only numbers are allowed';
            }
            return null;
          },
        );
        break;
      case 'Telebirr':
        _showAccountInputDialog(
          context,
          title: 'Enter Telebirr Phone Number',
          hintText: 'Phone number starting with 251',
          maxLength: 13,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            if (!value.startsWith('251')) {
              return 'Must start with 251';
            }
            if (value.length > 13) {
              return 'Phone number must be 13 digits or less';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Only numbers are allowed';
            }
            return null;
          },
        );
        break;
      case 'Chapa':
        _showAccountInputDialog(
          context,
          title: 'Enter Chapa Account',
          hintText: 'Chapa account details',
          maxLength: 13,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account details';
            }
            return null;
          },
          onSuccess: () {
            _showSuccessDialog(context);
          },
        );
        break;
    }
  }

  void _showAccountInputDialog(
    BuildContext context, {
    required String title,
    required String hintText,
    required int maxLength,
    required String? Function(String?)? validator,
    VoidCallback? onSuccess,
  }) {
    final formKey = GlobalKey<FormState>();
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(hintText: hintText),
                maxLength: maxLength,
                keyboardType: TextInputType.number,
                validator: validator,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    if ((selectedPaymentMethod == 'Chapa' ||
                            selectedPaymentMethod == 'Telebirr' ||
                            selectedPaymentMethod == 'CBE') &&
                        onSuccess == null) {
                      _showSuccessDialog(context);
                    } else {
                      onSuccess?.call();
                    }
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text('Payment Successful!'),
              ],
            ),
            content: Text(
              'Your payment for ${widget.product.name} has been processed successfully.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }
}

class FoodBeverageCategoryPage extends StatelessWidget {
  final List<Product> foodProducts = [
    Product(
      id: 'f1',
      name: "Coffee Beans",
      price: 120.0,
      image: "assets/food/coffee.jpg",
      description: "Premium Ethiopian coffee",
    ),
    Product(
      id: 'f2',
      name: "Teff Flour",
      price: 85.0,
      image: "assets/food/teff.jpg",
      description: "Organic gluten-free teff",
    ),
    Product(
      id: 'f3',
      name: "Honey",
      price: 65.0,
      image: "assets/food/honey.jpg",
      description: "Natural wild honey",
    ),
    Product(
      id: 'f4',
      name: "Spices Pack",
      price: 95.0,
      image: "assets/food/spices.jpg",
      description: "Traditional spice collection",
    ),
  ];

  FoodBeverageCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food & Beverages')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ethiopian Delicacies',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: EdgeInsets.all(10),
              itemCount: foodProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: foodProducts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ClothingCategoryPage extends StatelessWidget {
  final List<Product> clothingProducts = [
    Product(
      id: 'c1',
      name: "Traditional Shirt",
      price: 450.0,
      image: "assets/cloth/shirt.jpg",
      description: "Handwoven cotton shirt",
    ),
    Product(
      id: 'c2',
      name: "Scarf",
      price: 350.0,
      image: "assets/cloth/scarf.jpg",
      description: "Traditional Ethiopian design",
    ),
    Product(
      id: 'c3',
      name: "Dress",
      price: 600.0,
      image: "assets/cloth/dress.jpg",
      description: "Ethiopian cultural dress",
    ),
    Product(
      id: 'c4',
      name: "Hat",
      price: 250.0,
      image: "assets/cloth/hat.jpg",
      description: "Traditional Ethiopian hat",
    ),
  ];

  ClothingCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clothing')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Clothing Collection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: EdgeInsets.all(10),
              itemCount: clothingProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: clothingProducts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HandicraftCategoryPage extends StatelessWidget {
  final List<Product> handicraftProducts = [
    Product(
      id: 'h1',
      name: "Basket",
      price: 280.0,
      image: "assets/handcraft/basket.jpg",
      description: "Handwoven Ethiopian basket",
    ),
    Product(
      id: 'h2',
      name: "Pottery",
      price: 320.0,
      image: "assets/handcraft/pottery.jpg",
      description: "Traditional clay pottery",
    ),
    Product(
      id: 'h3',
      name: "Wood Carving",
      price: 450.0,
      image: "assets/handcraft/woodcarving.jpg",
      description: "Hand-carved wooden art",
    ),
    Product(
      id: 'h4',
      name: "Leather Bag",
      price: 390.0,
      image: "assets/handcraft/leatherbag.jpg",
      description: "Genuine leather bag",
    ),
  ];

  HandicraftCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Handicrafts')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Traditional Handicrafts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: EdgeInsets.all(10),
              itemCount: handicraftProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: handicraftProducts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class JewelryCategoryPage extends StatelessWidget {
  final List<Product> jewelryProducts = [
    Product(
      id: 'j1',
      name: "Silver Cross",
      price: 600.0,
      image: "assets/jewelry/jewelry.jpg",
      description: "Handcrafted Ethiopian cross",
    ),
    Product(
      id: 'j2',
      name: "Gold Necklace",
      price: 1200.0,
      image: "assets/jewelry/necklace.jpg",
      description: "24k gold necklace",
    ),
    Product(
      id: 'j3',
      name: "Bead Bracelet",
      price: 180.0,
      image: "assets/jewelry/bracelet.jpg",
      description: "Colorful bead bracelet",
    ),
    Product(
      id: 'j4',
      name: "Earrings Set",
      price: 350.0,
      image: "assets/jewelry/earrings.jpg",
      description: "Silver traditional earrings",
    ),
  ];

  JewelryCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jewelry')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ethiopian Jewelry',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: EdgeInsets.all(10),
              itemCount: jewelryProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: jewelryProducts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ElectronicsCategoryPage extends StatelessWidget {
  final List<Product> electronicProducts = [
    Product(
      id: 'e1',
      name: "Smartphone",
      price: 4500.0,
      image: "assets/electronic/phone.jpg",
      description: "Latest Android smartphone",
    ),
    Product(
      id: 'e2',
      name: "Laptop",
      price: 12000.0,
      image: "assets/electronic/laptop.jpg",
      description: "High performance laptop",
    ),
    Product(
      id: 'e3',
      name: "Headphones",
      price: 650.0,
      image: "assets/electronic/headphones.jpg",
      description: "Noise cancelling headphones",
    ),
    Product(
      id: 'e4',
      name: "Smart Watch",
      price: 1800.0,
      image: "assets/electronic/watch.jpg",
      description: "Fitness tracking watch",
    ),
  ];

  ElectronicsCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Electronics')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Modern Electronics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: EdgeInsets.all(10),
              itemCount: electronicProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: electronicProducts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _notificationsEnabled = true;
  final int _selectedOption = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Account')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            SizedBox(height: 20),
            Text(
              'User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'shop@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),

            // Personal Information Card
            Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.person, color: Colors.green),
                title: Text('Personal Information'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => _showPersonalInfo(context),
              ),
            ),

            // My Orders Card
            Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.shopping_bag, color: Colors.green),
                title: Text('My Orders'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => _showMyOrders(context),
              ),
            ),

            // Settings Card
            Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.settings, color: Colors.green),
                title: Text('Settings'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => _showSettings(context),
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _logout(context),
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: Text('Personal Information')),
              body: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Full Name', 'John Doe'),
                    _buildInfoRow('Email', 'shop@example.com'),
                    _buildInfoRow('Phone', '+251 912 345 678'),
                    _buildInfoRow('Date of Birth', 'January 1, 1990'),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  void _showMyOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: Text('My Orders')),
              body: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildOrderItem(
                    'ORD-12345',
                    'June 15, 2023',
                    '\$350.00',
                    'Delivered',
                    'assets/cloth/scarf.jpg', // Added image path
                    'Handwoven Scarf', // Added product name
                  ),
                  _buildOrderItem(
                    'ORD-12344',
                    'May 28, 2023',
                    '\$120.00',
                    'Delivered',
                    'assets/food/coffee.jpg', // Added image path
                    'Coffee Beans', // Added product name
                  ),
                  _buildOrderItem(
                    'ORD-12343',
                    'April 10, 2023',
                    '\$600.00',
                    'Cancelled',
                    'assets/jewelry/jewelry.jpg', // Added image path
                    'Silver Cross', // Added product name
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildOrderItem(
    String orderId,
    String date,
    String amount,
    String status,
    String imagePath, // New parameter
    String productName, // New parameter
  ) {
    Color statusColor = status == 'Delivered' ? Colors.green : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderId',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(date),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        amount,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Chip(
                  label: Text(status),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: Text('Settings')),
              body: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Language',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        FilterChip(
                          label: Text('English'),
                          selected: true,
                          onSelected: (bool selected) {},
                        ),
                        FilterChip(
                          label: Text('Amharic'),
                          selected: false,
                          onSelected: (bool selected) {},
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SwitchListTile(
                      title: Text('Enable notifications'),
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveNotificationPreference(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Log Out'),
            content: Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Log Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Image.asset('assets/coffee.jpg', width: 50),
                    title: Text('Coffee Beans'),
                    subtitle: Text('\$120.00'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.remove), onPressed: () {}),
                        Text('1'),
                        IconButton(icon: Icon(Icons.add), onPressed: () {}),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:', style: TextStyle(fontSize: 16)),
                    Text(
                      '\$360.00',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: Text('Checkout', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
