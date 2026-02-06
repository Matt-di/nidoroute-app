import 'package:flutter/material.dart';
import '../../../../core/models/incident.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../core/widgets/app_button.dart';

class IncidentResolutionSheet extends StatefulWidget {
  final String tripId;
  final Function(String incidentId, String resolutionNotes) onResolve;

  const IncidentResolutionSheet({
    super.key,
    required this.tripId,
    required this.onResolve,
  });

  @override
  State<IncidentResolutionSheet> createState() => _IncidentResolutionSheetState();
}

class _IncidentResolutionSheetState extends State<IncidentResolutionSheet> {
  final _resolutionNotesController = TextEditingController();
  final IncidentService _incidentService = IncidentService();
  
  List<Incident> _incidents = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedIncidentId;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  @override
  void dispose() {
    _resolutionNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    try {
      final incidents = await _incidentService.getIncidents(
        tripId: widget.tripId,
        status: 'unresolved', // Only show unresolved incidents
      );
      
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading incidents: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resolveIncident() async {
    if (_selectedIncidentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an incident to resolve'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_resolutionNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide resolution notes'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onResolve(
        _selectedIncidentId!,
        _resolutionNotesController.text.trim(),
      );
    } finally {
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
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resolve Incident',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Select and resolve an open incident',
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

          // Content
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Incidents List
                  const Text(
                    'Open Incidents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_incidents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Open Incidents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All incidents for this trip have been resolved',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._incidents.map((incident) => _buildIncidentCard(incident)),
                  
                  const SizedBox(height: 20),
                  
                  // Resolution Notes
                  const Text(
                    'Resolution Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _resolutionNotesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe how this incident was resolved...',
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
                        return 'Please provide resolution notes';
                      }
                      if (value.trim().length < 10) {
                        return 'Resolution notes must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Resolve Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Resolve Incident',
                      onPressed: (_incidents.isEmpty || _isSubmitting) ? null : _resolveIncident,
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

  Widget _buildIncidentCard(Incident incident) {
    final isSelected = _selectedIncidentId == incident.id;
    
    return InkWell(
      onTap: () => setState(() => _selectedIncidentId = incident.id),
      borderRadius: BorderRadius.circular(AppTheme.radius12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Incident Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: IncidentType.getColor(incident.type).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IncidentType.getIcon(incident.type),
                color: IncidentType.getColor(incident.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Incident Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        IncidentType.getDisplayName(incident.type),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: IncidentSeverity.getColor(incident.severity).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          IncidentSeverity.getDisplayName(incident.severity),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: IncidentSeverity.getColor(incident.severity),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reported: ${_formatDateTime(incident.reportedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }
}
