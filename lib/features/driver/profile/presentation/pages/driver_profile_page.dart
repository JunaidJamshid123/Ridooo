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
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentDriver == null
              ? const Center(child: Text('No driver data'))
              : CustomScrollView(
                  slivers: [
                    // Modern gradient header
                    SliverToBoxAdapter(
                      child: _buildProfileHeader(),
                    ),
                    // Vehicle info card
                    if (_currentDriver!.vehicleModel != null ||
                        _currentDriver!.vehiclePlate != null)
                      SliverToBoxAdapter(
                        child: _buildVehicleCard(),
                      ),
                    // Stats row
                    SliverToBoxAdapter(
                      child: _buildStatsRow(),
                    ),
                    // Menu sections
                    SliverToBoxAdapter(
                      child: _buildMenuSections(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2D2D2D),
            Color(0xFF3D3D3D),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              // Top row with title and edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Driver Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Profile photo and info
              Row(
                children: [
                  // Profile photo with camera button
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFF4A4A4A),
                          backgroundImage: _currentDriver!.profileImage != null
                              ? NetworkImage(_currentDriver!.profileImage!)
                              : null,
                          child: _currentDriver!.profileImage == null
                              ? Text(
                                  _currentDriver!.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _changeProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2ED573), Color(0xFF7BED9F)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2ED573).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Name and contact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentDriver!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Driver badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Verified Driver',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Contact pills
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildContactPill(
                              Icons.email_rounded,
                              _currentDriver!.email,
                            ),
                            if (_currentDriver!.phoneNumber != null)
                              _buildContactPill(
                                Icons.phone_rounded,
                                _currentDriver!.phoneNumber!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      transform: Matrix4.translationValues(0, -20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_currentDriver!.vehicleModel != null)
                Expanded(
                  child: _buildVehicleInfoItem(
                    Icons.time_to_leave_rounded,
                    'Model',
                    _currentDriver!.vehicleModel!,
                    const Color(0xFF3498DB),
                  ),
                ),
              if (_currentDriver!.vehiclePlate != null)
                Expanded(
                  child: _buildVehicleInfoItem(
                    Icons.confirmation_number_rounded,
                    'Plate',
                    _currentDriver!.vehiclePlate!,
                    const Color(0xFF2ECC71),
                  ),
                ),
            ],
          ),
          if (_currentDriver!.licenseNumber != null) ...[
            const SizedBox(height: 12),
            _buildVehicleInfoItem(
              Icons.badge_rounded,
              'License Number',
              _currentDriver!.licenseNumber!,
              const Color(0xFFF39C12),
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleInfoItem(IconData icon, String label, String value, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.only(right: fullWidth ? 0 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          _buildStatCard('4.8', 'Rating', Icons.star_rounded, const Color(0xFFFFA726)),
          const SizedBox(width: 12),
          _buildStatCard('248', 'Trips', Icons.route_rounded, const Color(0xFF42A5F5)),
          const SizedBox(width: 12),
          _buildStatCard('2y', 'Experience', Icons.access_time_rounded, const Color(0xFF66BB6A)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account section
          _buildSectionHeader('Account'),
          const SizedBox(height: 10),
          _buildMenuCard([
            _buildModernMenuItem(
              icon: Icons.person_rounded,
              title: 'Edit Profile',
              subtitle: 'Update your personal info',
              color: const Color(0xFF667EEA),
              onTap: _editProfile,
            ),
            _buildModernMenuItem(
              icon: Icons.history_rounded,
              title: 'Trip History',
              subtitle: 'View past rides',
              color: const Color(0xFF42A5F5),
              onTap: () {},
            ),
            _buildModernMenuItem(
              icon: Icons.directions_car_rounded,
              title: 'Vehicle Details',
              subtitle: 'Manage vehicle info',
              color: const Color(0xFF9CCC65),
              onTap: () {},
              isLast: true,
            ),
          ]),
          const SizedBox(height: 20),
          // Documents section
          _buildSectionHeader('Documents & Earnings'),
          const SizedBox(height: 10),
          _buildMenuCard([
            _buildModernMenuItem(
              icon: Icons.description_rounded,
              title: 'Documents',
              subtitle: 'License, insurance & more',
              color: const Color(0xFFFF7043),
              onTap: () {},
            ),
            _buildModernMenuItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Earnings & Payouts',
              subtitle: 'View your earnings',
              color: const Color(0xFF26A69A),
              onTap: () {},
              isLast: true,
            ),
          ]),
          const SizedBox(height: 20),
          // Support section
          _buildSectionHeader('Support'),
          const SizedBox(height: 10),
          _buildMenuCard([
            _buildModernMenuItem(
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle: 'App preferences',
              color: const Color(0xFF78909C),
              onTap: () {},
            ),
            _buildModernMenuItem(
              icon: Icons.help_rounded,
              title: 'Help & Support',
              subtitle: 'Get assistance',
              color: const Color(0xFF5C6BC0),
              onTap: () {},
            ),
            _buildModernMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              color: const Color(0xFFEF5350),
              onTap: _logout,
              isLast: true,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9E9E9E),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isLast ? 0 : 16),
          bottom: Radius.circular(isLast ? 16 : 0),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
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
