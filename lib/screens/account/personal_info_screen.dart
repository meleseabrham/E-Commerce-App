import 'package:flutter/material.dart';
import 'package:mehal_gebeya/utils/app_notify.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      var data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        final metadata = user.userMetadata ?? {};
        final newProfile = {
          'id': user.id,
          'email': user.email ?? '',
          'full_name': metadata['full_name'] ?? metadata['name'] ?? '',
          'avatar_url': metadata['avatar_url'] ?? metadata['picture'] ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'is_admin': false,
        };
        try {
          await Supabase.instance.client.from('users').upsert(newProfile);
          data = newProfile;
        } catch (_) {
          data = newProfile;
        }
      }

      if (mounted) {
        setState(() {
          _userProfile = data;
          _isLoading = false;
          _nameController.text = data?['full_name'] ?? '';
          _phoneController.text = data?['phone'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotify.error(context, 'Failed to load profile: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.from('users').update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }).eq('id', user.id);
      
      if (mounted) {
        AppNotify.success(context, 'Profile updated successfully!');
        // Reload profile to refresh the UI
        _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        AppNotify.error(context, 'Failed to update profile: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (_userProfile?['avatar_url'] ?? '').toString().isNotEmpty
                          ? NetworkImage(_userProfile!['avatar_url'])
                          : const AssetImage('assets/profile.jpg') as ImageProvider,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                      onTap: () {
                        print('Phone field focused');
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userProfile?['email'] ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await _saveProfile();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 