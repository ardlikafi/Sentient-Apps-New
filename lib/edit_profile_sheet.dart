import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'firebase_service.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  String? _error;
  File? _newProfileImageFile;
  String? _currentAvatarUrl;
  String? _currentUsername;
  String? _currentPhone;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() => _isLoading = true);
    final userData = await FirebaseService.getCurrentUser();
    if (mounted) {
      if (userData != null) {
        _currentUsername = userData['username'];
        _currentPhone = userData['phone'];

        _usernameController.text = _currentUsername ?? '';
        _phoneController.text = _currentPhone ?? '';

        _currentAvatarUrl = userData['avatar'];
      } else {
        _error = "Gagal memuat data pengguna.";
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _newProfileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    bool success = true;

    try {
      if (_newProfileImageFile != null) {
        final newAvatarUrl = await FirebaseService.uploadAvatar(_newProfileImageFile!);
        if (newAvatarUrl == null) {
          success = false;
        }
      }

      Map<String, dynamic> updates = {};

      if (_usernameController.text.trim() != (_currentUsername ?? '')) {
        updates['username'] = _usernameController.text.trim();
      }

      if (_phoneController.text.trim() != (_currentPhone ?? '')) {
        updates['phone'] = _phoneController.text.trim();
      }

      if (success && updates.isNotEmpty) {
        final result = await FirebaseService.updateUserProfile(updates);
        if (!result) success = false;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          colors: [
            Color(0xFF00207B),
            Color(0xFF001759),
            Color(0xFF000A26),
          ],
          stops: [0.0, 0.33, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
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
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildAvatarEditor(),
            const SizedBox(height: 24),
            _buildTextField(label: 'Username', controller: _usernameController),
            _buildTextField(label: 'Nomor HP', controller: _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            _buildSaveChangesButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarEditor() {
    ImageProvider? imageProvider;
    if (_newProfileImageFile != null) {
      imageProvider = FileImage(_newProfileImageFile!);
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentAvatarUrl!);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade700,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(Icons.add_a_photo, color: Colors.white.withOpacity(0.7), size: 40)
            : null,
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        onPressed: _isLoading ? null : _saveChanges,
        child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}