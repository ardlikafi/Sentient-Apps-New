import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentient/core/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/utils/image_helper.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);

class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const EditProfileSheet({super.key, this.initialUserData});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  File? _newProfileImageFile;
  bool _resetToDefault = false;
  String? _currentAvatarUrl;
  String? _currentUsername;
  String? _currentPhone;

  @override
  void initState() {
    super.initState();
    // 1. Ambil data profil dari widget atau UserProvider secara instan (0 detik)
    if (widget.initialUserData != null) {
      _applyUserData(widget.initialUserData!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cached =
            Provider.of<UserProvider>(context, listen: false).userData;
        if (cached != null && mounted) {
          setState(() {
            _applyUserData(cached);
          });
        }
      });
    }
    // 2. Sinkronkan data terbaru di background tanpa memunculkan layar loading kosong
    _syncFreshDataInBackground();
  }

  void _applyUserData(Map<String, dynamic> data) {
    _currentUsername = data['username']?.toString();
    _currentPhone = data['phone']?.toString();

    _usernameController.text = _currentUsername ?? '';
    _phoneController.text = _currentPhone ?? '';

    _currentAvatarUrl = data['avatar']?.toString();
  }

  Future<void> _syncFreshDataInBackground() async {
    try {
      final fresh = await FirebaseService.getCurrentUser();
      if (fresh != null && mounted) {
        // Hanya update jika user belum mengetik perubahan
        if (_usernameController.text == (_currentUsername ?? '')) {
          _usernameController.text = fresh['username']?.toString() ?? '';
        }
        if (_phoneController.text == (_currentPhone ?? '')) {
          _phoneController.text = fresh['phone']?.toString() ?? '';
        }
        setState(() {
          _currentUsername = fresh['username']?.toString();
          _currentPhone = fresh['phone']?.toString();
          if (_newProfileImageFile == null && !_resetToDefault) {
            _currentAvatarUrl = fresh['avatar']?.toString();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() {
          _newProfileImageFile = File(pickedFile.path);
          _resetToDefault = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetAvatar() {
    setState(() {
      _newProfileImageFile = null;
      _resetToDefault = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo reset to default. Tap "Save Changes" to apply.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newUsername.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username must be at least 3 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newUsername)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Username can only contain letters, numbers, and underscores (_).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    bool success = true;
    String? errorMessage;

    try {
      // 1. Validasi keunikan username jika diubah
      if (newUsername != (_currentUsername ?? '')) {
        final currentUid =
            FirebaseAuth.instance.currentUser?.uid ??
            FirebaseService.getCurrentUserId();
        final isAvailable = await FirebaseService.isUsernameAvailable(
          newUsername,
          excludeUid: currentUid,
        );
        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Username sudah dipakai orang lain!'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      // 2. Upload avatar baru jika ada
      if (success && _resetToDefault) {
        final resetOk = await FirebaseService.resetAvatarToDefault();
        if (!resetOk) {
          success = false;
          errorMessage = 'Failed to reset profile photo.';
        }
      } else if (success && _newProfileImageFile != null) {
        final newAvatarUrl = await FirebaseService.uploadAvatar(
          _newProfileImageFile!,
        );
        if (newAvatarUrl == null) {
          success = false;
          errorMessage = 'Failed to upload profile photo.';
        }
      }

      // 3. Update field data
      if (success) {
        Map<String, dynamic> updates = {};
        if (newUsername != (_currentUsername ?? '')) {
          updates['username'] = newUsername;
          updates['username_lowercase'] = newUsername.toLowerCase();
        }
        if (_phoneController.text.trim() != (_currentPhone ?? '')) {
          updates['phone'] = _phoneController.text.trim();
        }

        if (updates.isNotEmpty) {
          final result = await FirebaseService.updateUserProfile(updates);
          if (!result) {
            success = false;
            errorMessage = 'Failed to update profile data.';
          }
        }
      }

      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).refreshUser();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Failed to save profile changes.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00207B), Color(0xFF001759), Color(0xFF000A26)],
          stops: [0.0, 0.33, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildAvatarEditor(),
            const SizedBox(height: 24),
            _buildTextField(label: 'Username', controller: _usernameController),
            _buildTextField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _buildSaveChangesButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarEditor() {
    ImageProvider? imageProvider;
    if (_resetToDefault) {
      imageProvider = ImageHelper.getImageProvider(null);
    } else if (_newProfileImageFile != null) {
      imageProvider = FileImage(_newProfileImageFile!);
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      imageProvider = ImageHelper.getImageProvider(_currentAvatarUrl);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _isSaving ? null : _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade700,
                backgroundImage: imageProvider,
                child:
                    imageProvider == null
                        ? Icon(
                          Icons.add_a_photo,
                          color: Colors.white.withOpacity(0.7),
                          size: 40,
                        )
                        : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: kPrimaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: const Icon(
                Icons.photo_library,
                size: 16,
                color: kLightBlue,
              ),
              label: const Text(
                'Choose Photo',
                style: TextStyle(color: kLightBlue, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isSaving ? null : _resetAvatar,
              icon: const Icon(Icons.restore, size: 16, color: Colors.white70),
              label: const Text(
                'Reset Photo',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: !_isSaving,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.edit, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveChangesButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSaving ? null : _saveChanges,
        child:
            _isSaving
                ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                : const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
