import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final WarrantyStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getStatusTextColor(status);
    final bgColor = AppTheme.getStatusBgColor(status);
    final borderColor = AppTheme.getStatusBorderColor(status);
    final icon = AppTheme.getStatusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 10.0,
        vertical: isCompact ? 3.0 : 5.0,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 10.5 : 11.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
