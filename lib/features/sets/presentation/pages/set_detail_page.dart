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

class _SetDetailView extends StatefulWidget {
  const _SetDetailView();

  @override
  State<_SetDetailView> createState() => _SetDetailViewState();
}

class _SetDetailViewState extends State<_SetDetailView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _groupKeys = {};
  bool _hasAttemptedAdd = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFirstUncompleted(SetDetailModel set, SetDetailLoaded state) {
    final uncompletedGroups = set.groups.where((g) {
      final count = (state.selections[g.id] ?? []).length;
      return count < g.minSelections;
    }).toList();

    if (uncompletedGroups.isNotEmpty) {
      final firstGroup = uncompletedGroups.first;
      final key = _groupKeys[firstGroup.id];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      }
    }
  }

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
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Rasm (faqat haqiqiy fotosurat mavjud bo'lganda chiqadi, keraksiz bo'sh card mutlaqo yo'q)
                if (set.hasRealImage) ...[
                  _buildSetHero(set, isDark),
                  const SizedBox(height: 18),
                ],

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
                  final groupKey = _groupKeys.putIfAbsent(group.id, () => GlobalKey());
                  final selectedInGroup = state.selections[group.id] ?? [];
                  final isGroupCompleted = selectedInGroup.length >= group.minSelections;
                  final isHighlightedError = _hasAttemptedAdd && !isGroupCompleted;

                  final ruleText = group.selectionType == 'FIXED'
                      ? 'Komboga kiritilgan'
                      : (group.selectionType == 'SINGLE_CHOICE'
                          ? '1 ta taom tanlang'
                          : '${group.minSelections} - ${group.maxSelections} ta tanlang');

                  return AnimatedContainer(
                    key: groupKey,
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 22),
                    padding: isHighlightedError
                        ? const EdgeInsets.all(12)
                        : EdgeInsets.zero,
                    decoration: isHighlightedError
                        ? BoxDecoration(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          )
                        : null,
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
                                color: isGroupCompleted
                                    ? AppColors.success
                                    : (isHighlightedError
                                        ? AppColors.primary
                                        : (isDark ? AppColors.neutral700 : AppColors.neutral400)),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  if (isGroupCompleted || isHighlightedError)
                                    BoxShadow(
                                      color: (isGroupCompleted ? AppColors.success : AppColors.primary).withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: isGroupCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                    : (isHighlightedError
                                        ? const Icon(Icons.priority_high_rounded, color: Colors.white, size: 16)
                                        : Text(
                                            '${groupIndex + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          )),
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
                                      color: isHighlightedError
                                          ? AppColors.primary
                                          : (isDark ? Colors.white : AppColors.neutral900),
                                    ),
                                  ),
                                  Text(
                                    ruleText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isHighlightedError
                                          ? AppColors.primary.withValues(alpha: 0.85)
                                          : (isDark ? AppColors.neutral400 : AppColors.neutral500),
                                      fontWeight: isHighlightedError ? FontWeight.w600 : FontWeight.normal,
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
                                    : (isHighlightedError
                                        ? AppColors.primary.withValues(alpha: 0.18)
                                        : AppColors.neutral500.withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isGroupCompleted
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : (isHighlightedError
                                          ? AppColors.primary
                                          : AppColors.neutral500.withValues(alpha: 0.25)),
                                  width: isHighlightedError ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                isGroupCompleted
                                    ? '✓ (${selectedInGroup.length}/${group.minSelections})'
                                    : (isHighlightedError
                                        ? 'Majburiy (${selectedInGroup.length}/${group.minSelections})'
                                        : '${selectedInGroup.length}/${group.minSelections}'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isGroupCompleted
                                      ? AppColors.success
                                      : (isHighlightedError
                                          ? AppColors.primary
                                          : (isDark ? AppColors.neutral300 : AppColors.neutral700)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Guruhdagi mahsulotlar ro'yxati (2 ustunli GridView, qurilma ekraniga moslashuvchan)
                        Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.sizeOf(context).width;
                            final cardWidth = (screenWidth - 32.0 - 10.0) / 2.0;
                            final itemAspectRatio = (cardWidth / 166.0).clamp(0.96, 1.25);

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: group.items.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: itemAspectRatio,
                              ),
                              itemBuilder: (context, index) {
                                final item = group.items[index];
                                final isSelected = selectedInGroup.any((i) => i.isSame(item));
                                final hasVariant = item.variantTitle.isNotEmpty &&
                                    item.variantTitle.toLowerCase().trim() != 'size' &&
                                    item.variantTitle.toLowerCase().trim() != 'null';

                                return Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      context.read<SetDetailCubit>().toggleItem(group, item);
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.06)
                                            : (isDark ? AppColors.darkCard : Colors.white),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkBorder : AppColors.neutral200),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
                                                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                            blurRadius: isSelected ? 6 : 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Rasm va tepasida tanlov belgisi
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  height: 96,
                                                  child: _buildItemGridThumbnail(item, isDark),
                                                ),
                                              ),
                                              Positioned(
                                                top: 7,
                                                right: 7,
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppColors.darkSurface.withValues(alpha: 0.9)
                                                        : Colors.white.withValues(alpha: 0.92),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.14),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: group.selectionType == 'FIXED'
                                                      ? const Icon(
                                                          Icons.check_circle_rounded,
                                                          color: AppColors.success,
                                                          size: 18,
                                                        )
                                                      : (group.selectionType == 'SINGLE_CHOICE'
                                                          ? Icon(
                                                              isSelected
                                                                  ? Icons.radio_button_checked_rounded
                                                                  : Icons.radio_button_unchecked_rounded,
                                                              color: isSelected ? AppColors.primary : AppColors.neutral400,
                                                              size: 18,
                                                            )
                                                          : Icon(
                                                              isSelected
                                                                  ? Icons.check_box_rounded
                                                                  : Icons.check_box_outline_blank_rounded,
                                                              color: isSelected ? AppColors.primary : AppColors.neutral400,
                                                              size: 18,
                                                            )),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Matnlar qismi
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item.productTitle,
                                                  style: AppTextStyles.labelMedium.copyWith(
                                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                    fontSize: 13.5,
                                                    color: isDark ? Colors.white : AppColors.neutral900,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (hasVariant) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    item.variantTitle,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : (isDark ? AppColors.neutral400 : AppColors.neutral500),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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

                                  context.pop();
                                }
                              : () {
                                  HapticFeedback.heavyImpact();
                                  setState(() {
                                    _hasAttemptedAdd = true;
                                  });
                                  _scrollToFirstUncompleted(set, state);

                                  final messenger = ScaffoldMessenger.of(context);
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Iltimos, avval tanlang: ${uncompleted.join(", ")}',
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 3),
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

  /// Set fotosurati (faqat haqiqiy rasm yuklangan bo'lsa chiqadi, bo'sh card yo'qotildi)
  Widget _buildSetHero(SetDetailModel set, bool isDark) {
    if (!set.hasRealImage) {
      return const SizedBox.shrink();
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
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// 2 ustunli Grid uchun har bir taom rasmi
  Widget _buildItemGridThumbnail(SetGroupItemModel item, bool isDark) {
    final hasRealImage = item.imageUrl.isNotEmpty &&
        !item.imageUrl.contains('logo.png') &&
        !item.imageUrl.contains('placeholder') &&
        !item.imageUrl.contains('no-image');

    if (!hasRealImage) {
      return Container(
        color: isDark ? AppColors.darkSurface : const Color(0xFFFFF7F5),
        child: Center(
          child: Icon(
            Icons.restaurant_rounded,
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: isDark ? AppColors.darkSurface : const Color(0xFFFFF7F5),
        child: Center(
          child: Icon(
            Icons.restaurant_rounded,
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
