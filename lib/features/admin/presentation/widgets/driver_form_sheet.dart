import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/driver.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_section_title.dart';

class DriverFormSheet extends StatefulWidget {
  final Driver? driver;

  const DriverFormSheet({super.key, this.driver});

  @override
  State<DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends State<DriverFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _licenseController;
  late TextEditingController _passwordController;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  bool _isActive = true;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.driver?.user.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.driver?.user.lastName ?? '');
    _emailController = TextEditingController(text: widget.driver?.user.email ?? '');
    _phoneController = TextEditingController(text: widget.driver?.phone ?? '');
    _licenseController = TextEditingController(text: widget.driver?.licenseNumber ?? '');
    _passwordController = TextEditingController();
    _selectedGender = widget.driver?.user.gender;
    _selectedDateOfBirth = widget.driver?.user.dateOfBirth;
    _isActive = widget.driver?.isActive ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.driver != null;

    return AppFormSheet(
      title: isEditing ? 'Edit Driver' : 'Add New Driver',
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
          isFullWidth: false,
          height: 44,
        ),
        AppButton(
          text: isEditing ? 'Save Changes' : 'Add Driver',
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
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (widget.driver?.avatar != null
                            ? NetworkImage(widget.driver!.avatar!)
                            : null) as ImageProvider?,
                    child: (_pickedImage == null && widget.driver?.avatar == null)
                        ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
              hint: 'driver@school.com',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
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
                  initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
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
                      : 'Select date',
                ),
              ),
            ),
            const SizedBox(height: 32),
            const AppSectionTitle(
              title: 'Driver License',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'License Number',
              controller: _licenseController,
              hint: 'e.g. DL123456789',
              prefixIcon: const Icon(Icons.badge_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter license number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: const Text('Driver can accept assignments'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: AppTheme.primaryColor,
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
        'phone': _phoneController.text.trim(),
        'license_number': _licenseController.text.trim(),
        'gender': _selectedGender,
        'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
        'is_active': _isActive,
        'avatar': _pickedImage?.path,
      };

      if (widget.driver == null) {
        data['password'] = _passwordController.text;
      }

      Navigator.pop(context, data);
    }
  }
}
