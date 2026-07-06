import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// Murojaat yuborish sahifasi.
///
/// Foydalanuvchi murojaat turini tanlab, xabar yozadi va "Yuborish" tugmasini bosadi.
/// Muvaffaqiyatli yuborilgandan keyin sahifa yopiladi.
class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final _messageController = TextEditingController();
  String? _selectedPurpose;
  bool _isSubmitting = false;
  int _charCount = 0;

  final List<Map<String, String>> _purposes = [
    {'key': 'food', 'translation': 'profile.inquiry_purpose_food'},
    {'key': 'delivery', 'translation': 'profile.inquiry_purpose_delivery'},
    {'key': 'service', 'translation': 'profile.inquiry_purpose_service'},
    {'key': 'suggestion', 'translation': 'profile.inquiry_purpose_suggestion'},
    {'key': 'complaint', 'translation': 'profile.inquiry_purpose_complaint'},
    {'key': 'other', 'translation': 'profile.inquiry_purpose_other'},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _selectedPurpose != null && _messageController.text.trim().length >= 5;

  Future<void> _submitInquiry() async {
    FocusScope.of(context).unfocus();
    if (!_isFormValid) return;

    setState(() => _isSubmitting = true);

    try {
      const String mutation = r'''
        mutation createInquiry($type: String!, $message: String!) {
          createInquiry(type: $type, message: $message)
        }
      ''';

      final client = buildGraphQLClient();
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {
          'type': _selectedPurpose,
          'message': _messageController.text.trim(),
        },
        operationName: 'createInquiry',
      ));

      if (result.hasException) throw result.exception!;

      if (!mounted) return;

      // Muvaffaqiyatli — dialog ko'rsatib, sahifani yopamiz
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'profile.support'.tr(),
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(dialogContext).textTheme.headlineMedium?.color,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'profile.inquiry_success'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'common.yes'.tr(),
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context); // Sahifani yopamiz
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Unauthenticated')
                ? 'error.unauthorized'.tr()
                : 'error.server'.tr(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('profile.support_inquiry'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purpose section
            Row(
              children: [
                Text(
                  'profile.inquiry_purpose'.tr(),
                  style: AppTextStyles.h4.copyWith(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                const Text(' *', style: TextStyle(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _purposes.map((purpose) {
                final isSelected = _selectedPurpose == purpose['key'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedPurpose = isSelected ? null : purpose['key'];
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : (isDark ? AppColors.neutral800 : AppColors.neutral50),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.neutral700 : AppColors.neutral200),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      purpose['translation']!.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white : AppColors.neutral900),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Message section
            Row(
              children: [
                Text(
                  'profile.message'.tr(),
                  style: AppTextStyles.h4.copyWith(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                const Text(' *', style: TextStyle(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 500,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              onChanged: (text) => setState(() => _charCount = text.length),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'profile.message_hint'.tr(),
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                filled: true,
                fillColor: isDark
                    ? AppColors.neutral800.withValues(alpha: 0.5)
                    : AppColors.neutral50,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_charCount/500',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _isSubmitting
            ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              )
            : _AnimatedScaleButton(
                onTap: _isFormValid ? _submitInquiry : null,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isFormValid ? AppColors.primary : AppColors.neutral200,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: _isFormValid ? Colors.white : AppColors.neutral400,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'profile.send'.tr(),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: _isFormValid ? Colors.white : AppColors.neutral400,
                          fontWeight: FontWeight.bold,
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

class _AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedScaleButton({required this.child, required this.onTap});

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: !isEnabled ? null : (_) => setState(() => _scale = 0.96),
      onTapUp: !isEnabled ? null : (_) => setState(() => _scale = 1.0),
      onTapCancel: !isEnabled ? null : () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
