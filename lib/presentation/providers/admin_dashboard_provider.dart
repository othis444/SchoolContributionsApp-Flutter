// lib/presentation/providers/admin_dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:school_contributions_app/data/datasources/student_datasource.dart';
import 'package:school_contributions_app/data/repositories/student_repository.dart';
import 'package:school_contributions_app/data/models/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_contributions_app/data/models/user.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AdminDashboardProvider extends ChangeNotifier {
  late final StudentRepository _studentRepository;
  List<Student> _allStudents = [];
  List<AppUser> _allUsers = [];
  Map<String, String> _classLeadIdToNameMap = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Student> _parsedStudentsForImport = [];
  List<String> _csvValidationErrors = [];

  AdminDashboardProvider() {
    _studentRepository = StudentRepository(
      StudentDataSource(FirebaseFirestore.instance),
      FirebaseFirestore.instance,
    );
    // <--- تم التعديل هنا: استدعاء listenToAllUsers() في المُنشئ
    // هذا يضمن أن _classLeadIdToNameMap يتم تهيئته مبكراً
    _listenToAllUsers();
  }

  List<Student> get allStudents => _allStudents;
  List<AppUser> get allUsers => _allUsers;
  Map<String, String> get classLeadIdToNameMap => _classLeadIdToNameMap;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Student> get parsedStudentsForImport => _parsedStudentsForImport;
  List<String> get csvValidationErrors => _csvValidationErrors;

  // دالة عامة للاستماع لجميع الطلاب، يتم استدعاؤها عند الحاجة
  void listenToAllStudents() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('AdminDashboardProvider: Starting to listen to all students...');
    _studentRepository.getAllStudents().listen(
      (students) {
        debugPrint(
          'AdminDashboardProvider: Received ${students.length} students from stream.',
        );
        _allStudents = students.map((student) {
          // <--- التأكد من استخدام _classLeadIdToNameMap المحدث هنا --->
          return student.copyWith(
            classLeadName:
                _classLeadIdToNameMap[student.classLeadId] ?? 'غير معروف',
          );
        }).toList();
        _isLoading = false;
        notifyListeners();
        debugPrint(
          'AdminDashboardProvider: _allStudents updated. Notifying listeners.',
        );
      },
      onError: (error) {
        _errorMessage = 'فشل تحميل بيانات الطلاب: $error';
        _isLoading = false;
        notifyListeners();
        debugPrint(
          'AdminDashboardProvider: Error listening to all students: $error',
        );
      },
    );
  }

  // دالة خاصة للاستماع لجميع المستخدمين (يتم استدعاؤها في المُنشئ)
  void _listenToAllUsers() {
    // <--- تم تغيير الاسم إلى خاص
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('AdminDashboardProvider: Starting to listen to all users...');
    _studentRepository.getAllUsers().listen(
      (users) {
        debugPrint(
          'AdminDashboardProvider: Received ${users.length} users from stream.',
        );
        _allUsers = users;
        _classLeadIdToNameMap = {
          for (var user in users) user.id: user.email.split('@')[0],
        };
        // <--- تحديث أسماء معلمي الفصل للطلاب الموجودين بالفعل بعد جلب المستخدمين --->
        _allStudents = _allStudents.map((student) {
          return student.copyWith(
            classLeadName:
                _classLeadIdToNameMap[student.classLeadId] ?? 'غير معروف',
          );
        }).toList();
        // نهاية التحديث --->
        _isLoading = false;
        notifyListeners();
        debugPrint(
          'AdminDashboardProvider: _allUsers and _classLeadIdToNameMap updated. Notifying listeners.',
        );
      },
      onError: (error) {
        _errorMessage = 'فشل تحميل بيانات المستخدمين: $error';
        _isLoading = false;
        notifyListeners();
        debugPrint(
          'AdminDashboardProvider: Error listening to all users: $error',
        );
      },
    );
  }

  // دالة عامة يمكن استدعاؤها يدوياً لتحديث المستخدمين إذا لزم الأمر
  // (على سبيل المثال، من UserManagementScreen)
  void fetchAllUsers() {
    // <--- دالة عامة لطلب جلب المستخدمين يدوياً
    _listenToAllUsers();
  }

  Future<void> addStudent(Student student) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _studentRepository.addNewStudent(student);
      debugPrint('AdminDashboardProvider: Student added successfully.');
    } catch (e) {
      _errorMessage = 'فشل إضافة الطالب: $e';
      debugPrint('AdminDashboardProvider: Error adding student: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStudent(Student student) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _studentRepository.updateStudentData(student);
      debugPrint('AdminDashboardProvider: Student updated successfully.');
    } catch (e) {
      _errorMessage = 'فشل تحديث الطالب: $e';
      debugPrint('AdminDashboardProvider: Error updating student: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _studentRepository.deleteStudent(studentId);
      debugPrint(
        'AdminDashboardProvider: Student $studentId deleted successfully.',
      );
    } catch (e) {
      _errorMessage = 'فشل حذف الطالب: $e';
      debugPrint(
        'AdminDashboardProvider: Error deleting student $studentId: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMultipleStudents(List<String> studentIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      for (String id in studentIds) {
        await _studentRepository.deleteStudent(
          id,
        ); // تستدعي دالة حذف طالب واحد لكل معرف
      }
      debugPrint(
        'AdminDashboardProvider: Successfully deleted ${studentIds.length} students.',
      );
    } catch (e) {
      _errorMessage = 'فشل حذف بعض الطلاب: $e';
      debugPrint(
        'AdminDashboardProvider: Error deleting multiple students: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> parseStudentsFromCsv() async {
    _isLoading = true;
    _errorMessage = null;
    _parsedStudentsForImport = [];
    _csvValidationErrors = [];
    notifyListeners();

    debugPrint(
      'AdminDashboardProvider: Starting CSV file picking and parsing...',
    );
    try {
      final filePath = await FlutterFileDialog.pickFile(
        params: OpenFileDialogParams(
          dialogType: OpenFileDialogType.document,
          fileExtensionsFilter: ['csv'],
        ),
      );

      if (filePath != null) {
        debugPrint(
          'AdminDashboardProvider: File picker returned a file path: $filePath',
        );
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          debugPrint(
            'AdminDashboardProvider: File bytes are available. Size: ${bytes.length} bytes',
          );
          final csvString = utf8.decode(bytes);
          debugPrint(
            'AdminDashboardProvider: Decoded CSV string (first 200 chars): ${csvString.substring(0, csvString.length > 200 ? 200 : csvString.length)}',
          );

          List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter()
              .convert(csvString);
          debugPrint(
            'AdminDashboardProvider: CSV converter returned ${rowsAsListOfValues.length} rows.',
          );

          if (rowsAsListOfValues.isEmpty) {
            _errorMessage = 'ملف CSV فارغ أو غير صالح.';
            debugPrint(
              'AdminDashboardProvider: Error - CSV is empty after conversion.',
            );
            notifyListeners();
            return;
          }

          final List<String> headers = rowsAsListOfValues[0]
              .map((e) => e.toString().trim())
              .toList();
          debugPrint('AdminDashboardProvider: Headers found: $headers');
          final List<List<dynamic>> dataRows = rowsAsListOfValues.sublist(1);
          debugPrint(
            'AdminDashboardProvider: Data rows count: ${dataRows.length}',
          );

          final int serialNumberIndex = headers.indexOf('Serial Number');
          final int studentNameIndex = headers.indexOf('Student Name');
          final int classNameIndex = headers.indexOf('Class Name');
          final int genderIndex = headers.indexOf('Gender');
          final int sectionIndex = headers.indexOf('Section');
          final int classLeadEmailIndex = headers.indexOf('Class Lead Email');

          if (serialNumberIndex == -1 ||
              studentNameIndex == -1 ||
              classNameIndex == -1 ||
              genderIndex == -1 ||
              sectionIndex == -1 ||
              classLeadEmailIndex == -1) {
            _errorMessage =
                'ملف CSV لا يحتوي على جميع الأعمدة المطلوبة (Serial Number, Student Name, Class Name, Gender, Section, Class Lead Email).';
            debugPrint('AdminDashboardProvider: Missing required CSV headers.');
            notifyListeners();
            return;
          }

          for (int i = 0; i < dataRows.length; i++) {
            final row = dataRows[i];
            final int rowNumber = i + 2;

            if (row.length < headers.length) {
              _csvValidationErrors.add(
                'الصف $rowNumber: صف غير مكتمل. تم تخطيه.',
              );
              debugPrint(
                'AdminDashboardProvider: Row $rowNumber incomplete: $row',
              );
              continue;
            }
            try {
              final serialNumber = row[serialNumberIndex].toString().trim();
              final studentName = row[studentNameIndex].toString().trim();
              final className = row[classNameIndex].toString().trim();
              final gender = row[genderIndex].toString().trim();
              final section = row[sectionIndex].toString().trim();
              final classLeadEmail = row[classLeadEmailIndex].toString().trim();

              if (serialNumber.isEmpty ||
                  studentName.isEmpty ||
                  className.isEmpty ||
                  gender.isEmpty ||
                  section.isEmpty ||
                  classLeadEmail.isEmpty) {
                _csvValidationErrors.add(
                  'الصف $rowNumber: توجد حقول فارغة مطلوبة.',
                );
                debugPrint(
                  'AdminDashboardProvider: Row $rowNumber has empty required fields.',
                );
                continue;
              }

              final classLeadUser = _allUsers.firstWhere(
                (user) =>
                    user.email.toLowerCase() == classLeadEmail.toLowerCase(),
                orElse: () =>
                    AppUser(id: '', email: '', role: UserRole.student),
              );

              if (classLeadUser.id.isEmpty) {
                _csvValidationErrors.add(
                  'الصف $rowNumber: معلم الفصل المسؤول "$classLeadEmail" غير موجود.',
                );
                debugPrint(
                  'AdminDashboardProvider: Row $rowNumber: Class Lead "$classLeadEmail" not found.',
                );
                continue;
              }

              final student = Student(
                id: '',
                serialNumber: serialNumber,
                studentName: studentName,
                className: className,
                gender: gender,
                section: section,
                classLeadId: classLeadUser.id,
                classLeadName: classLeadUser.email.split('@')[0],
                monthlyPayments: {},
              );
              _parsedStudentsForImport.add(student);
            } catch (e) {
              _csvValidationErrors.add(
                'الصف $rowNumber: حدث خطأ أثناء تحليل البيانات: $e',
              );
              debugPrint(
                'AdminDashboardProvider: Error parsing row $rowNumber: $e',
              );
            }
          }

          if (_parsedStudentsForImport.isEmpty &&
              _csvValidationErrors.isEmpty) {
            _errorMessage =
                'لم يتم العثور على أي طلاب صالحين للاستيراد في ملف CSV.';
          } else if (_parsedStudentsForImport.isEmpty &&
              _csvValidationErrors.isNotEmpty) {
            _errorMessage = 'لم يتم استيراد أي طلاب بسبب الأخطاء التالية:';
          } else if (_csvValidationErrors.isNotEmpty) {
            _errorMessage =
                'تم استيراد بعض الطلاب، ولكن توجد أخطاء في صفوف أخرى.';
          } else {
            _errorMessage = null;
          }
          debugPrint(
            'AdminDashboardProvider: CSV parsing finished. Valid students: ${_parsedStudentsForImport.length}, Errors: ${_csvValidationErrors.length}',
          );
        } else {
          _errorMessage =
              'الملف المختار فارغ أو لا يمكن قراءته. يرجى التأكد من أن الملف يحتوي على بيانات وأن التطبيق لديه صلاحيات القراءة.';
          debugPrint(
            'AdminDashboardProvider: Error - Selected file has no bytes.',
          );
        }
      } else {
        _errorMessage = 'لم يتم اختيار ملف CSV.';
        debugPrint(
          'AdminDashboardProvider: File picker returned null (no file selected).',
        );
      }
    } catch (e) {
      _errorMessage = 'فشل استيراد ملف CSV: $e';
      debugPrint(
        'AdminDashboardProvider: General error during file picking/parsing: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> performCsvImport() async {
    if (_parsedStudentsForImport.isEmpty) {
      _errorMessage = 'لا يوجد طلاب لاستيرادهم.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint(
      'AdminDashboardProvider: Starting Firestore import for ${_parsedStudentsForImport.length} students...',
    );
    try {
      await _studentRepository.addStudentsFromCsv(_parsedStudentsForImport);
      _parsedStudentsForImport = [];
      _csvValidationErrors = [];
      _errorMessage = null;
      debugPrint(
        'AdminDashboardProvider: Successfully imported students to Firestore.',
      );
    } catch (e) {
      _errorMessage = 'فشل حفظ الطلاب المستوردين: $e';
      debugPrint(
        'AdminDashboardProvider: Error saving imported students to Firestore: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUser(AppUser user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _studentRepository.addUser(user);
      debugPrint('AdminDashboardProvider: User added successfully.');
    } catch (e) {
      _errorMessage = 'فشل إضافة المستخدم: $e';
      debugPrint('AdminDashboardProvider: Error adding user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(AppUser user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _studentRepository.updateUser(user);
      debugPrint('AdminDashboardProvider: User updated successfully.');
    } catch (e) {
      _errorMessage = 'فشل تحديث المستخدم: $e';
      debugPrint('AdminDashboardProvider: Error updating user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _studentRepository.deleteUser(userId);
      debugPrint('AdminDashboardProvider: User $userId deleted successfully.');
    } catch (e) {
      _errorMessage = 'فشل حذف المستخدم: $e';
      debugPrint('AdminDashboardProvider: Error deleting user $userId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
