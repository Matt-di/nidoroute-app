import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../logic/bloc/admin_event.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/models/guardian.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/widgets/location_picker_screen.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_section_title.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PassengerFormSheet extends StatefulWidget {
  final Passenger? passenger;

  const PassengerFormSheet({super.key, this.passenger});

  @override
  State<PassengerFormSheet> createState() => _PassengerFormSheetState();
}

class _PassengerFormSheetState extends State<PassengerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _pickupAddressController;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedGuardianId;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  
  double? _pickupLat;
  double? _pickupLng;

  List<Guardian> _guardians = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.passenger?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.passenger?.lastName ?? '',
    );
    _pickupAddressController = TextEditingController(
      text: widget.passenger?.pickupLocation?.address ?? '',
    );
    _selectedGender = widget.passenger?.gender;
    _selectedDateOfBirth = widget.passenger?.dateOfBirth;
    _selectedGuardianId = widget.passenger?.guardian?.id;
    
    if (widget.passenger?.pickupLocation?.coordinates != null) {
      _pickupLat = widget.passenger!.pickupLocation!.coordinates!['latitude'];
      _pickupLng = widget.passenger!.pickupLocation!.coordinates!['longitude'];
    }

    // Load guardians
    context.read<AdminBloc>().add(const AdminLoadGuardians());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _pickupAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  Future<void> _pickLocation() async {
    final lat = _pickupLat;
    final lng = _pickupLng;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialPosition: lat != null && lng != null 
              ? LatLng(lat, lng) 
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _pickupAddressController.text = result['address'];
        _pickupLat = result['lat'];
        _pickupLng = result['lng'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.passenger != null;

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminGuardiansLoaded) {
          setState(() => _guardians = state.guardians);
        }
      },
      child: AppFormSheet(
        title: isEditing ? 'Edit Passenger' : 'Add New Passenger',
        actions: [
          AppButton(
            text: 'Cancel',
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(context),
            isFullWidth: false,
            height: 44,
          ),
          AppButton(
            text: isEditing ? 'Save Changes' : 'Add Passenger',
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (widget.passenger?.image != null
                                ? NetworkImage(widget.passenger!.image!)
                                : null) as ImageProvider?,
                        child: (_pickedImage == null &&
                                widget.passenger?.image == null)
                            ? Icon(Icons.person,
                                size: 50, color: Colors.grey.shade400)
                            : null,
                      ),
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
                          child: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
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
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _selectedDateOfBirth ??
                        DateTime.now().subtract(const Duration(days: 365 * 6)),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365 * 18),
                    ),
                    lastDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                  );
                  if (date != null) {
                    setState(() => _selectedDateOfBirth = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                title: 'Guardian Information',
                icon: Icons.family_restroom,
              ),
              const SizedBox(height: 16),
              BlocBuilder<AdminBloc, AdminState>(
                buildWhen: (previous, current) => 
                    current is AdminLoadingGuardians || 
                    current is AdminGuardiansLoaded ||
                    current is AdminLoading,
                builder: (context, state) {
                  final isLoading = state is AdminLoadingGuardians || state is AdminLoading;
                  
                  return DropdownButtonFormField<String>(
                    value: _guardians.any((g) => g.id == _selectedGuardianId)
                        ? _selectedGuardianId
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isLoading ? 'Loading Guardians...' : 'Guardian',
                      prefixIcon: isLoading 
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.family_restroom),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _guardians.map((guardian) {
                      return DropdownMenuItem(
                        value: guardian.id,
                        child: Text(
                          '${guardian.fullName} (${guardian.email})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: isLoading 
                        ? null 
                        : (value) => setState(() => _selectedGuardianId = value),
                    validator: (value) {
                      if (isLoading) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please select a guardian';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              const AppSectionTitle(
                title: 'Addresses',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Pickup Address',
                controller: _pickupAddressController,
                hint: 'e.g. 123 Maple St, Springfield',
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 2,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: _pickLocation,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
        'gender': _selectedGender,
        'guardian_id': _selectedGuardianId,
        'pickup_address': _pickupAddressController.text.trim(),
        'pickup_lat': _pickupLat,
        'pickup_lng': _pickupLng,
      };
      if (_pickedImage != null) {
        data['image_file'] = _pickedImage;
      }
      Navigator.pop(context, data);
    }
  }
}
