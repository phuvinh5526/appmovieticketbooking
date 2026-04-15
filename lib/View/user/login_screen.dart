import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Components/bottom_nav_bar.dart';
import '../../View/admin/admin_main_screen.dart';
import '../../View/user/register_screen.dart';
import '../../View/user/forgot_password_screen.dart';
import '../../main.dart';
import '../../Components/loading_animation.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/user_service.dart';
import '../../Providers/user_provider.dart';
import '../../Model/User.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _obscureText = true;
  String? emailError;
  String? passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    String input = emailController.text.trim();
    String password = passwordController.text;

    if (input.isEmpty) {
      setState(() {
        emailError = 'Vui lòng nhập email/số điện thoại';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        passwordError = 'Vui lòng nhập mật khẩu';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Kiểm tra tài khoản admin
      if (input.toLowerCase() == 'admin@cinema.com' && password == 'admin') {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminMainScreen()),
        );
        return;
      }

      // 2. Gọi UserService để xác thực thông tin từ Firestore
      final result = await _userService.login(
        emailOrPhone: input,
        password: password,
      );

      if (result['success']) {
        // Lấy email thực tế của người dùng (kể cả khi họ đăng nhập bằng SĐT)
        String actualEmail = result['email'];

        // 3. Đăng nhập vào Firebase Auth bằng email thực tế
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: actualEmail,
          password: password,
        );

        // 4. Lấy dữ liệu người dùng đầy đủ
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        final userData = userDoc.data() as Map<String, dynamic>;
        final user = User.fromJson({...userData, 'id': userCredential.user!.uid});

        setState(() => _isLoading = false);
        
        if (!mounted) return;
        context.read<UserProvider>().setUser(user);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavBar()),
        );
      } else {
        setState(() => _isLoading = false);
        if (result['field'] == 'emailOrPhone') {
          setState(() => emailError = result['message']);
        } else if (result['field'] == 'password') {
          setState(() => passwordError = result['message']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavBar()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xff252429),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff252429), Color(0xff2A2A2A)],
                ),
              ),
              child: CustomPaint(painter: PatternPainter()),
            ),
            Form(
              key: _formKey,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                          ),
                          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 20)],
                        ),
                        child: Icon(Icons.movie_creation_outlined, size: 60, color: Colors.orange),
                      ),
                      SizedBox(height: 30),
                      Text(
                        'Đăng Nhập',
                        style: TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 40),
                      // Input Email/Phone
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: emailController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email/Số điện thoại',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                icon: Icon(Icons.person_outline, color: Colors.orange),
                              ),
                            ),
                            if (emailError != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                child: Text(emailError!, style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Input Password
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: passwordController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                icon: Icon(Icons.lock_outline, color: Colors.orange),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.white38,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              obscureText: _obscureText,
                            ),
                            if (passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                child: Text(passwordError!, style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen())),
                          child: Text('Quên mật khẩu?', style: TextStyle(color: Colors.orange)),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Button Login
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => _login(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text('Đăng Nhập', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())),
                            child: Text('Đăng ký', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: LoadingAnimation(message: "Đang đăng nhập")),
              ),
          ],
        ),
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03)..style = PaintingStyle.fill;
    for (var i = 0; i < size.width; i += 30) {
      for (var j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
