import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Liquid glass card — clean, frosted white with subtle shadows
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 12,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.glassWhite,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? AppColors.glassBorder,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Button with gradient
class GlassButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final double borderRadius;
  final bool isLoading;
  final bool isSmall;
  final Color? color;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient,
    this.borderRadius = 14,
    this.isLoading = false,
    this.isSmall = false,
    this.color,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmall ? 16 : 24,
            vertical: widget.isSmall ? 10 : 14,
          ),
          decoration: BoxDecoration(
            gradient: widget.gradient ?? AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: (widget.color ?? AppColors.primaryStart)
                    .withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: widget.isSmall ? 16 : 20),
                      SizedBox(width: widget.isSmall ? 6 : 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: widget.isSmall ? 13 : 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Status badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded, color: color.withValues(alpha: 0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Clean white scaffold with subtle background
class GlassScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // Clean light background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          // Subtle decorative shapes
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.03),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Body
          SafeArea(child: body),
        ],
      ),
    );
  }
}

/// Approval chain visualization
class ApprovalChainWidget extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final bool isRejected;

  const ApprovalChainWidget({
    super.key,
    required this.steps,
    required this.currentStep,
    this.isRejected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.accentGreen
                    : AppColors.glassBorder,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;
        final isRejectedStep = isCurrent && isRejected;

        Color color;
        if (isRejectedStep) {
          color = AppColors.accentRed;
        } else if (isCompleted) {
          color = AppColors.accentGreen;
        } else if (isCurrent) {
          color = AppColors.accentAmber;
        } else {
          color = AppColors.textMuted;
        }

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : isRejectedStep
                        ? Icons.close
                        : isCurrent
                            ? Icons.hourglass_top
                            : Icons.circle_outlined,
                color: color,
                size: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }
}
