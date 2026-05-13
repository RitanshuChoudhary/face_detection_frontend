import 'package:attendence_app/screens/admin/manage_students_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/shimmer_loading.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchClasses();
    });
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  void _openAddClassSheet() {
    _classNameController.clear();
    _sectionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadius),
        ),
      ),
      builder: (context) {
        return Consumer<AdminProvider>(
          builder: (context, adminProv, child) {
            return LoadingOverlay(
              isLoading: adminProv.isLoading,
              message: 'Creating class record...',
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
                            'Create New Class',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                        label: 'Class Name',
                        hint: 'Grade 10, Computer Science, etc.',
                        prefixIcon: Icons.class_outlined,
                        controller: _classNameController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Enter class name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        label: 'Section (Optional)',
                        hint: 'Section A, Section B',
                        prefixIcon: Icons.grid_3x3,
                        controller: _sectionController,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Create Class',
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final ok = await adminProv.createClass(
                            _classNameController.text.trim(),
                            _sectionController.text.trim(),
                          );

                          if (!mounted) return;

                          if (ok) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Class created successfully!'),
                                backgroundColor: AppConstants.success,
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Classes Directory')),
      body: LoadingOverlay(
        isLoading: adminProv.isLoading,
        message: 'Creating class record...',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Academic Classes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: adminProv.isClassesLoading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (context, index) => const ShimmerListTile(),
                      )
                    : adminProv.classes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 48,
                                  color: AppConstants.textMuted.withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No classes registered yet.',
                                  style: TextStyle(color: AppConstants.textLight),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: adminProv.classes.length,
                            itemBuilder: (context, index) {
                              final cls = adminProv.classes[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppConstants.accent
                                        .withOpacity(0.1),
                                    child: const Icon(
                                      Icons.class_outlined,
                                      color: AppConstants.accent,
                                    ),
                                  ),
                                  title: Text(
                                    cls.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Click to view students roster',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ManageStudentsScreen(),
                                      ),
                                    );
                                  },
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
        onPressed: _openAddClassSheet,
        backgroundColor: AppConstants.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
