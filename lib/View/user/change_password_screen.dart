import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  final UserService _userService = UserService();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Reset errors
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    // Validate inputs
    if (_currentPasswordController.text.isEmpty) {
      setState(() => _currentPasswordError = 'Vui lòng nhập mật khẩu hiện tại');
      return;
    }

    final String newPassword = _newPasswordController.text;
    if (newPassword.isEmpty) {
      setState(() => _newPasswordError = 'Vui lòng nhập mật khẩu mới');
      return;
    }

    // Kiểm tra mật khẩu hợp lệ
    final passwordCheck = _userService.isPasswordValid(newPassword);
    if (!passwordCheck['isValid']) {
      setState(() => _newPasswordError = passwordCheck['message']);
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Vui lòng nhập lại mật khẩu mới');
      return;
    }

    if (newPassword != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Mật khẩu không khớp');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Mã hóa mật khẩu hiện tại để so sánh
      final encryptedCurrentPassword =
          _userService.hashPassword(_currentPasswordController.text);

      // Lấy mật khẩu đã mã hóa từ Firestore để so sánh
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final storedPassword = userDoc.data()?['hashedPassword'];

      // So sánh mật khẩu đã mã hóa
      if (encryptedCurrentPassword != storedPassword) {
        setState(() {
          _currentPasswordError = 'Mật khẩu hiện tại không đúng';
          _isLoading = false;
        });
        return;
      }

      // Mã hóa mật khẩu mới
      final encryptedNewPassword = _userService.hashPassword(newPassword);

      // Cập nhật mật khẩu mới trong Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'hashedPassword': encryptedNewPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật mật khẩu trong Firebase Auth
      await user.updatePassword(newPassword);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Mật khẩu mới không đủ mạnh';
          setState(() => _newPasswordError = errorMessage);
          break;
        case 'requires-recent-login':
          errorMessage = 'Vui lòng đăng nhập lại để thực hiện thao tác này';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
          break;
        default:
          errorMessage = 'Đã có lỗi xảy ra: ${e.message}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required Function(bool) onToggleVisibility,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.orange),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.orange,
                ),
                onPressed: () => onToggleVisibility(!obscureText),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorText: errorText,
            ),
          ),
        ),
        if (label == "Mật khẩu mới")
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mật khẩu phải:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '• Có ít nhất 8 ký tự',
                  style: TextStyle(
                    color: _newPasswordController.text.length >= 8
                        ? Colors.green
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '• Chứa ít nhất 1 chữ cái viết hoa',
                  style: TextStyle(
                    color:
                        RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)
                            ? Colors.green
                            : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '• Chứa ít nhất 1 ký tự đặc biệt',
                  style: TextStyle(
                    color: RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                            .hasMatch(_newPasswordController.text)
                        ? Colors.green
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff252429),
      appBar: AppBar(
        title: Text(
          "Đổi mật khẩu",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xff252429),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff252429),
                  Color(0xff2A2A2A),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: "Mật khẩu hiện tại",
                    obscureText: _obscureCurrentPassword,
                    onToggleVisibility: (value) {
                      setState(() => _obscureCurrentPassword = value);
                    },
                    errorText: _currentPasswordError,
                  ),
                  SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: "Mật khẩu mới",
                    obscureText: _obscureNewPassword,
                    onToggleVisibility: (value) {
                      setState(() => _obscureNewPassword = value);
                    },
                    errorText: _newPasswordError,
                  ),
                  SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: "Nhập lại mật khẩu mới",
                    obscureText: _obscureConfirmPassword,
                    onToggleVisibility: (value) {
                      setState(() => _obscureConfirmPassword = value);
                    },
                    errorText: _confirmPasswordError,
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: Colors.orange.withOpacity(0.5),
                      ),
                      child: Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
