import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// Ilovadagi yagona standart matn kiritish komponenti.
///
/// AGENTS.md 8.2 talablari bo'yicha:
/// - borderRadius: 14px
/// - Fon: Light rejimda [AppColors.neutral50], Dark rejimda [AppColors.darkSurface]
/// - Border: Odatiy 1px [AppColors.neutral200] (darkda [AppColors.neutral800]), fokuslanganda 1.5px [AppColors.primary]
/// - Qiymat mavjud bo'lganda avtomatik o'chirish (`Icons.close_rounded`) ikonkasi
/// - Padding: gorizontal 16px, vertikal 14px
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showClearButton;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final bool autocorrect;
  final bool enableSuggestions;
  final SpellCheckConfiguration? spellCheckConfiguration;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixText,
    this.prefixStyle,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showClearButton = true,
    this.errorText,
    this.validator,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.spellCheckConfiguration = const SpellCheckConfiguration.disabled(),
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _effectiveController;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _showClear = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      if (oldWidget.controller == null) {
        _effectiveController.dispose();
      }
      _effectiveController = widget.controller ?? TextEditingController();
      _showClear = _effectiveController.text.isNotEmpty;
      _effectiveController.addListener(_handleTextChange);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleTextChange);
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (hasText != _showClear) {
      setState(() {
        _showClear = hasText;
      });
    }
  }

  void _clearText() {
    _effectiveController.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        width: 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1.5,
      ),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? AppColors.darkError : AppColors.error,
        width: 1,
      ),
    );

    final focusedErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? AppColors.darkError : AppColors.error,
        width: 1.5,
      ),
    );

    Widget? suffix;
    if (widget.suffixIcon != null) {
      suffix = widget.suffixIcon;
    } else if (widget.showClearButton && _showClear && widget.enabled && !widget.readOnly) {
      suffix = IconButton(
        icon: Icon(
          Icons.close_rounded,
          size: 18,
          color: isDark ? AppColors.neutral400 : AppColors.neutral500,
        ),
        splashRadius: 20,
        onPressed: _clearText,
      );
    }

    Widget? prefixWidget;
    if (widget.prefix != null) {
      prefixWidget = widget.prefix;
    } else if (widget.prefixIcon != null) {
      prefixWidget = Icon(
        widget.prefixIcon,
        size: 20,
        color: isDark ? AppColors.neutral400 : AppColors.neutral500,
      );
    }

    return TextFormField(
      controller: _effectiveController,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      obscureText: widget.obscureText,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      spellCheckConfiguration: widget.spellCheckConfiguration,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      validator: widget.validator,
      style: AppTextStyles.bodyLarge.copyWith(
        color: isDark ? Colors.white : AppColors.neutral900,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.neutral50,
        hintText: widget.hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.neutral500 : AppColors.neutral400,
        ),
        labelText: widget.labelText,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.neutral400 : AppColors.neutral500,
        ),
        prefixIcon: prefixWidget,
        prefixText: widget.prefixText,
        prefixStyle: widget.prefixStyle ??
            AppTextStyles.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.neutral900,
              fontWeight: FontWeight.w500,
            ),
        suffixIcon: suffix,
        errorText: widget.errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: focusedErrorBorder,
      ),
    );
  }
}
