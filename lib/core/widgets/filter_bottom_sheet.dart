import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

enum TripFilter { all, completed, inProgress, upcoming }
enum TripSort { date }

class FilterBottomSheet extends StatefulWidget {
  final TripFilter? selectedFilter;
  final TripSort? selectedSort;
  final DateTime? selectedDate;
  final String? searchQuery;
  final Function(TripFilter?, TripSort?, DateTime?, String?) onFiltersChanged;
  final VoidCallback? onClearAll;

  const FilterBottomSheet({
    super.key,
    this.selectedFilter,
    this.selectedSort,
    this.selectedDate,
    this.searchQuery,
    required this.onFiltersChanged,
    this.onClearAll,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  TripFilter? _selectedFilter;
  TripSort? _selectedSort;
  DateTime? _selectedDate;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
    _selectedSort = widget.selectedSort ?? TripSort.date;
    _selectedDate = widget.selectedDate;
    _searchQuery = widget.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
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
                const Icon(
                  Icons.filter_list_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Trips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date filter
                const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDateFilter(),
                
                const SizedBox(height: 24),
                
                // Status filter
                const Text(
                  'Trip Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...TripFilter.values.map((filter) => _buildStatusFilter(filter)),
                
                const SizedBox(height: 24),
                
                // Sort filter
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...TripSort.values.map((sort) => _buildSortFilter(sort)),
                
                const SizedBox(height: 32),
                
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _selectedDate != null 
                  ? AppTheme.primaryColor 
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? DateFormat('MMM d, yyyy').format(_selectedDate!)
                  : 'Select date',
              style: TextStyle(
                color: _selectedDate != null
                    ? AppTheme.textPrimary
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_selectedDate != null)
              GestureDetector(
                onTap: _clearDate,
                child: Icon(
                  Icons.clear,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(TripFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = _selectedFilter == filter ? null : filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedFilter == filter
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _selectedFilter == filter
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(filter),
                color: _selectedFilter == filter
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                _getFilterDisplayName(filter),
                style: TextStyle(
                  color: _selectedFilter == filter
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_selectedFilter == filter)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortFilter(TripSort sort) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSort = _selectedSort == sort ? null : sort;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedSort == sort
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _selectedSort == sort
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                _getSortIcon(sort),
                color: _selectedSort == sort
                    ? AppTheme.primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                _getSortDisplayName(sort),
                style: TextStyle(
                  color: _selectedSort == sort
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_selectedSort == sort)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilter = null;
      _selectedSort = TripSort.date;
      _selectedDate = null;
      _searchQuery = null;
    });
    widget.onClearAll?.call();
    Navigator.pop(context);
  }

  void _applyFilters() {
    widget.onFiltersChanged(
      _selectedFilter,
      _selectedSort,
      _selectedDate,
      _searchQuery,
    );
    Navigator.pop(context);
  }

  String _getFilterDisplayName(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return 'All Trips';
      case TripFilter.completed:
        return 'Completed';
      case TripFilter.inProgress:
        return 'In Progress';
      case TripFilter.upcoming:
        return 'Upcoming';
    }
  }

  IconData _getStatusIcon(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return Icons.list;
      case TripFilter.completed:
        return Icons.check_circle;
      case TripFilter.inProgress:
        return Icons.gps_fixed;
      case TripFilter.upcoming:
        return Icons.schedule;
    }
  }

  String _getSortDisplayName(TripSort sort) {
    switch (sort) {
      case TripSort.date:
        return 'Date';
    }
  }

  IconData _getSortIcon(TripSort sort) {
    switch (sort) {
      case TripSort.date:
        return Icons.calendar_today;
    }
  }
}

// Helper function to show the filter bottom sheet
Future<void> showFilterBottomSheet({
  required BuildContext context,
  TripFilter? selectedFilter,
  TripSort? selectedSort,
  DateTime? selectedDate,
  String? searchQuery,
  required Function(TripFilter?, TripSort?, DateTime?, String?) onFiltersChanged,
  VoidCallback? onClearAll,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => FilterBottomSheet(
      selectedFilter: selectedFilter,
      selectedSort: selectedSort,
      selectedDate: selectedDate,
      searchQuery: searchQuery,
      onFiltersChanged: onFiltersChanged,
      onClearAll: onClearAll,
    ),
  );
}
