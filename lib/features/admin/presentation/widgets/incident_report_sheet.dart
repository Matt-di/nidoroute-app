import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/models/incident.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../core/widgets/app_button.dart';

class IncidentReportSheet extends StatefulWidget {
  final String tripId;
  final LatLng? currentLocation;

  const IncidentReportSheet({
    super.key,
    required this.tripId,
    this.currentLocation,
  });

  @override
  State<IncidentReportSheet> createState() => _IncidentReportSheetState();
}

class _IncidentReportSheetState extends State<IncidentReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  String _selectedType = IncidentType.other;
  String _selectedSeverity = IncidentSeverity.medium;
  bool _isSubmitting = false;
  bool _useCurrentLocation = true;
  LatLng? _selectedLocation;
  bool _isGettingLocation = false;

  final IncidentService _incidentService = IncidentService();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Ensure all required fields have valid values
      final incidentType = _selectedType.isNotEmpty ? _selectedType : IncidentType.other;
      final description = _descriptionController.text.trim();
      final severity = _selectedSeverity.isNotEmpty ? _selectedSeverity : IncidentSeverity.medium;

      final incident = await _incidentService.reportIncident(
        tripId: widget.tripId,
        type: incidentType,
        description: description,
        lat: _useCurrentLocation && _selectedLocation != null ? _selectedLocation!.latitude : null,
        lng: _useCurrentLocation && _selectedLocation != null ? _selectedLocation!.longitude : null,
        severity: severity,
      );

      // Always try to show success and close, even if widget might be disposed
      if (mounted) {
        Navigator.pop(context, incident);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('Incident reported successfully! Help is on the way.')),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // If widget is not mounted, try to show the snackbar in a different way
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pop(context, incident);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Incident reported successfully! Help is on the way.')),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        // Handle error when widget is not mounted
        setState(() => _isSubmitting = false);
      }
    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.report_problem,
                    color: AppTheme.errorColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Incident',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Report an issue or emergency',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Form
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Incident Type
                  const Text(
                    'Incident Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildIncidentTypeSelector(),
                  const SizedBox(height: 20),

                  // Severity Level
                  const Text(
                    'Severity Level',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSeveritySelector(),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Location
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isGettingLocation ? Icons.hourglass_empty : Icons.location_on,
                          color: _isGettingLocation ? Colors.orange : AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isGettingLocation
                              ? Text(
                                  'Getting current location...',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                )
                              : _selectedLocation != null
                                  ? Text(
                                      'Location: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    )
                                  : Text(
                                      'Location unavailable',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                        ),
                        if (!_isGettingLocation && _selectedLocation == null)
                          TextButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Retry'),
                          ),
                        if (_selectedLocation != null)
                          Switch(
                            value: _useCurrentLocation,
                            onChanged: (value) {
                              setState(() => _useCurrentLocation = value);
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: _isSubmitting ? 'Reporting...' : 'Report Incident',
                      onPressed: _isSubmitting ? null : _submitIncident,
                      isLoading: _isSubmitting,
                      variant: AppButtonVariant.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IncidentType.allTypes.map((type) {
        final isSelected = _selectedType == type;
        return InkWell(
          onTap: () => setState(() => _selectedType = type),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? IncidentType.getColor(type).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              border: Border.all(
                color: isSelected 
                    ? IncidentType.getColor(type)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IncidentType.getIcon(type),
                  size: 16,
                  color: isSelected 
                      ? IncidentType.getColor(type)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  IncidentType.getDisplayName(type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? IncidentType.getColor(type)
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeveritySelector() {
    return Row(
      children: IncidentSeverity.allSeverities.map((severity) {
        final isSelected = _selectedSeverity == severity;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: severity != IncidentSeverity.critical ? 8 : 0,
            ),
            child: InkWell(
              onTap: () => setState(() => _selectedSeverity = severity),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? IncidentSeverity.getColor(severity).withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                  border: Border.all(
                    color: isSelected 
                        ? IncidentSeverity.getColor(severity)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: IncidentSeverity.getColor(severity),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      IncidentSeverity.getDisplayName(severity),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected 
                            ? IncidentSeverity.getColor(severity)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
