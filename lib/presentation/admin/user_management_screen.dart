// lib/presentation/admin/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_contributions_app/data/models/user.dart';
import 'package:school_contributions_app/presentation/providers/admin_dashboard_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // <--- تم التعديل هنا: استدعاء fetchAllUsers() بدلاً من listenToAllUsers() --->
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminDashboardProvider>(
        context,
        listen: false,
      ).fetchAllUsers();
    });
  }

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

  void _confirmDeleteUser(AppUser user) {
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
                  Navigator.of(dialogContext).pop();
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
                        if (user.role == UserRole.classLead) ...[
                          Text(
                            'تعديل الدفعات: ${user.canEditPayments ? 'مسموح' : 'غير مسموح'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            'عرض الطلاب: ${user.canViewStudents ? 'مسموح' : 'غير مسموح'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
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
        tooltip: 'إضافة مستخدم جديد',
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

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
  UserRole _selectedRole = UserRole.classLead;
  List<String> _assignedClasses = [];
  bool _isPasswordVisible = false;
  bool _isCreatingUserInAuth = false;

  bool _canEditPayments = true;
  bool _canViewStudents = true;

  final List<String> _availableClasses = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.userToEdit != null) {
      _emailController.text = widget.userToEdit!.email;
      _selectedRole = widget.userToEdit!.role;
      _assignedClasses = List.from(widget.userToEdit!.assignedClasses);
      _canEditPayments = widget.userToEdit!.canEditPayments;
      _canViewStudents = widget.userToEdit!.canViewStudents;
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
      String? errorMessage;
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      setState(() {
        _isCreatingUserInAuth = true;
      });

      try {
        if (widget.userToEdit == null) {
          final UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );
          final String userId = userCredential.user!.uid;

          final newUser = AppUser(
            id: userId,
            email: _emailController.text.trim(),
            role: _selectedRole,
            assignedClasses: _selectedRole == UserRole.classLead
                ? _assignedClasses
                : [],
            canEditPayments: _selectedRole == UserRole.classLead
                ? _canEditPayments
                : false,
            canViewStudents: _selectedRole == UserRole.classLead
                ? _canViewStudents
                : false,
          );
          await provider.addUser(newUser);
          errorMessage = provider.errorMessage;
        } else {
          final updatedUser = widget.userToEdit!.copyWith(
            role: _selectedRole,
            assignedClasses: _selectedRole == UserRole.classLead
                ? _assignedClasses
                : [],
            canEditPayments: _selectedRole == UserRole.classLead
                ? _canEditPayments
                : false,
            canViewStudents: _selectedRole == UserRole.classLead
                ? _canViewStudents
                : false,
          );
          await provider.updateUser(updatedUser);
          errorMessage = provider.errorMessage;
        }

        if (errorMessage == null) {
          Navigator.of(context).pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                widget.userToEdit == null
                    ? 'تمت إضافة المستخدم بنجاح!'
                    : 'تم تحديث المستخدم بنجاح!',
              ),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } on FirebaseAuthException catch (e) {
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
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(authError)));
      } catch (e) {
        scaffoldMessenger.showSnackBar(
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
                readOnly: widget.userToEdit != null,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email),
                  filled: widget.userToEdit != null,
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
              if (widget.userToEdit == null)
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
                      if (_selectedRole == UserRole.admin) {
                        _assignedClasses = [];
                        _canEditPayments = false;
                        _canViewStudents = false;
                      } else {
                        _canEditPayments = true;
                        _canViewStudents = true;
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
                                  _assignedClasses = [''];
                                } else {
                                  _assignedClasses.remove('');
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
                    const SizedBox(height: 15),
                    SwitchListTile(
                      title: const Text('السماح بتعديل الدفعات الشهرية'),
                      value: _canEditPayments,
                      onChanged: (bool value) {
                        setState(() {
                          _canEditPayments = value;
                        });
                      },
                      secondary: const Icon(Icons.payments),
                      activeColor: Colors.green,
                    ),
                    SwitchListTile(
                      title: const Text('السماح بعرض بيانات الطلاب'),
                      value: _canViewStudents,
                      onChanged: (bool value) {
                        setState(() {
                          _canViewStudents = value;
                        });
                      },
                      secondary: const Icon(Icons.visibility),
                      activeColor: Colors.green,
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
