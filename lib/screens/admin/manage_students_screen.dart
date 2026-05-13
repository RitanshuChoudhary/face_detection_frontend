import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../services/image_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/shimmer_loading.dart';
import 'register_student_face_screen.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollController = TextEditingController();
  int? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final prov = Provider.of<AdminProvider>(context, listen: false);
    await prov.fetchStudents();
    await prov.fetchClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  void _openAddStudentSheet() {
    final classes = Provider.of<AdminProvider>(context, listen: false).classes;
    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register a Class first!')),
      );
      return;
    }

    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _rollController.clear();
    _selectedClassId = classes.first.id;
    File? selectedFaceFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final adminProv = Provider.of<AdminProvider>(context);
            return LoadingOverlay(
              isLoading: adminProv.isLoading,
              message: 'Enrolling student account & processing face...',
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppConstants.paddingLarge,
                  right: AppConstants.paddingLarge,
                  top: AppConstants.paddingLarge,
                  bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.paddingLarge,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Register Student Account',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Full Name',
                        hint: 'David Jones',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter student name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Email Address',
                        hint: 'david@school.com',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter email address' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Password',
                        hint: '••••••',
                        prefixIcon: Icons.vpn_key_outlined,
                        controller: _passwordController,
                        isPassword: true,
                        validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Roll Number',
                        hint: 'RO19001',
                        prefixIcon: Icons.badge_outlined,
                        controller: _rollController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter roll number' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Assign Class', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedClassId,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                        items: classes.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )).toList(),
                        onChanged: (val) {
                          setModalState(() => _selectedClassId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Student Photo (Required)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final file = await ImageService().captureFromCamera();
                          if (file != null) {
                            setModalState(() {
                              selectedFaceFile = file;
                            });
                          }
                        },
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(
                              color: selectedFaceFile != null ? AppConstants.success : Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          child: selectedFaceFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                  child: Image.file(selectedFaceFile!, fit: BoxFit.cover, width: double.infinity),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_outlined, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 12),
                                    const Text('Tap to capture student face photo', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Enroll Student with Face',
                        onPressed: () async {
                          if (!_formKey.currentState!.validate() || _selectedClassId == null) return;
                          if (selectedFaceFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please capture student photo first!'), backgroundColor: AppConstants.warning),
                            );
                            return;
                          }

                          final prov = Provider.of<AdminProvider>(context, listen: false);
                          final ok = await prov.registerStudentWithFace(
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                            rollNumber: _rollController.text.trim(),
                            classId: _selectedClassId!,
                            faceFile: selectedFaceFile!,
                          );

                          if (!mounted) return;

                          if (ok) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Student registered & Face verified successfully!'), backgroundColor: AppConstants.success),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(prov.errorMessage ?? 'Failed to register student'),
                                backgroundColor: AppConstants.error,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showStudentActionSheet(dynamic student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadius)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Roll No: ${student.rollNumber} • Class ID: ${student.classId}',
                style: const TextStyle(color: AppConstants.textLight, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Register/Re-register Face option
              ListTile(
                leading: const Icon(Icons.face, color: AppConstants.primary),
                title: Text(
                  student.hasFaceRegistered ? 'Re-register Face Features' : 'Register Face Features',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Capture 3 facial views to train AI model'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RegisterStudentFaceScreen(student: student),
                    ),
                  );
                },
              ),
              
              // Delete Face option
              if (student.hasFaceRegistered)
                ListTile(
                  leading: const Icon(Icons.no_photography_outlined, color: AppConstants.error),
                  title: const Text('Clear Trained Face Metadata', style: TextStyle(color: AppConstants.error, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Completely removes saved facial embeddings'),
                  onTap: () async {
                    Navigator.pop(context);
                    final prov = Provider.of<AdminProvider>(context, listen: false);
                    final ok = await prov.deleteStudentFaces(student.id);
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Face template cleared!'), backgroundColor: AppConstants.success),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Students Directory')),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: LoadingOverlay(
          isLoading: adminProv.isLoading,
          message: 'Enrolling student account...',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Enrolled Students',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: ${adminProv.students.length}',
                      style: const TextStyle(fontSize: 13, color: AppConstants.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              Expanded(
                child: adminProv.isStudentsLoading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (context, index) => const ShimmerListTile(),
                      )
                    : adminProv.students.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.face, size: 48, color: AppConstants.textMuted.withOpacity(0.5)),
                                    const SizedBox(height: 12),
                                    const Text('No students registered yet.', style: TextStyle(color: AppConstants.textLight)),
                                  ],
                                ),
                              )
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: adminProv.students.length,
                          itemBuilder: (context, index) {
                            final student = adminProv.students[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: student.hasFaceRegistered
                                      ? AppConstants.success.withOpacity(0.12)
                                      : AppConstants.warning.withOpacity(0.12),
                                  child: Icon(
                                    student.hasFaceRegistered ? Icons.face : Icons.face_retouching_off,
                                    color: student.hasFaceRegistered ? AppConstants.success : AppConstants.warning,
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Roll No: ${student.rollNumber}'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: student.hasFaceRegistered
                                            ? AppConstants.success.withOpacity(0.15)
                                            : AppConstants.warning.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        student.hasFaceRegistered ? 'Face Trained' : 'Face Missing',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: student.hasFaceRegistered ? AppConstants.success : AppConstants.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.more_vert),
                                onTap: () => _showStudentActionSheet(student),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddStudentSheet,
        backgroundColor: AppConstants.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
