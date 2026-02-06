import 'package:flutter/material.dart';
import '../../../../core/models/guardian.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_section_title.dart';

class GuardianFormSheet extends StatefulWidget {
  final Guardian? guardian;

  const GuardianFormSheet({super.key, this.guardian});

  @override
  State<GuardianFormSheet> createState() => _GuardianFormSheetState();
}

class _GuardianFormSheetState extends State<GuardianFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _relationshipController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.guardian?.user.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.guardian?.user.lastName ?? '');
    _emailController = TextEditingController(text: widget.guardian?.user.email ?? '');
    _phoneController = TextEditingController(text: widget.guardian?.phone ?? '');
    _addressController = TextEditingController(text: widget.guardian?.address ?? '');
    _emergencyContactController = TextEditingController(text: widget.guardian?.emergencyContact ?? '');
    _relationshipController = TextEditingController(text: widget.guardian?.relationship ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _relationshipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.guardian != null;

    return AppFormSheet(
      title: isEditing ? 'Edit Guardian' : 'Add New Guardian',
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
          isFullWidth: false,
          height: 44,
        ),
        AppButton(
          text: isEditing ? 'Save Changes' : 'Add Guardian',
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
              label: 'Email Address',
              controller: _emailController,
              hint: 'guardian@email.com',
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
            AppTextField(
              label: 'Phone Number',
              controller: _phoneController,
              hint: '+1 234 567 890',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 32),
            const AppSectionTitle(
              title: 'Additional Information',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Address',
              controller: _addressController,
              hint: 'Street address, city, state, zip',
              prefixIcon: const Icon(Icons.home_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Emergency Contact',
              controller: _emergencyContactController,
              hint: 'Emergency contact phone number',
              prefixIcon: const Icon(Icons.contact_emergency_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Relationship to Student',
              controller: _relationshipController,
              hint: 'e.g. Parent, Guardian, Relative',
              prefixIcon: const Icon(Icons.family_restroom_outlined),
            ),

            if (!isEditing) ...[ 
              const SizedBox(height: 32),
              const AppSectionTitle(
                title: 'Account Security (Optional)',
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Initial Password',
                controller: _passwordController,
                obscureText: true,
                hint: 'Leave empty for auto-generated password',
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 8) {
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
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
        'relationship': _relationshipController.text.trim(),
      };

      if (widget.guardian == null && _passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      Navigator.pop(context, data);
    }
  }
}
