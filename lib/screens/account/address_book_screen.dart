import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

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
      _isLoading = false;
    });
  }

  Future<void> _addOrEditAddress({Map<String, dynamic>? address}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: address?['address_line1'] ?? '');
    final labelController = TextEditingController(text: address?['label'] ?? '');
    final cityController = TextEditingController(text: address?['city'] ?? '');
    final countryController = TextEditingController(text: address?['country'] ?? '');
    final phoneController = TextEditingController(text: address?['phone'] ?? '+251');
    final isDefault = ValueNotifier<bool>(address?['is_default'] ?? false);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(address == null ? 'Add Address' : 'Edit Address'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: labelController, decoration: InputDecoration(labelText: 'Label (e.g. Home, Work)')),
              TextField(controller: controller, decoration: InputDecoration(labelText: 'Address Line 1')),
              TextField(controller: cityController, decoration: InputDecoration(labelText: 'City')),
              TextField(controller: countryController, decoration: InputDecoration(labelText: 'Country')),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Phone (+251...)'),
                maxLength: 13,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    // Always start with +251
                    if (!newValue.text.startsWith('+251')) {
                      return oldValue;
                    }
                    // Prevent deleting +251
                    if (newValue.selection.start < 4) {
                      return oldValue;
                    }
                    // Only allow 7 or 9 as the next digit after +251
                    if (newValue.text.length >= 5) {
                      final nextDigit = newValue.text[4];
                      if (nextDigit != '7' && nextDigit != '9') {
                        return oldValue;
                      }
                    }
                    // Only allow numbers after +251
                    if (newValue.text.length > 4) {
                      final afterPrefix = newValue.text.substring(4);
                      if (!RegExp(r'^[79][0-9]*').hasMatch(afterPrefix)) {
                        return oldValue;
                      }
                    }
                    // Enforce max length
                    if (newValue.text.length > 13) {
                      return oldValue;
                    }
                    return newValue;
                  }),
                ],
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isDefault,
                builder: (context, value, _) => CheckboxListTile(
                  value: value,
                  onChanged: (v) => isDefault.value = v ?? false,
                  title: Text('Set as default'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (!RegExp(r'^\+251[79]\d{8}$').hasMatch(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Phone must start with +2517 or +2519 and be 13 digits.')),
                );
                return;
              }
              final data = {
                'user_id': user.id,
                'label': labelController.text,
                'address_line1': controller.text,
                'city': cityController.text,
                'country': countryController.text,
                'phone': phone,
                'is_default': isDefault.value,
              };
              if (address == null) {
                await Supabase.instance.client.from('user_addresses').insert(data);
              } else {
                await Supabase.instance.client.from('user_addresses').update(data).eq('id', address['id']);
              }
              Navigator.pop(context);
              _fetchAddresses();
            },
            child: Text(address == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(String id) async {
    await Supabase.instance.client.from('user_addresses').delete().eq('id', id);
    _fetchAddresses();
  }

  Future<void> _setDefault(String id) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // Unset all
    await Supabase.instance.client.from('user_addresses').update({'is_default': false}).eq('user_id', user.id);
    // Set selected
    await Supabase.instance.client.from('user_addresses').update({'is_default': true}).eq('id', id);
    _fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Addresses')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(child: Text('No address found. Please add an address.'))
              : ListView.builder(
              itemCount: _addresses.length,
              itemBuilder: (context, i) {
                final address = _addresses[i];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(address['is_default'] == true ? Icons.star : Icons.location_on),
                    title: Text(address['label'] ?? ''),
                    subtitle: Text('${address['address_line1'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _addOrEditAddress(address: address),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteAddress(address['id']),
                        ),
                        if (address['is_default'] != true)
                          IconButton(
                            icon: Icon(Icons.star_border),
                            tooltip: 'Set as default',
                            onPressed: () => _setDefault(address['id']),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditAddress(),
        child: Icon(Icons.add),
        tooltip: 'Add Address',
      ),
    );
  }
} 