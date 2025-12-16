import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';
import '../login_screen.dart';
import 'attendance_view.dart';
import 'chat_view.dart';

Future<void> handleLogout(BuildContext context) async {
  try {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }
}

class DashboardLayout extends StatefulWidget {
  final String title;
  final String role;
  final Widget child;

  const DashboardLayout({
    super.key,
    required this.title,
    required this.role,
    required this.child,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  String _currentView = 'dashboard'; // 'dashboard' or 'settings'
  String _userName = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['full_name'] ?? 'User';
        _avatarUrl = user.userMetadata?['avatar_url'];
      });
    }
  }

  void _navigateTo(String view) {
    setState(() {
      _currentView = view;
    });
  }

  void _onProfileUpdated() {
    _fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    // Determine the body content
    Widget bodyContent;
    String displayTitle = widget.title;

    if (_currentView == 'settings') {
      bodyContent = _SettingsView(onProfileUpdated: _onProfileUpdated);
      displayTitle = 'Settings';
    } else if (_currentView == 'attendance') {
      bodyContent = const AttendanceView();
      displayTitle = 'Attendance';
    } else if (_currentView == 'chat') {
      bodyContent = const ChatView();
      displayTitle = 'Team Chat';
    } else {
      bodyContent = widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Light grey bg
      appBar: !isDesktop
          ? AppBar(
              title: Text(
                displayTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: () => handleLogout(context),
                ),
              ],
            )
          : null,
      drawer: !isDesktop
          ? _Sidebar(
              role: widget.role,
              isMobile: true,
              onItemSelected: _navigateTo,
              currentView: _currentView,
              userName: _userName,
              avatarUrl: _avatarUrl,
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            _Sidebar(
              role: widget.role,
              isMobile: false,
              onItemSelected: _navigateTo,
              currentView: _currentView,
              userName: _userName,
              avatarUrl: _avatarUrl,
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  _TopBar(
                    title: displayTitle,
                    role: widget.role,
                    userName: _userName,
                  ),
                Expanded(
                  child: _currentView == 'chat'
                      ? bodyContent
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: bodyContent,
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

class _Sidebar extends StatelessWidget {
  final String role;
  final bool isMobile;
  final Function(String) onItemSelected;
  final String currentView;
  final String userName;
  final String? avatarUrl;

  const _Sidebar({
    required this.role,
    required this.isMobile,
    required this.onItemSelected,
    required this.currentView,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Filter items based on role
    final bool isEmployee = role == 'Employee' || role == 'Team Leader';

    return Container(
      width: 250,
      color: const Color(0xFFEF5350), // Red theme base
      child: Column(
        children: [
          // Logo Area
          Container(
            height: isMobile ? 150 : 80,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: const Color(0xFFD32F2F), // Darker red
            child: Row(
              children: [
                const Icon(Icons.dashboard, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Kanavu\nConnect',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _SidebarItem(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  active: currentView == 'dashboard',
                  onTap: () => onItemSelected('dashboard'),
                ),

                _SidebarItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  active: currentView == 'chat',
                  onTap: () => onItemSelected('chat'),
                ),

                if (isEmployee) ...[
                  _SidebarItem(
                    icon: Icons.fingerprint,
                    label: 'Give Attendance',
                    active: currentView == 'attendance',
                    onTap: () => onItemSelected('attendance'),
                  ),
                ],

                // Hide Users and Orders for Employee
                if (!isEmployee) ...[
                  _SidebarItem(
                    icon: Icons.people,
                    label: 'Users',
                    active: false,
                    onTap: () {},
                  ),
                  _SidebarItem(
                    icon: Icons.shopping_cart,
                    label: 'Orders',
                    active: false,
                    onTap: () {},
                  ),
                ],

                _SidebarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  active: currentView == 'settings',
                  onTap: () => onItemSelected('settings'),
                ),
                const Divider(color: Colors.white24),
                _SidebarItem(
                  icon: Icons.help,
                  label: 'Support',
                  active: false,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // User Info at bottom
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFD32F2F),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isNotEmpty ? userName : role,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// Settings View
class _SettingsView extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const _SettingsView({required this.onProfileUpdated});

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isUploading = false;
  String? _avatarUrl;
  Uint8List? _newImageBytes; // To hold the newly picked image before saving

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _nameController.text = user.userMetadata?['full_name'] ?? '';
          _avatarUrl = user.userMetadata?['avatar_url'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    final Uint8List originalImageBytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _newImageBytes = originalImageBytes;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? newImageUrl;
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Upload new image if exists
      if (_newImageBytes != null) {
        final String fileExt = 'jpg';
        final String fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final String filePath = fileName;
        String contentType = 'image/jpeg';

        await Supabase.instance.client.storage
            .from('Avatar')
            .uploadBinary(
              filePath,
              _newImageBytes!,
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );

        newImageUrl = Supabase.instance.client.storage
            .from('Avatar')
            .getPublicUrl(filePath);
      }

      // 2. Prepare updates
      final newName = _nameController.text.trim();
      final Map<String, dynamic> updates = {};

      if (newName.isNotEmpty) {
        updates['full_name'] = newName;
      }
      if (newImageUrl != null) {
        updates['avatar_url'] = newImageUrl;
      }

      if (updates.isNotEmpty) {
        // Update Auth Metadata
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: updates),
        );

        // Update Profiles Table
        await Supabase.instance.client
            .from('profiles')
            .update(updates)
            .eq('id', user.id);

        widget.onProfileUpdated();

        if (mounted) {
          setState(() {
            if (newImageUrl != null) _avatarUrl = newImageUrl;
            _newImageBytes = null; // Clear picked image
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String message = 'Error updating profile: $e';
        if (e.toString().contains('row-level security') ||
            e.toString().contains('403')) {
          message = 'Permission Denied: Check RLS Policies.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeProfileImage() async {
    if (_avatarUrl == null) return;

    try {
      setState(() => _isLoading = true);

      // Nullify avatar_url in user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': null}),
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'avatar_url': null})
            .eq('id', user.id);
      }

      // Update local state and trigger callback
      widget.onProfileUpdated();

      if (mounted) {
        setState(() {
          _avatarUrl = null;
          _newImageBytes = null; // Also clear pending image
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image removed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Profile Image
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _newImageBytes != null
                            ? MemoryImage(_newImageBytes!)
                            : (_avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null)
                                  as ImageProvider?,
                        child: (_avatarUrl == null && _newImageBytes == null)
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      if (_isUploading)
                        const CircularProgressIndicator(color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickImage,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Photo'),
                      ),
                      if (_avatarUrl != null) ...[
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: _isUploading ? null : _removeProfileImage,
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text('Remove'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String role;
  final String userName;

  const _TopBar({
    required this.title,
    required this.role,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: Colors.grey),
          const SizedBox(width: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Search
          Container(
            width: 200,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 8),
                Text('Search...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          // Logout Button
          ElevatedButton.icon(
            onPressed: () => handleLogout(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final IconData icon;
  final Color iconColor;
  final bool isPositive;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.iconColor,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isPositive)
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 16)
                else
                  const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  subValue,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChartPlaceholder extends StatelessWidget {
  final String title;
  final Color color;
  final double height;

  const ChartPlaceholder({
    super.key,
    required this.title,
    required this.color,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 48, color: color.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
