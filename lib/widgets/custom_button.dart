import 'package:flutter/material.dart';
import '../config/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isSecondary;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGradient = LinearGradient(
      colors: color != null 
          ? [color!, color!.withOpacity(0.8)] 
          : [AppConstants.primary, AppConstants.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final secondaryBg = isDark ? Colors.white10 : AppConstants.primaryLight;
    final secondaryFg = isDark ? Colors.white : AppConstants.primary;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isSecondary ? null : primaryGradient,
        color: isSecondary ? secondaryBg : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: isSecondary ? [] : [
          BoxShadow(
            color: (color ?? AppConstants.primary).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: isSecondary ? secondaryFg : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: isSecondary ? secondaryFg : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
