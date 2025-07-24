// lib/presentation/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_contributions_app/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart'; // لاستخدام GoRouter للتنقل

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isPasswordVisible =
      false; // <--- إضافة متغير حالة جديد لإظهار/إخفاء كلمة المرور

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).signIn(_emailController.text.trim(), _passwordController.text.trim());
        // التوجيه يتم التعامل معه بواسطة GoRouter في app.dart بناءً على حالة المصادقة
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(
            'Exception: ',
            '',
          ); // لإزالة "Exception: "
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50, // خلفية فاتحة وأنيقة
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Directionality(
              // لضمان اتجاه النص من اليمين لليسار
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // شعار أو أيقونة المدرسة
                  Icon(
                    Icons.school, // يمكن استبدالها بشعار مخصص لاحقاً
                    size: 100,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'متابعة المساهمات المجتمعية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'سجل الدخول للمتابعة',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 40.0),

                  // حقل البريد الإلكتروني
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.right, // محاذاة النص لليمين
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      hintText: 'ادخل بريدك الإلكتروني',
                      prefixIcon: Icon(
                        Icons.email,
                        color: Colors.blueAccent,
                      ), // أيقونة على اليسار
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'الرجاء إدخال بريد إلكتروني صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // حقل كلمة المرور
                  TextFormField(
                    controller: _passwordController,
                    obscureText:
                        !_isPasswordVisible, // <--- استخدام متغير الحالة هنا
                    textAlign: TextAlign.right, // محاذاة النص لليمين
                    decoration: InputDecoration(
                      // <--- تغيير إلى InputDecoration لتمكين suffixIcon
                      labelText: 'كلمة المرور',
                      hintText: 'ادخل كلمة المرور',
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Colors.blueAccent,
                      ), // أيقونة على اليسار
                      suffixIcon: IconButton(
                        // <--- إضافة زر التبديل هنا
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible =
                                !_isPasswordVisible; // تبديل حالة الرؤية
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30.0),

                  // رسالة الخطأ
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  // زر تسجيل الدخول
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 8, // ظل أكبر للزر
                      shadowColor: Colors.blue.shade300,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                  const SizedBox(height: 20.0),

                  // (اختياري) زر "هل نسيت كلمة المرور؟"
                  TextButton(
                    onPressed: () {
                      // GoRouter.of(context).push('/forgot-password');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'وظيفة استعادة كلمة المرور قيد الإنشاء.',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'هل نسيت كلمة المرور؟',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
