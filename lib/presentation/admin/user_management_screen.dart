// lib/presentation/admin/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_contributions_app/data/models/user.dart';
import 'package:school_contributions_app/presentation/providers/admin_dashboard_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide AuthProvider; // لإخفاء AuthProvider من Firebase Auth

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // تم إزالة استدعاء _listenToAllUsers() هنا
    // AdminDashboardProvider يقوم بالفعل بالاستماع للمستخدمين في مُنشئه
  }

  // دالة لعرض نموذج إضافة/تعديل المستخدم
  void _showAddEditUserDialog({AppUser? userToEdit}) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AddEditUserDialog(userToEdit: userToEdit),
        );
      },
    );
  }

  // دالة لتأكيد حذف المستخدم
  void _confirmDeleteUser(AppUser user) {
    // الحصول على ScaffoldMessenger قبل فتح الـ dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد أنك تريد حذف المستخدم ${user.email}؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop(); // إغلاق مربع الحوار
                  final provider = Provider.of<AdminDashboardProvider>(
                    dialogContext,
                    listen: false,
                  );
                  await provider.deleteUser(user.id);
                  if (provider.errorMessage == null) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('تم حذف المستخدم بنجاح!')),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(provider.errorMessage!)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<AdminDashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (provider.allUsers.isEmpty) {
              return const Center(
                child: Text(
                  'لا يوجد مستخدمون مسجلون حتى الآن.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.allUsers.length,
              itemBuilder: (context, index) {
                final user = provider.allUsers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الدور: ${user.role == UserRole.admin ? 'مدير' : 'مسؤول فصل'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (user.role == UserRole.classLead &&
                            user.assignedClasses.isNotEmpty)
                          Text(
                            'الفصول المخصصة: ${user.assignedClasses.join(', ')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showAddEditUserDialog(userToEdit: user),
                              tooltip: 'تعديل المستخدم',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteUser(user),
                              tooltip: 'حذف المستخدم',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUserDialog(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.person_add, color: Colors.white),
        tooltip: 'إضافة مستخدم جديد',
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AddEditUserDialog - مربع حوار لإضافة/تعديل المستخدمين
// -----------------------------------------------------------------------------
class AddEditUserDialog extends StatefulWidget {
  final AppUser? userToEdit;

  const AddEditUserDialog({super.key, this.userToEdit});

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.classLead; // الدور الافتراضي
  List<String> _assignedClasses = []; // الفصول المخصصة
  bool _isPasswordVisible = false;
  bool _isCreatingUserInAuth = false; // لحالة تحميل Firebase Auth

  // قائمة بجميع الفصول المتاحة (يمكن جلبها من Firestore في تطبيق حقيقي)
  final List<String> _availableClasses = [
    'الصف الأول أ', 'الصف الأول ب', 'الصف الثاني أ', 'الصف الثاني ب',
    'الصف الثالث أ', 'الصف الثالث ب', 'الصف الرابع أ', 'الصف الرابع ب',
    'الصف الخامس أ', 'الصف الخامس ب', 'الصف السادس أ', 'الصف السادس ب',
    'الصف السابع أ', 'الصف السابع ب', 'الصف الثامن أ', 'الصف الثامن ب',
    'الصف التاسع أ', 'الصف التاسع ب', 'الصف العاشر أ', 'الصف العاشر ب',
    '', // خيار فارغ لعدم تحديد فصل (للسماح بمسؤول فصل بدون فصول محددة)
  ];

  @override
  void initState() {
    super.initState();
    if (widget.userToEdit != null) {
      _emailController.text = widget.userToEdit!.email;
      _selectedRole = widget.userToEdit!.role;
      _assignedClasses = List.from(widget.userToEdit!.assignedClasses);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AdminDashboardProvider>(
        context,
        listen: false,
      );
      String? userId;
      String? errorMessage;
      final scaffoldMessenger = ScaffoldMessenger.of(
        context,
      ); // <--- الحصول على ScaffoldMessenger هنا

      setState(() {
        _isCreatingUserInAuth = true;
      });

      try {
        if (widget.userToEdit == null) {
          // إضافة مستخدم جديد
          // أولاً: إنشاء المستخدم في Firebase Authentication
          final UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );
          userId = userCredential.user!.uid;

          // ثانياً: حفظ بيانات المستخدم والدور في Firestore
          final newUser = AppUser(
            id: userId,
            email: _emailController.text.trim(),
            role: _selectedRole,
            assignedClasses: _selectedRole == UserRole.classLead
                ? _assignedClasses
                : [],
          );
          await provider.addUser(newUser);
          errorMessage = provider.errorMessage; // تحقق من الأخطاء من المزود
        } else {
          // تعديل مستخدم موجود
          final updatedUser = widget.userToEdit!.copyWith(
            role: _selectedRole,
            assignedClasses: _selectedRole == UserRole.classLead
                ? _assignedClasses
                : [],
          );
          await provider.updateUser(updatedUser);
          errorMessage = provider.errorMessage; // تحقق من الأخطاء من المزود
        }

        if (errorMessage == null) {
          Navigator.of(context).pop(); // إغلاق مربع الحوار عند النجاح
          scaffoldMessenger.showSnackBar(
            // <--- استخدام المرجع المحفوظ
            SnackBar(
              content: Text(
                widget.userToEdit == null
                    ? 'تمت إضافة المستخدم بنجاح!'
                    : 'تم تحديث المستخدم بنجاح!',
              ),
            ),
          );
        } else {
          // عرض الخطأ إذا كان هناك مشكلة في Firestore (وليس في Auth)
          scaffoldMessenger.showSnackBar(
            // <--- استخدام المرجع المحفوظ
            SnackBar(content: Text(errorMessage!)),
          );
        }
      } on FirebaseAuthException catch (e) {
        // التعامل مع أخطاء Firebase Auth
        String authError;
        if (e.code == 'weak-password') {
          authError = 'كلمة المرور ضعيفة جداً.';
        } else if (e.code == 'email-already-in-use') {
          authError = 'هذا البريد الإلكتروني مستخدم بالفعل.';
        } else if (e.code == 'invalid-email') {
          authError = 'صيغة البريد الإلكتروني غير صحيحة.';
        } else {
          authError = 'خطأ في المصادقة: ${e.message}';
        }
        scaffoldMessenger.showSnackBar(
          // <--- استخدام المرجع المحفوظ
          SnackBar(content: Text(authError)),
        );
      } catch (e) {
        // التعامل مع أي أخطاء أخرى
        scaffoldMessenger.showSnackBar(
          // <--- استخدام المرجع المحفوظ
          SnackBar(content: Text('حدث خطأ غير متوقع: $e')),
        );
      } finally {
        setState(() {
          _isCreatingUserInAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.userToEdit == null ? 'إضافة مستخدم جديد' : 'تعديل المستخدم',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.right,
                readOnly:
                    widget.userToEdit !=
                    null, // لا يمكن تعديل البريد الإلكتروني للمستخدمين الموجودين
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email),
                  filled:
                      widget.userToEdit !=
                      null, // تظليل الحقل إذا كان للقراءة فقط
                  fillColor: widget.userToEdit != null
                      ? Colors.grey.shade200
                      : null,
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
              const SizedBox(height: 15),
              if (widget.userToEdit ==
                  null) // حقل كلمة المرور يظهر فقط عند إضافة مستخدم جديد
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (widget.userToEdit == null &&
                        (value == null || value.isEmpty)) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value != null && value.length < 6) {
                      return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 15),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'الدور',
                  prefixIcon: Icon(Icons.person),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role == UserRole.admin ? 'مدير' : 'مسؤول فصل'),
                  );
                }).toList(),
                onChanged: (UserRole? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                      // إذا كان الدور مدير، لا توجد فصول مخصصة
                      if (_selectedRole == UserRole.admin) {
                        _assignedClasses = [];
                      }
                    });
                  }
                },
              ),
              if (_selectedRole == UserRole.classLead)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    const Text(
                      'الفصول المخصصة:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: _availableClasses.map((className) {
                        return FilterChip(
                          label: Text(
                            className.isEmpty ? 'لا يوجد فصل' : className,
                          ),
                          selected: _assignedClasses.contains(className),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                if (className.isEmpty) {
                                  // إذا اختار "لا يوجد فصل"، امسح كل الفصول الأخرى
                                  _assignedClasses = [''];
                                } else {
                                  _assignedClasses.remove(
                                    '',
                                  ); // إذا اختار فصلاً، أزل "لا يوجد فصل"
                                  _assignedClasses.add(className);
                                }
                              } else {
                                _assignedClasses.remove(className);
                              }
                            });
                          },
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue.shade800,
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isCreatingUserInAuth ? null : _saveUser,
          child: _isCreatingUserInAuth
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(widget.userToEdit == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    );
  }
}
