import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../../../../core/config/supabase_config.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../../auth/domain/entities/user.dart' as app_user;

/// Driver profile page showing driver account info and options
class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  app_user.User? _currentDriver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserJson = prefs.getString('CACHED_USER');
      
      if (cachedUserJson != null) {
        final userModel = UserModel.fromJson(jsonDecode(cachedUserJson));
        setState(() {
          _currentDriver = userModel.toEntity();
          _isLoading = false;
        });
      } else {
        // Fetch from Supabase if not cached
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;
        
        if (userId != null) {
          final response = await supabase
              .from(SupabaseConfig.usersTable)
              .select()
              .eq('id', userId)
              .single();
          
          final userModel = UserModel.fromJson(response);
          setState(() {
            _currentDriver = userModel.toEntity();
            _isLoading = false;
          });
          
          // Cache the user
          await prefs.setString('CACHED_USER', jsonEncode(userModel.toJson()));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (_currentDriver == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDriverProfilePage(driver: _currentDriver!),
      ),
    );
    
    if (result == true) {
      _loadDriverProfile(); // Reload profile after edit
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    
    // Show options: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_currentDriver?.profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context, null);
                  _removeProfilePicture();
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      await _uploadProfilePicture(File(image.path));
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final supabase = Supabase.instance.client;
      final userId = _currentDriver!.id;
      
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'profile_picture.$fileExt';
      final filePath = '$userId/$fileName';

      // Upload to Supabase Storage
      await supabase.storage.from('avatars').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      // Update driver profile in database
      await supabase.from(SupabaseConfig.usersTable).update({
        'profile_image': imageUrl,
      }).eq('id', userId);

      // Update cached user
      final updatedDriver = UserModel(
        id: _currentDriver!.id,
        name: _currentDriver!.name,
        email: _currentDriver!.email,
        phoneNumber: _currentDriver!.phoneNumber,
        profileImage: imageUrl,
        role: _currentDriver!.role,
        licenseNumber: _currentDriver!.licenseNumber,
        vehicleModel: _currentDriver!.vehicleModel,
        vehiclePlate: _currentDriver!.vehiclePlate,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('CACHED_USER', jsonEncode(updatedDriver.toJson()));

      if (mounted) {
        Navigator.pop(context); // Close loading
        _loadDriverProfile(); // Reload profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final supabase = Supabase.instance.client;
      final userId = _currentDriver!.id;

      // Delete from storage if exists
      if (_currentDriver!.profileImage != null) {
        final fileExt = _currentDriver!.profileImage!.split('.').last.split('?').first;
        try {
          await supabase.storage.from('avatars').remove(['$userId/profile_picture.$fileExt']);
        } catch (e) {
          // Ignore if file doesn't exist
        }
      }

      // Update driver profile in database
      await supabase.from(SupabaseConfig.usersTable).update({
        'profile_image': null,
      }).eq('id', userId);

      // Update cached user
      final updatedDriver = UserModel(
        id: _currentDriver!.id,
        name: _currentDriver!.name,
        email: _currentDriver!.email,
        phoneNumber: _currentDriver!.phoneNumber,
        profileImage: null,
        role: _currentDriver!.role,
        licenseNumber: _currentDriver!.licenseNumber,
        vehicleModel: _currentDriver!.vehicleModel,
        vehiclePlate: _currentDriver!.vehiclePlate,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('CACHED_USER', jsonEncode(updatedDriver.toJson()));

      if (mounted) {
        Navigator.pop(context); // Close loading
        _loadDriverProfile(); // Reload profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentDriver == null
              ? const Center(child: Text('No driver data'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Profile photo with edit button
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _currentDriver!.profileImage != null
                                ? NetworkImage(_currentDriver!.profileImage!)
                                : null,
                            child: _currentDriver!.profileImage == null
                                ? Text(
                                    _currentDriver!.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changeProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        _currentDriver!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        _currentDriver!.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (_currentDriver!.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currentDriver!.phoneNumber!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Driver-specific info card
                      if (_currentDriver!.vehicleModel != null ||
                          _currentDriver!.vehiclePlate != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.local_taxi, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Vehicle Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_currentDriver!.vehicleModel != null)
                                _buildInfoRow('Model', _currentDriver!.vehicleModel!),
                              if (_currentDriver!.vehiclePlate != null)
                                _buildInfoRow('Plate', _currentDriver!.vehiclePlate!),
                              if (_currentDriver!.licenseNumber != null)
                                _buildInfoRow('License', _currentDriver!.licenseNumber!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Menu items
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: _editProfile,
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'Trip History',
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.directions_car,
                        title: 'Vehicle Details',
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.description,
                        title: 'Documents',
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.account_balance_wallet,
                        title: 'Earnings & Payouts',
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        onTap: _logout,
                        textColor: Colors.red,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// Edit Driver Profile Page
class EditDriverProfilePage extends StatefulWidget {
  final app_user.User driver;

  const EditDriverProfilePage({super.key, required this.driver});

  @override
  State<EditDriverProfilePage> createState() => _EditDriverProfilePageState();
}

class _EditDriverProfilePageState extends State<EditDriverProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _licenseNumberController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _emailController = TextEditingController(text: widget.driver.email);
    _phoneController = TextEditingController(text: widget.driver.phoneNumber ?? '');
    _vehicleModelController = TextEditingController(text: widget.driver.vehicleModel ?? '');
    _vehiclePlateController = TextEditingController(text: widget.driver.vehiclePlate ?? '');
    _licenseNumberController = TextEditingController(text: widget.driver.licenseNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Update in Supabase
      await supabase.from(SupabaseConfig.usersTable).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'vehicle_model': _vehicleModelController.text.trim(),
        'vehicle_plate': _vehiclePlateController.text.trim(),
        'license_number': _licenseNumberController.text.trim(),
      }).eq('id', widget.driver.id);

      // Update cached user
      final updatedDriver = UserModel(
        id: widget.driver.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImage: widget.driver.profileImage,
        role: widget.driver.role,
        licenseNumber: _licenseNumberController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        vehiclePlate: _vehiclePlateController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('CACHED_USER', jsonEncode(updatedDriver.toJson()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              // Vehicle Information Section
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'e.g., Toyota Corolla 2020',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehiclePlateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                  hintText: 'e.g., ABC-1234',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Driver License Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
