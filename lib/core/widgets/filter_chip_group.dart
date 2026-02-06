import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterChipGroup extends StatefulWidget {
  final List<String> filters;
  final String initialValue;
  final ValueChanged<String> onSelected;

  const FilterChipGroup({
    super.key,
    required this.filters,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<FilterChipGroup> createState() => _FilterChipGroupState();
}

class _FilterChipGroupState extends State<FilterChipGroup> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: widget.filters.map((filter) {
          final isSelected = _selectedValue == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedValue = filter;
                  });
                  widget.onSelected(filter);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF03173D),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }).toList(),
      ),
    );
  }
}
