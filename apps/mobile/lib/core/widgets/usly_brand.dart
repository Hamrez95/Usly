import 'package:flutter/material.dart';
import 'package:usly/core/theme/usly_theme.dart';

class UslyBrandMark extends StatelessWidget {
  const UslyBrandMark({this.size = 48, this.showName = true, super.key});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Usly',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * .14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(size * .34),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .7),
              ),
            ),
            child: ExcludeSemantics(
              child: Image.asset(
                'assets/branding/usly-mark.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(width: UslySpacing.md),
            ExcludeSemantics(
              child: Text(
                'Usly',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UslyCompanionScene extends StatelessWidget {
  const UslyCompanionScene({this.height = 156, this.caption, super.key});

  final double height;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'دو فرم آرام کنار یک جرقه مشترک؛ نماد پیدا کردن حال خوب دونفره',
      image: true,
      child: Column(
        children: [
          Image.asset(
            'assets/illustrations/usly-companion.png',
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          if (caption != null) ...[
            const SizedBox(height: UslySpacing.sm),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class UslyPrivacyBadge extends StatelessWidget {
  const UslyPrivacyBadge({this.label = 'پاسخ خصوصی تو', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = UslyPalette.of(context);
    return Semantics(
      label: '$label؛ فقط خودت می‌بینی',
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(
          horizontal: UslySpacing.md,
          vertical: UslySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: palette.privacy.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 17, color: palette.privacy),
            const SizedBox(width: UslySpacing.sm),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: palette.privacy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UslyGuestNotice extends StatelessWidget {
  const UslyGuestNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UslySpacing.md),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.science_outlined, color: colors.onTertiaryContainer),
            const SizedBox(width: UslySpacing.sm),
            Expanded(
              child: Text(
                'حساب مهمان موقت است؛ برای تست مناسب است، اما بعد از خروج یا حذف برنامه ممکن است قابل‌بازیابی نباشد.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
