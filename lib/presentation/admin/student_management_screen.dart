// lib/presentation/admin/student_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:school_contributions_app/presentation/providers/admin_dashboard_provider.dart';
import 'package:school_contributions_app/data/models/user.dart'; // لاستخدام UserRole في AddEditStudentDialog

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String? _selectedClassFilter; // <--- جديد: فلتر الصف المختار
  String? _selectedSectionFilter; // <--- جديد: فلتر الشعبة المختار

  // قائمة الصفوف المتاحة للفلترة (يمكن أن تكون ديناميكية لاحقًا)
  final List<String> _availableClassesFilter = [
    'الصف الأول أ',
    'الصف الأول ب',
    'الصف الثاني أ',
    'الصف الثاني ب',
    'الصف الثالث أ',
    'الصف الثالث ب',
    'الصف الرابع أ',
    'الصف الرابع ب',
    'الصف الخامس أ',
    'الصف الخامس ب',
    'الصف السادس أ',
    'الصف السادس ب',
    'الصف السابع أ',
    'الصف السابع ب',
    'الصف الثامن أ',
    'الصف الثامن ب',
    'الصف التاسع أ',
    'الصف التاسع ب',
    'الصف العاشر أ',
    'الصف العاشر ب',
  ];

  // قائمة الشعب المتاحة للفلترة (يمكن أن تكون ديناميكية لاحقًا)
  final List<String> _availableSectionsFilter = ['أ', 'ب', 'ج', 'د', 'هـ'];

  @override
  void initState() {
    super.initState();
    // AdminDashboardProvider يقوم بالفعل بالاستماع للطلاب في مُنشئه.
    // لا حاجة لاستدعاء listenToAllStudents() هنا.
  }

  // دالة لفلترة الطلاب بناءً على الفلاتر المختارة
  List<Student> _getFilteredStudents(List<Student> allStudents) {
    if (_selectedClassFilter == null && _selectedSectionFilter == null) {
      return allStudents; // إذا لم يتم اختيار أي فلاتر، أظهر جميع الطلاب
    }

    return allStudents.where((student) {
      bool matchesClass = true;
      bool matchesSection = true;

      if (_selectedClassFilter != null) {
        matchesClass = student.className == _selectedClassFilter;
      }
      if (_selectedSectionFilter != null) {
        matchesSection = student.section == _selectedSectionFilter;
      }
      return matchesClass && matchesSection;
    }).toList();
  }

  void _showAddEditStudentDialog({Student? studentToEdit}) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AddEditStudentDialog(studentToEdit: studentToEdit),
        );
      },
    );
  }

  void _confirmDeleteStudent(Student student) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
              'هل أنت متأكد أنك تريد حذف الطالب ${student.studentName}؟',
            ),
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
                  await provider.deleteStudent(student.id);
                  if (provider.errorMessage == null) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('تم حذف الطالب بنجاح!')),
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

  Future<void> _importStudents() async {
    final provider = Provider.of<AdminDashboardProvider>(
      context,
      listen: false,
    );
    await provider.parseStudentsFromCsv();

    if (provider.errorMessage != null &&
        provider.parsedStudentsForImport.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      _showCsvValidationDialog(
        context,
        provider.parsedStudentsForImport,
        provider.csvValidationErrors,
      );
    }
  }

  void _showCsvValidationDialog(
    BuildContext dialogContext,
    List<Student> validStudents,
    List<String> errors,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: dialogContext,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نتائج التحقق من ملف CSV'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تم العثور على ${validStudents.length} طالبًا صالحًا للاستيراد.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'تم العثور على ${errors.length} أخطاء/تحذيرات:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ...errors.map(
                      (error) => Text(
                        '- $error',
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  ],
                  if (validStudents.isEmpty && errors.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'لن يتم استيراد أي طلاب بسبب الأخطاء المذكورة أعلاه.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              if (validStudents.isNotEmpty)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final provider = Provider.of<AdminDashboardProvider>(
                      dialogContext,
                      listen: false,
                    );
                    await provider.performCsvImport();
                    if (provider.errorMessage == null) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('تم استيراد الطلاب بنجاح!'),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(provider.errorMessage!)),
                      );
                    }
                  },
                  child: const Text('استيراد'),
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
      appBar: AppBar(
        title: const Text('إدارة الطلاب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importStudents,
            tooltip: 'استيراد طلاب من ملف CSV',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<AdminDashboardProvider>(
          builder: (context, provider, child) {
            final filteredStudents = _getFilteredStudents(
              provider.allStudents,
            ); // <--- استخدام الطلاب المفلترين

            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null && provider.allStudents.isEmpty) {
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

            return Column(
              children: [
                // <--- منطقة الفلاتر الجديدة
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedClassFilter,
                          decoration: const InputDecoration(
                            labelText: 'فلتر الصف',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          hint: const Text('جميع الصفوف'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('جميع الصفوف'),
                            ),
                            ..._availableClassesFilter.map((className) {
                              return DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedClassFilter = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSectionFilter,
                          decoration: const InputDecoration(
                            labelText: 'فلتر الشعبة',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          hint: const Text('جميع الشعب'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('جميع الشعب'),
                            ),
                            ..._availableSectionsFilter.map((section) {
                              return DropdownMenuItem(
                                value: section,
                                child: Text(section),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSectionFilter = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _selectedClassFilter = null;
                            _selectedSectionFilter = null;
                          });
                        },
                        tooltip: 'مسح الفلاتر',
                      ),
                    ],
                  ),
                ),

                // نهاية منطقة الفلاتر الجديدة --->
                if (filteredStudents.isEmpty &&
                    (_selectedClassFilter != null ||
                        _selectedSectionFilter != null))
                  const Expanded(
                    child: Center(
                      child: Text(
                        'لا يوجد طلاب مطابقون للفلاتر المختارة.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (filteredStudents.isEmpty &&
                    provider.allStudents.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'لا يوجد طلاب مسجلون حتى الآن.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: filteredStudents
                          .length, // <--- استخدام الطلاب المفلترين هنا
                      itemBuilder: (context, index) {
                        final student =
                            filteredStudents[index]; // <--- استخدام الطلاب المفلترين هنا
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
                                  '${student.studentName} (${student.serialNumber})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الصف: ${student.className} - الشعبة: ${student.section}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  'معلم الفصل: ${student.classLeadName ?? 'غير معروف'}',
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
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showAddEditStudentDialog(
                                            studentToEdit: student,
                                          ),
                                      tooltip: 'تعديل الطالب',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _confirmDeleteStudent(student),
                                      tooltip: 'حذف الطالب',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditStudentDialog(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.person_add, color: Colors.white),
        tooltip: 'إضافة طالب جديد',
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AddEditStudentDialog - مربع حوار لإضافة/تعديل الطلاب (بدون تغيير)
// -----------------------------------------------------------------------------
class AddEditStudentDialog extends StatefulWidget {
  final Student? studentToEdit;

  const AddEditStudentDialog({super.key, this.studentToEdit});

  @override
  State<AddEditStudentDialog> createState() => _AddEditStudentDialogState();
}

class _AddEditStudentDialogState extends State<AddEditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  String _selectedGender = 'ذكر';
  final TextEditingController _sectionController = TextEditingController();
  String? _selectedClassLeadId;

  final List<String> _availableClasses = [
    'الصف الأول أ',
    'الصف الأول ب',
    'الصف الثاني أ',
    'الصف الثاني ب',
    'الصف الثالث أ',
    'الصف الثالث ب',
    'الصف الرابع أ',
    'الصف الرابع ب',
    'الصف الخامس أ',
    'الصف الخامس ب',
    'الصف السادس أ',
    'الصف السادس ب',
    'الصف السابع أ',
    'الصف السابع ب',
    'الصف الثامن أ',
    'الصف الثامن ب',
    'الصف التاسع أ',
    'الصف التاسع ب',
    'الصف العاشر أ',
    'الصف العاشر ب',
  ];

  List<AppUser> _availableClassLeads = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableClassLeads();

    if (widget.studentToEdit != null) {
      _serialNumberController.text = widget.studentToEdit!.serialNumber;
      _studentNameController.text = widget.studentToEdit!.studentName;

      final cleanedClassName = widget.studentToEdit!.className.trim();
      _classNameController.text = _availableClasses.contains(cleanedClassName)
          ? cleanedClassName
          : _availableClasses.first;

      final cleanedGender = widget.studentToEdit!.gender.trim();
      _selectedGender = ['ذكر', 'أنثى'].contains(cleanedGender)
          ? cleanedGender
          : 'ذكر';

      _sectionController.text = widget.studentToEdit!.section;
    }
  }

  Future<void> _loadAvailableClassLeads() async {
    final provider = Provider.of<AdminDashboardProvider>(
      context,
      listen: false,
    );
    setState(() {
      _availableClassLeads = provider.allUsers
          .where((user) => user.role == UserRole.classLead)
          .toList();

      _availableClassLeads.insert(
        0,
        AppUser(id: '', email: 'لا يوجد معلم مسؤول', role: UserRole.classLead),
      );

      if (widget.studentToEdit != null) {
        final existingClassLead = _availableClassLeads.firstWhere(
          (user) => user.id == widget.studentToEdit!.classLeadId.trim(),
          orElse: () => AppUser(id: '', email: '', role: UserRole.student),
        );
        _selectedClassLeadId = existingClassLead.id.isNotEmpty
            ? existingClassLead.id
            : null;
      } else {
        _selectedClassLeadId = null;
      }
    });
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _studentNameController.dispose();
    _classNameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AdminDashboardProvider>(
        context,
        listen: false,
      );
      String? errorMessage;

      final selectedClassLeadUser = _availableClassLeads.firstWhere(
        (user) => user.id == _selectedClassLeadId,
        orElse: () => AppUser(id: '', email: '', role: UserRole.student),
      );

      final newStudent = Student(
        id: widget.studentToEdit?.id ?? '',
        serialNumber: _serialNumberController.text.trim(),
        studentName: _studentNameController.text.trim(),
        className: _classNameController.text.trim(),
        gender: _selectedGender,
        section: _sectionController.text.trim(),
        classLeadId: _selectedClassLeadId ?? '',
        classLeadName: selectedClassLeadUser.email.split('@')[0],
        monthlyPayments: widget.studentToEdit?.monthlyPayments ?? {},
      );

      try {
        if (widget.studentToEdit == null) {
          await provider.addStudent(newStudent);
          errorMessage = provider.errorMessage;
        } else {
          await provider.updateStudent(newStudent);
          errorMessage = provider.errorMessage;
        }

        if (errorMessage == null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.studentToEdit == null
                    ? 'تمت إضافة الطالب بنجاح!'
                    : 'تم تحديث الطالب بنجاح!',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage!)));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.studentToEdit == null ? 'إضافة طالب جديد' : 'تعديل الطالب',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _serialNumberController,
                keyboardType: TextInputType.text,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الرقم التسلسلي',
                  prefixIcon: Icon(Icons.format_list_numbered),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الرقم التسلسلي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _studentNameController,
                keyboardType: TextInputType.text,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'اسم الطالب',
                  prefixIcon: Icon(Icons.person),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الطالب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _classNameController.text.isEmpty
                    ? null
                    : _classNameController.text,
                decoration: const InputDecoration(
                  labelText: 'الصف',
                  prefixIcon: Icon(Icons.class_),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: _availableClasses.map((className) {
                  return DropdownMenuItem(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _classNameController.text = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار الصف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'الجنس',
                  prefixIcon: Icon(Icons.wc),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _sectionController,
                keyboardType: TextInputType.text,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الشعبة',
                  hintText: 'مثال: أ',
                  prefixIcon: Icon(Icons.category),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الشعبة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedClassLeadId,
                decoration: const InputDecoration(
                  labelText: 'معلم الفصل المسؤول',
                  prefixIcon: Icon(Icons.person_outline),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: _availableClassLeads.map((user) {
                  return DropdownMenuItem(
                    value: user.id,
                    child: Text(user.email.split('@')[0]),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedClassLeadId = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار معلم مسؤول';
                  }
                  return null;
                },
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
          onPressed: _saveStudent,
          child: Text(widget.studentToEdit == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    );
  }
}
