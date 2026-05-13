import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/shimmer_loading.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchSubjects();
    });
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _openAddSubjectSheet() {
    _subjectNameController.clear();
    _codeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadius)),
      ),
      builder: (context) {
        return Consumer<AdminProvider>(
          builder: (context, adminProv, child) {
            return LoadingOverlay(
              isLoading: adminProv.isLoading,
              message: 'Creating subject record...',
              child: Padding(
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
                            'Create New Subject',
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
                        label: 'Subject Name',
                        hint: 'Mathematics, Artificial Intelligence, Physics',
                        prefixIcon: Icons.book_outlined,
                        controller: _subjectNameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter subject name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Subject Code',
                        hint: 'CS-101, MATH-302',
                        prefixIcon: Icons.qr_code_outlined,
                        controller: _codeController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter subject code' : null,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Create Subject',
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final ok = await adminProv.createSubject(
                            _subjectNameController.text.trim(),
                            _codeController.text.trim(),
                          );

                          if (!mounted) return;

                          if (ok) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Subject created successfully!'), backgroundColor: AppConstants.success),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects Directory')),
      body: LoadingOverlay(
        isLoading: adminProv.isLoading,
        message: 'Creating subject record...',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Academic Subjects',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: adminProv.isSubjectsLoading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (context, index) => const ShimmerListTile(),
                      )
                    : adminProv.subjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book, size: 48, color: AppConstants.textMuted.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text('No subjects registered yet.', style: TextStyle(color: AppConstants.textLight)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: adminProv.subjects.length,
                            itemBuilder: (context, index) {
                              final sub = adminProv.subjects[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppConstants.warning.withOpacity(0.1),
                                    child: const Icon(Icons.book, color: AppConstants.warning),
                                  ),
                                  title: Text(
                                    sub.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('Code: ${sub.code}'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
        onPressed: _openAddSubjectSheet,
        backgroundColor: AppConstants.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
