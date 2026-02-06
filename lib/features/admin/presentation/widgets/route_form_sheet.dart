import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/route.dart' as model;
import '../../../../core/models/driver.dart';
import '../../../../core/models/car.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/location_picker_screen.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_section_title.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteFormSheet extends StatefulWidget {
  final model.Route? route;

  const RouteFormSheet({super.key, this.route});

  @override
  State<RouteFormSheet> createState() => _RouteFormSheetState();
}

class _RouteFormSheetState extends State<RouteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _startLatController;
  late TextEditingController _startLngController;
  late TextEditingController _endLatController;
  late TextEditingController _endLngController;
  late TextEditingController _startAddressController;
  late TextEditingController _endAddressController;
  late TextEditingController _estimatedDurationController;
  
  String? _selectedDriverId;
  String? _selectedCarId;
  String _selectedStatus = 'scheduled';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.name ?? '');
    _descriptionController = TextEditingController(text: widget.route?.description ?? '');
    _startLatController = TextEditingController(text: widget.route?.startLat?.toString() ?? '');
    _startLngController = TextEditingController(text: widget.route?.startLng?.toString() ?? '');
    _endLatController = TextEditingController(text: widget.route?.endLat?.toString() ?? '');
    _endLngController = TextEditingController(text: widget.route?.endLng?.toString() ?? '');
    _startAddressController = TextEditingController(text: widget.route?.startAddress ?? '');
    _endAddressController = TextEditingController(text: widget.route?.endAddress ?? '');
    _estimatedDurationController = TextEditingController(text: widget.route?.estimatedDuration?.toString() ?? '');
    
    _selectedDriverId = widget.route?.driver?.id;
    _selectedCarId = widget.route?.car?.id;

    // Trigger loading of dependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBloc>().add(const AdminLoadRouteDependencies());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startLatController.dispose();
    _startLngController.dispose();
    _endLatController.dispose();
    _endLngController.dispose();
    _startAddressController.dispose();
    _endAddressController.dispose();
    _estimatedDurationController.dispose();
    super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.route != null;

    return AppFormSheet(
      title: isEditing ? 'Edit Route' : 'Create New Route',
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
          isFullWidth: false,
          height: 44,
        ),
        AppButton(
          text: isEditing ? 'Save Changes' : 'Create Route',
          onPressed: _submit,
          isFullWidth: false,
          height: 44,
        ),
      ],
      child: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          List<Driver> drivers = [];
          List<Car> cars = [];
          
          if (state is AdminRouteDependenciesLoaded) {
            drivers = state.drivers;
            cars = state.cars;
          } else if (state is AdminLoading || state is AdminLoadingRouteDependencies) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle(
                  title: 'Route Basics',
                  icon: Icons.alt_route_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Route Name',
                  controller: _nameController,
                  hint: 'e.g. Morning Route A',
                  prefixIcon: const Icon(Icons.alt_route_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a route name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  hint: 'Describe the primary stops or schedule...',
                  prefixIcon: const Icon(Icons.description_outlined),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 32),
                const AppSectionTitle(
                  title: 'Assignments',
                  icon: Icons.assignment_ind_outlined,
                ),
                const SizedBox(height: 16),
                
                // Driver Dropdown
                _buildDropdownField<String>(
                  label: 'Assigned Driver',
                  value: _selectedDriverId,
                  items: drivers.map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.user.fullName),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedDriverId = val),
                  hint: 'Select a driver',
                  icon: Icons.person_outline,
                ),
                
                const SizedBox(height: 20),
                
                // Car Dropdown
                _buildDropdownField<String>(
                  label: 'Assigned Car',
                  value: _selectedCarId,
                  items: cars.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.model} (${c.plateNumber})'),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCarId = val),
                  hint: 'Select a car',
                  icon: Icons.directions_bus_outlined,
                ),

                const SizedBox(height: 32),
                const AppSectionTitle(
                  title: 'Location & Schedule',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  label: 'Start Address',
                  controller: _startAddressController,
                  hint: 'Enter or pick start address...',
                  prefixIcon: const Icon(Icons.home_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () => _pickLocation(true),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                AppTextField(
                  label: 'End Address',
                  controller: _endAddressController,
                  hint: 'Enter or pick end address...',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () => _pickLocation(false),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                AppTextField(
                  label: 'Estimated Duration (mins)',
                  controller: _estimatedDurationController,
                  hint: '30',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickLocation(bool isStart) async {
    final currentLat = double.tryParse(isStart ? _startLatController.text : _endLatController.text);
    final currentLng = double.tryParse(isStart ? _startLngController.text : _endLngController.text);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialPosition: currentLat != null && currentLng != null
              ? LatLng(currentLat, currentLng)
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isStart) {
          _startAddressController.text = result['address'];
          _startLatController.text = result['lat'].toString();
          _startLngController.text = result['lng'].toString();
        } else {
          _endAddressController.text = result['address'];
          _endLatController.text = result['lat'].toString();
          _endLngController.text = result['lng'].toString();
        }
      });
    }
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: AppTheme.textFieldDecoration(
            hintText: hint ?? '',
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'driver_id': _selectedDriverId,
        'car_id': _selectedCarId,
        'start_address': _startAddressController.text.trim(),
        'end_address': _endAddressController.text.trim(),
        'start_lat': double.tryParse(_startLatController.text),
        'start_lng': double.tryParse(_startLngController.text),
        'end_lat': double.tryParse(_endLatController.text),
        'end_lng': double.tryParse(_endLngController.text),
        'estimated_duration': int.tryParse(_estimatedDurationController.text),
      };
      Navigator.pop(context, data);
    }
  }
}

