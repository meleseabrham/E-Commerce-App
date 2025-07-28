import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/account/account_screen.dart'; // Do not import AdminDashboardScreen from here
import 'screens/settings/settings_screen.dart';
import 'providers/cart_provider.dart';
import 'theme/app_colors.dart';
import 'models/product.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin/admin_products_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_categories_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/admin_audit_logs_screen.dart';
import 'screens/admin/admin_analysis_screen.dart';
import 'screens/orders/my_orders_screen.dart';
import 'providers/wishlist_provider.dart';
import 'screens/account/personal_info_screen.dart';
import 'screens/account/change_password_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()), // <-- Add this line
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
            '/products': (context) => const AdminProductsScreen(),
            '/dashboard': (context) => const AdminDashboardScreen(),
            '/categories': (context) => const AdminCategoriesScreen(),
            '/users': (context) => const AdminUsersScreen(),
            '/orders': (context) => const AdminOrdersScreen(),
            '/my_orders': (context) => const MyOrdersScreen(),
            '/orders/all': (context) => const AdminOrdersScreen(status: 'all'),
            '/orders/accepted': (context) => const AdminOrdersScreen(status: 'accepted'),
            '/orders/rejected': (context) => const AdminOrdersScreen(status: 'rejected'),
            '/orders/pending': (context) => const AdminOrdersScreen(status: 'pending'),
            '/audit_logs': (context) => const AdminAuditLogsScreen(),
            '/analytics': (context) => const AdminAnalysisScreen(),
            '/personal_info': (context) => const PersonalInfoScreen(),
            '/change_password': (context) => const ChangePasswordScreen(),
          },
        );
      },
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
                    image: AssetImage(product.imageUrl), // Use product image
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
                  product.name, // Use product name
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}', // Use product price
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
    cartProvider.addItem(product); // Assuming product is not null here
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'), // Use product name
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
