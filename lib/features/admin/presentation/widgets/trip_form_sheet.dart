import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/route.dart' as model;
import '../../../../core/models/driver.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_section_title.dart';

class TripFormSheet extends StatefulWidget {
  const TripFormSheet({super.key});

  @override
  State<TripFormSheet> createState() => _TripFormSheetState();
}

class _TripFormSheetState extends State<TripFormSheet> {
  final _formKey = GlobalKey<FormState>();
  model.Route? _selectedRoute;
  Driver? _selectedDriver;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadRoutes());
    context.read<AdminBloc>().add(const AdminLoadDrivers());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'Schedule New Trip',
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
          isFullWidth: false,
          height: 44,
        ),
        AppButton(
          text: 'Schedule',
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
              title: 'Trip Details',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 16),
            
            // Route Selection
            BlocBuilder<AdminBloc, AdminState>(
              buildWhen: (previous, current) => current is AdminRoutesLoaded,
              builder: (context, state) {
                List<model.Route> routes = [];
                if (state is AdminRoutesLoaded) {
                  routes = state.routes;
                }
                return DropdownButtonFormField<model.Route>(
                  decoration: InputDecoration(
                    labelText: 'Select Route',
                    prefixIcon: const Icon(Icons.route_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: routes.map((route) {
                    return DropdownMenuItem(
                      value: route,
                      child: Text(route.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedRoute = value),
                  validator: (value) => value == null ? 'Please select a route' : null,
                );
              },
            ),
            const SizedBox(height: 20),
            
            // Driver Selection
            BlocBuilder<AdminBloc, AdminState>(
              buildWhen: (previous, current) => current is AdminDriversLoaded,
              builder: (context, state) {
                List<Driver> drivers = [];
                if (state is AdminDriversLoaded) {
                  drivers = state.drivers;
                }
                return DropdownButtonFormField<Driver>(
                  decoration: InputDecoration(
                    labelText: 'Assign Driver',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: drivers.map((driver) {
                    return DropdownMenuItem(
                      value: driver,
                      child: Text(driver.fullName),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedDriver = value),
                  validator: (value) => value == null ? 'Please select a driver' : null,
                );
              },
            ),
            const SizedBox(height: 24),

            const AppSectionTitle(
              title: 'Schedule Information',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 8),

            // Date Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
              ),
              title: const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("${_selectedDate.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectDate(context),
            ),

            // Time Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time, color: Colors.orange, size: 20),
              ),
              title: const Text('Select Time', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTime(context),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      final data = {
        'route_id': _selectedRoute!.id,
        'driver_id': _selectedDriver!.id,
        'scheduled_at': dateTime.toIso8601String(),
        'status': 'scheduled',
      };
      Navigator.pop(context, data);
    }
  }
}
