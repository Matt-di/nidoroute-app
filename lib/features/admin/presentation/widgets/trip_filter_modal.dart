import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TripFilterModal extends StatefulWidget {
  final String selectedStatus;
  final String selectedDateRange;
  final Function(String) onStatusChanged;
  final Function(String) onDateRangeChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearAll;

  const TripFilterModal({
    super.key,
    required this.selectedStatus,
    required this.selectedDateRange,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onApplyFilters,
    required this.onClearAll,
  });

  @override
  State<TripFilterModal> createState() => _TripFilterModalState();
}

class _TripFilterModalState extends State<TripFilterModal> {
  late String _modalStatus;
  late String _modalDateRange;

  final List<String> _statusOptions = ['All', 'Scheduled', 'In Progress', 'Completed', 'Cancelled'];
  final List<String> _dateRangeOptions = ['All Time', 'Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days'];

  @override
  void initState() {
    super.initState();
    _modalStatus = widget.selectedStatus;
    _modalDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Trips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _modalStatus = 'All';
                    _modalDateRange = 'All Time';
                  });
                  widget.onClearAll();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Filter
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.map((status) {
              final isSelected = _modalStatus == status;
              return FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _modalStatus = selected ? status : 'All';
                  });
                  widget.onStatusChanged(_modalStatus);
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Date Range Filter
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dateRangeOptions.map((range) {
              final isSelected = _modalDateRange == range;
              return FilterChip(
                label: Text(range),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _modalDateRange = selected ? range : 'All Time';
                  });
                  widget.onDateRangeChanged(_modalDateRange);
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilters();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
