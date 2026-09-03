import 'package:flutter/material.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';

class OverdueFilter extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const OverdueFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all'),
          _buildFilterChip('Has Balance', 'balance'),
          _buildFilterChip('Settled', 'settled'),
          _buildFilterChip('Overdue (30+ days)', 'overdue'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onFilterChanged(value),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: AppTextStyles.body.copyWith(
          fontSize: 13,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
