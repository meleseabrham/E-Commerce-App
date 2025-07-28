import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../services/receipt_service.dart';
import '../orders/order_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../account/address_book_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<CartItem> items;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedPaymentMethod;
  bool showConfirmButton = false;
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _selectedAddress;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('user_addresses')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false);
    setState(() {
      _addresses = List<Map<String, dynamic>>.from(data);
      _selectedAddress = _addresses.firstWhere((a) => a['is_default'] == true, orElse: () => _addresses.isNotEmpty ? _addresses[0] : {});
      _isLoadingAddresses = false;
    });
  }

  void _showAddressSelector() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddressSelectorSheet(addresses: _addresses, selected: _selectedAddress),
    );
    if (selected != null) {
      setState(() {
        _selectedAddress = selected;
      });
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: _isLoadingAddresses
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Address selection section
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(_selectedAddress != null && _selectedAddress!.isNotEmpty
                      ? '${_selectedAddress!['label'] ?? ''}: ${_selectedAddress!['address_line1'] ?? ''}, ${_selectedAddress!['city'] ?? ''}, ${_selectedAddress!['country'] ?? ''}\nPhone: ${_selectedAddress!['phone'] ?? ''}'
                      : 'No address selected'),
                  trailing: TextButton(
                    onPressed: _showAddressSelector,
                    child: Text(_selectedAddress == null || _selectedAddress!.isEmpty ? 'Add Address' : 'Change'),
                  ),
                ),
                if (_addresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No address found. Please add an address.', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPaymentMethods(),
                const SizedBox(height: 24),
                if (selectedPaymentMethod != null) ...[
                  Text(
                    'Enter Payment Details',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: _buildPaymentForm(),
                  ),
                ],
                const SizedBox(height: 24),
                _buildOrderSummary(),
              ],
            ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _buildPaymentMethodCard(
          'CBE',
          'assets/logo/cbe.jpg',
          'Commercial Bank of Ethiopia',
        ),
        _buildPaymentMethodCard(
          'Telebirr',
          'assets/logo/tele.jpg',
          'Mobile Money by Ethio Telecom',
        ),
        _buildPaymentMethodCard(
          'Chapa',
          'assets/logo/chapa.jpg',
          'Digital Payment Platform',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String id, String logo, String description) {
    final isSelected = selectedPaymentMethod == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = id;
            _accountController.clear();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(logo, width: 32, height: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: id,
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value;
                    _accountController.clear();
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    String? hintText;
    String? labelText;
    List<TextInputFormatter>? inputFormatters;
    String? Function(String?)? validator;

    switch (selectedPaymentMethod) {
      case 'CBE':
        hintText = '1000xxxxxxxxxx';
        labelText = 'CBE Account Number';
        inputFormatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(13),
        ];
        validator = (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your CBE account number';
          }
          if (!value.startsWith('1000')) {
            return 'CBE account must start with 1000';
          }
          if (value.length != 13) {
            return 'CBE account must be 13 digits';
          }
          return null;
        };
        break;
      case 'Telebirr':
        hintText = '251xxxxxxxxx';
        labelText = 'Telebirr Mobile Number';
        inputFormatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
        ];
        validator = (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your Telebirr mobile number';
          }
          if (!value.startsWith('251')) {
            return 'Mobile number must start with 251';
          }
          if (value.length != 12) {
            return 'Mobile number must be 12 digits';
          }
          return null;
        };
        break;
      case 'Chapa':
        hintText = 'Enter card number';
        labelText = 'Card Number';
        inputFormatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          CardNumberInputFormatter(),
        ];
        validator = (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your card number';
          }
          value = value.replaceAll(' ', '');
          if (value.length != 16) {
            return 'Card number must be 16 digits';
          }
          if (!_validateCardNumber(value)) {
            return 'Invalid card number';
          }
          return null;
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _accountController,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: (value) {
            setState(() {
              showConfirmButton = value.isNotEmpty;
            });
          },
        ),
        if (selectedPaymentMethod == 'Chapa') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date (MM/YY)',
                    hintText: 'MM/YY',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    ExpiryDateInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length != 5) {
                      return 'Invalid format';
                    }
                    final parts = value.split('/');
                    if (parts.length != 2) return 'Invalid format';
                    final month = int.tryParse(parts[0]);
                    final year = int.tryParse(parts[1]);
                    if (month == null || year == null) return 'Invalid format';
                    if (month < 1 || month > 12) return 'Invalid month';
                    final now = DateTime.now();
                    final cardYear = 2000 + year;
                    if (cardYear < now.year) return 'Card expired';
                    if (cardYear == now.year && month < now.month) return 'Card expired';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length != 3) {
                      return 'Must be 3 digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _validateCardNumber(String number) {
    int sum = 0;
    bool isEven = false;
    
    // Loop through values starting from the rightmost side
    for (var i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    return sum % 10 == 0;
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shadowColor: AppColors.shadow,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.name} (${item.quantity}x)',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${widget.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            // Disable Pay Now unless address and payment method are selected
            onPressed: _isProcessing || _selectedAddress == null || selectedPaymentMethod == null ? null : _processPayment,
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Pay Now',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a payment method'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // Validate payment input
    if (!(_formKey.currentState?.validate() ?? false) || _accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter valid payment details'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final orderId = const Uuid().v4();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final order = {
        'id': orderId,
        'user_id': user.id,
        'items': widget.items.map((item) => item.toMap()).toList(),
        'totalAmount': widget.totalAmount,
        'total': widget.totalAmount,
        'paymentMethod': selectedPaymentMethod ?? '',
        'paymentId': _accountController.text,
        'orderDate': DateTime.now().toIso8601String(),
        'address_id': _selectedAddress?['id'],
        'shipping_address': _selectedAddress,
      };
      await Supabase.instance.client.from('orders').insert(order);

      // Mark all ordered products as sold
      for (final item in widget.items) {
        await Supabase.instance.client
            .from('products')
            .update({'is_sold': true})
            .eq('id', item.productId);
      }

      // Insert a notification for admins
      await Supabase.instance.client.from('notifications').insert({
        'type': 'new_order',
        'message': 'A new order has been placed: #$orderId',
        'order_id': orderId,
        'is_read': false,
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create payment record
      await Supabase.instance.client.from('payments').insert({
        'order_id': orderId,
        'user_id': user.id,
        'method': selectedPaymentMethod,
        'amount': widget.totalAmount,
        'status': 'pending',
      });
      // Clear the cart after successful order
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).clear();
      }
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to order details
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: PurchaseOrder.fromMap(order)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String inputData = newValue.text;
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < inputData.length; i++) {
      buffer.write(inputData[i]);
      int nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != inputData.length) {
        buffer.write(' ');
      }
    }

    String string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(
        offset: string.length,
      ),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String inputData = newValue.text;
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < inputData.length; i++) {
      buffer.write(inputData[i]);
      int nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != inputData.length) {
        buffer.write('/');
      }
    }

    String string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(
        offset: string.length,
      ),
    );
  }
} 

class AddressSelectorSheet extends StatelessWidget {
  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selected;
  const AddressSelectorSheet({required this.addresses, this.selected, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('Select Address', style: TextStyle(fontWeight: FontWeight.bold))),
          ...addresses.map((address) => RadioListTile<Map<String, dynamic>>(
                value: address,
                groupValue: selected,
                title: Text('${address['label'] ?? ''}: ${address['address_line1'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}'),
                onChanged: (val) => Navigator.pop(context, val),
              )),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Add New Address'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddressBookScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
} 