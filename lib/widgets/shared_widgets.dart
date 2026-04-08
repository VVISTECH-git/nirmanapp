// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';

// ─── RUPEE FORMATTER ─────────────────────────────────────

String formatRupees(int paise, {bool compact = false}) {
  final rupees = paise / 100;
  if (compact) {
    if (rupees >= 10000000) return '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
    if (rupees >= 100000) return '₹${(rupees / 100000).toStringAsFixed(1)}L';
    if (rupees >= 1000) return '₹${(rupees / 1000).toStringAsFixed(0)}K';
  }
  return '₹${rupees.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

int rupeesToPaise(double rupees) => (rupees * 100).round();
double paiseToRupees(int paise) => paise / 100;

// ─── STATUS BADGE ─────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge(this.status, {super.key, this.fontSize = 11});

  String get label {
    return AppStrings.taskStatusLabels[status] ??
        AppStrings.phaseStatusLabels[status] ??
        AppStrings.issueStatusLabels[status] ??
        status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: AppTheme.statusColor(status),
        ),
      ),
    );
  }
}

// ─── PRIORITY BADGE ───────────────────────────────────────

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge(this.priority, {super.key});

  Color get color {
    switch (priority) {
      case 'critical': return const Color(0xFFE24B4A);
      case 'high': return const Color(0xFFD85A30);
      case 'medium': return const Color(0xFFEF9F27);
      default: return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(priority, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── AVATAR ───────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final double size;
  final Color? color;

  const UserAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 36,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? const Color(0xFFE6F1FB);
    final fgColor = color != null ? Colors.white : const Color(0xFF185FA5);

    if (imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w600, color: fgColor),
      ),
    );
  }
}

// ─── SECTION HEADER ──────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E), letterSpacing: 0.8)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: const TextStyle(fontSize: 13, color: Color(0xFF378ADD), fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

// ─── METRIC CARD ─────────────────────────────────────────

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

// ─── PROGRESS BAR ────────────────────────────────────────

class NirmanProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final double height;

  const NirmanProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: (progress / 100).clamp(0.0, 1.0),
        backgroundColor: const Color(0xFFEEEEEE),
        valueColor: AlwaysStoppedAnimation(color ?? const Color(0xFF378ADD)),
        minHeight: height,
      ),
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: const Color(0xFFDDDDDD)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
            if (buttonLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onButton, child: Text(buttonLabel!)),
            ]
          ],
        ),
      ),
    );
  }
}

// ─── LOADING SCREEN ──────────────────────────────────────

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── FILTER CHIPS ────────────────────────────────────────

class FilterChips extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final Function(String) onSelected;

  const FilterChips({
    super.key,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = selected == options[i];
          return Padding(
            padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelected(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF378ADD) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF378ADD) : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────

class NirmanFAB extends StatelessWidget {
  final VoidCallback onTap;
  final String? label;

  const NirmanFAB({super.key, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onTap,
        icon: const Icon(Icons.add),
        label: Text(label!),
      );
    }
    return FloatingActionButton(
      onPressed: onTap,
      child: const Icon(Icons.add),
    );
  }
}

// ─── DROPDOWN (avoids DropdownButtonFormField deprecation) ───

class NirmanDropdown<T> extends StatelessWidget {
  final String label;
  final T selected;
  final Map<T, String> items;
  final Function(T) onChanged;

  const NirmanDropdown({
    super.key,
    required this.label,
    required this.selected,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selected,
          isDense: true,
          items: items.entries
              .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
