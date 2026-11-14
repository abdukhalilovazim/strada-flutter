import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/sets/data/models/set_detail_model.dart';
import '../bloc/set_detail_cubit.dart';

class SetDetailPage extends StatelessWidget {
  final String slug;

  const SetDetailPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SetDetailCubit()..loadSet(slug),
      child: const _SetDetailView(),
    );
  }
}

class _SetDetailView extends StatelessWidget {
  const _SetDetailView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<SetDetailCubit, SetDetailState>(
      listener: (context, state) {
        if (state is SetDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SetDetailLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.neutral900,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is! SetDetailLoaded) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.neutral900,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.neutral400),
                  const SizedBox(height: 12),
                  Text('common.error'.tr(), style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text('common.back'.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        final set = state.set;
        final isValid = state.isValid;
        final uncompleted = state.uncompletedGroupTitles;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              set.title,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.textTheme.headlineMedium?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.neutral900,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Rasm yoki Maxsus Hero Banner (agar rasm bo'lmasa)
                _buildSetHero(set, isDark),
                const SizedBox(height: 18),

                // 2. Set Sarlavhasi va Narxi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            set.title,
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: isDark ? Colors.white : AppColors.neutral900,
                            ),
                          ),
                          if (set.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              set.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${NumberFormatter.formatSum(set.price.toInt())} ${'common.currency'.tr()}',
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 3. Tarkibiy Guruhlar (Ketma-ket qadamlar)
                ...set.groups.asMap().entries.map((entry) {
                  final groupIndex = entry.key;
                  final group = entry.value;
                  final selectedInGroup = state.selections[group.id] ?? [];
                  final isGroupCompleted = selectedInGroup.length >= group.minSelections;

                  final ruleText = group.selectionType == 'FIXED'
                      ? 'Komboga kiritilgan'
                      : (group.selectionType == 'SINGLE_CHOICE'
                          ? '1 ta taom tanlang'
                          : '${group.minSelections} - ${group.maxSelections} ta tanlang');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Guruh headeri (Qadam ko'rsatkichi bilan)
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isGroupCompleted ? AppColors.success : AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isGroupCompleted ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isGroupCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                    : Text(
                                        '${groupIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.title,
                                    style: AppTextStyles.h4.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : AppColors.neutral900,
                                    ),
                                  ),
                                  Text(
                                    ruleText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isGroupCompleted
                                    ? AppColors.success.withValues(alpha: 0.14)
                                    : AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isGroupCompleted
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                isGroupCompleted
                                    ? '✓ (${selectedInGroup.length}/${group.minSelections})'
                                    : '${selectedInGroup.length}/${group.minSelections}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isGroupCompleted ? AppColors.success : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Guruhdagi mahsulotlar ro'yxati
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: group.items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              color: isDark ? AppColors.darkBorder : AppColors.neutral100,
                            ),
                            itemBuilder: (context, index) {
                              final item = group.items[index];
                              final isSelected = selectedInGroup.any((i) => i.id == item.id);

                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  context.read<SetDetailCubit>().toggleItem(group, item);
                                },
                                borderRadius: index == 0
                                    ? const BorderRadius.vertical(top: Radius.circular(16))
                                    : (index == group.items.length - 1
                                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                        : BorderRadius.zero),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.05)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      // Mahsulot rasmi yoki chiroyli fallback icon
                                      _buildItemThumbnail(item, isDark),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productTitle,
                                              style: AppTextStyles.labelMedium.copyWith(
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                fontSize: 14,
                                                color: isDark ? Colors.white : AppColors.neutral900,
                                              ),
                                            ),
                                            if (item.variantTitle.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.variantTitle,
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : (isDark ? AppColors.neutral400 : AppColors.neutral500),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Tanlov belgisi
                                      if (group.selectionType == 'FIXED')
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.success,
                                          size: 22,
                                        )
                                      else if (group.selectionType == 'SINGLE_CHOICE')
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked_rounded
                                              : Icons.radio_button_unchecked_rounded,
                                          color: isSelected ? AppColors.primary : AppColors.neutral400,
                                          size: 22,
                                        )
                                      else
                                        Icon(
                                          isSelected
                                              ? Icons.check_box_rounded
                                              : Icons.check_box_outline_blank_rounded,
                                          color: isSelected ? AppColors.primary : AppColors.neutral400,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ogohlantirish (agar hali barcha guruhlar tanlanmagan bo'lsa)
                  if (!isValid && uncompleted.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Iltimos, tanlang: ${uncompleted.join(", ")}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  Row(
                    children: [
                      // Miqdor Stepper [-] 1 [+]
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              onPressed: state.quantity > 1
                                  ? () => context.read<SetDetailCubit>().decrementQuantity()
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 48),
                            ),
                            Text(
                              '${state.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () => context.read<SetDetailCubit>().incrementQuantity(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 48),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Savatga qo'shish tugmasi
                      Expanded(
                        child: AppButton(
                          text: '${'cart.add'.tr()} — ${NumberFormatter.formatSum(state.totalPrice.toInt())} ${'common.currency'.tr()}',
                          onTap: isValid
                              ? () {
                                  HapticFeedback.mediumImpact();

                                  // Tanlangan tarkiblarni yig'amiz
                                  final flatSelections = <SetSelectionItem>[];
                                  for (final entry in state.selections.entries) {
                                    final groupId = entry.key;
                                    for (final item in entry.value) {
                                      if (item.productVariantId != null) {
                                        flatSelections.add(SetSelectionItem(
                                          setGroupId: groupId,
                                          productVariantId: item.productVariantId!,
                                          productTitle: item.productTitle,
                                          variantTitle: item.variantTitle,
                                        ));
                                      }
                                    }
                                  }

                                  context.read<CartCubit>().addSetToCart(
                                        set,
                                        flatSelections,
                                        quantity: state.quantity,
                                      );

                                  final messenger = ScaffoldMessenger.of(context);
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('${set.title} ${'cart.added'.tr()}'),
                                      backgroundColor: AppColors.primary,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      action: SnackBarAction(
                                        label: 'cart.title'.tr(),
                                        textColor: Colors.white,
                                        onPressed: () {
                                          messenger.clearSnackBars();
                                          context.go('/cart');
                                        },
                                      ),
                                    ),
                                  );

                                  context.pop();
                                }
                              : () {
                                  HapticFeedback.heavyImpact();
                                  final messenger = ScaffoldMessenger.of(context);
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Iltimos, avval tanlang: ${uncompleted.join(", ")}'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Set rasmi yoki rasm bo'lmaganda chiroyli Hero Banner
  Widget _buildSetHero(SetDetailModel set, bool isDark) {
    final hasRealImage = set.imageUrl.isNotEmpty &&
        !set.imageUrl.contains('logo.png') &&
        !set.imageUrl.contains('placeholder') &&
        !set.imageUrl.contains('no-image');

    if (!hasRealImage) {
      return _buildNoImageHero(set, isDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1.25,
        child: CachedNetworkImage(
          imageUrl: set.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => const PizzaImagePlaceholder(
            width: double.infinity,
            height: double.infinity,
          ),
          errorWidget: (_, __, ___) => _buildNoImageHero(set, isDark),
        ),
      ),
    );
  }

  /// Rasm bo'lmaganda ko'rsatiladigan zamonaviy va chiroyli Banner
  Widget _buildNoImageHero(SetDetailModel set, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2B1D1D), const Color(0xFF1F1717)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFEF2F2)],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.local_pizza_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                SizedBox(width: 4),
                Text(
                  'PIZZA STRADA COMBO',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Guruh ichidagi har bir taom uchun rasm yoki chiroyli fallback icon
  Widget _buildItemThumbnail(SetGroupItemModel item, bool isDark) {
    final hasRealImage = item.imageUrl.isNotEmpty &&
        !item.imageUrl.contains('logo.png') &&
        !item.imageUrl.contains('placeholder') &&
        !item.imageUrl.contains('no-image');

    if (!hasRealImage) {
      return _buildItemPlaceholder(isDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: CachedNetworkImage(
          imageUrl: item.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildItemPlaceholder(isDark),
          errorWidget: (_, __, ___) => _buildItemPlaceholder(isDark),
        ),
      ),
    );
  }

  /// Taom uchun fallback icon placeholder
  Widget _buildItemPlaceholder(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 20,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
