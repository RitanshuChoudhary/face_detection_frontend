import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/shimmer_loading.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _empIdController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<AdminProvider>(context, listen: false);
      prov.fetchTeachers();
      prov.fetchClasses();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _empIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _openAddTeacherSheet() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _empIdController.clear();
    _phoneController.clear();
    int? selectedClassId;

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
            final classesList = adminProv.classes;

            return LoadingOverlay(
              isLoading: adminProv.isLoading,
              message: 'Registering teacher credentials...',
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
                            'Register New Teacher',
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
                        hint: 'Prof. Mary Jane',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter teacher name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Email Address',
                        hint: 'mary.jane@school.com',
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
                        label: 'Employee ID (Optional)',
                        hint: 'EMP982',
                        prefixIcon: Icons.badge_outlined,
                        controller: _empIdController,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Phone Number (Optional)',
                        hint: '+1 555-0199',
                        prefixIcon: Icons.phone_android,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Assign Class (Optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textLight),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedClassId,
                        hint: const Text('Select classroom to assign'),
                        dropdownColor: Theme.of(context).cardColor,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          prefixIcon: const Icon(Icons.school, color: AppConstants.primary),
                        ),
                        items: classesList.map((cls) {
                          return DropdownMenuItem<int>(
                            value: cls.id,
                            child: Text(cls.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedClassId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Add Teacher',
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final prov = Provider.of<AdminProvider>(context, listen: false);
                          final ok = await prov.createTeacher(
                            _nameController.text.trim(),
                            _emailController.text.trim(),
                            _passwordController.text,
                            _empIdController.text.trim(),
                            _phoneController.text.trim(),
                            classId: selectedClassId,
                          );

                          if (!mounted) return;
                          
                          if (ok) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Teacher successfully enrolled!'), backgroundColor: AppConstants.success),
                            );
                          } else {
                            setModalState(() {}); // update UI to show error message
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

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Teachers Directory')),
      body: LoadingOverlay(
        isLoading: adminProv.isLoading,
        message: 'Saving teacher credentials...',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Registered Teachers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: adminProv.isTeachersLoading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (context, index) => const ShimmerListTile(),
                      )
                    : adminProv.teachers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.badge, size: 48, color: AppConstants.textMuted.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text('No teachers registered yet.', style: TextStyle(color: AppConstants.textLight)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: adminProv.teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = adminProv.teachers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppConstants.primary.withOpacity(0.1),
                                child: const Icon(Icons.person, color: AppConstants.primary),
                              ),
                              title: Text(
                                teacher.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(teacher.email),
                              trailing: Icon(
                                Icons.chevron_right, 
                                color: isDark ? Colors.white30 : Colors.black26
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTeacherSheet,
        backgroundColor: AppConstants.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
