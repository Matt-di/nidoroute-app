import 'package:flutter/material.dart';
import '../../../../core/models/user.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_section_title.dart';

class StaffFormSheet extends StatefulWidget {
  final User? staff;

  const StaffFormSheet({super.key, this.staff});

  @override
  State<StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.staff?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.staff?.lastName ?? '');
    _emailController = TextEditingController(text: widget.staff?.email ?? '');
    _passwordController = TextEditingController();
    _selectedGender = widget.staff?.gender;
    _selectedDateOfBirth = widget.staff?.dateOfBirth;
    _selectedRole = widget.staff?.role ?? 'admin';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staff != null;

    return AppFormSheet(
      title: isEditing ? 'Edit Staff Member' : 'Add New Staff',
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
          isFullWidth: false,
          height: 44,
        ),
        AppButton(
          text: isEditing ? 'Save Changes' : 'Add Staff',
          onPressed: _submit,
          isFullWidth: false,
          height: 44,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'Personal Information',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Work Email',
              controller: _emailController,
              hint: 'staff@school.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: const Icon(Icons.wc_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                  lastDate: DateTime.now().subtract(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDateOfBirth = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.year}'
                      : 'Select date (optional)',
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Role',
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
              ],
              onChanged: (value) => setState(() => _selectedRole = value),
            ),

            if (!isEditing) ...[
              const SizedBox(height: 32),
              const AppSectionTitle(
                title: 'Account Security',
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Initial Password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
        'role': _selectedRole,
      };

      if (widget.staff == null) {
        data['password'] = _passwordController.text;
      }

      Navigator.pop(context, data);
    }
  }
}
