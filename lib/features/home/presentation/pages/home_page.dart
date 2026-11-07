import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/core/widgets/strada_refresh_control.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/header_location_pill.dart';

/// 📱 HomePage powered 100% by Server-Driven UI (SDUI)
/// Benchmarked against Dodo Pizza, Bellissimo, Uzum Tezkor, and Yandex Eats.
/// Compliant with Apple Guideline 2.5.2 & Google Play policies.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() => setState(() {}));
  }

  void _onSearchChanged() {
    final hasText = _searchController.text.trim().isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() => _hasSearchText = hasText);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, checkoutState) {
          return HeaderLocationPill(
            orderType: checkoutState.isDelivery ? 0 : 1,
            addressName: checkoutState.address,
            branchTitle: checkoutState.branchTitle,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const OrderTypeBottomSheet(),
              );
            },
          );
        },
      ),
      actions: [
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: isDark ? Colors.white : AppColors.neutral900,
                size: 24,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/notifications');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        color: isDark ? AppColors.darkSurface : Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: SizedBox(
          height: 50,
          child: TextField(
            key: const Key('home_search_input'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onChanged: (val) {
              context.read<HomeCubit>().search(val);
            },
            onSubmitted: (val) {
              context.read<HomeCubit>().search(val);
              _searchFocusNode.unfocus();
            },
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.neutral900,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Pitsa, kombo, ichimlik qidirish...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral400,
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 22,
                color: _searchFocusNode.hasFocus ? AppColors.primary : AppColors.neutral400,
              ),
              suffixIcon: _hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.neutral500),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _searchController.clear();
                        context.read<HomeCubit>().search('');
                        _searchFocusNode.unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.transparent,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.transparent,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeUpdatingUI) {
            return SDUIUpdateView(
              isSuccess: state.isSuccess,
              title: state.title,
              subtitle: state.subtitle,
            );
          }

          if (state is HomeLoading) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            );
          }

          if (state is HomeFailure) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                StradaSliverRefreshControl(
                  onRefresh: () => context.read<HomeCubit>().init(forceRefresh: true),
                ),
                _buildAppBar(context),
                SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AppIcons.wifiOff, size: 48, color: AppColors.neutral400),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<HomeCubit>().init(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('common.retry'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
          }

          if (state is HomeLoaded) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: SDUIRenderer(
                key: ValueKey('sdui_${state.sduiPage.versionUuid}'),
                page: state.sduiPage,
                selectedCategorySlug: state.selectedCategory,
                leadingSlivers: [
                  _buildAppBar(context),
                  _buildSearchBar(context),
                ],
                onRefresh: () => context.read<HomeCubit>().init(forceRefresh: true),
                onFilterCategory: (slug) => context.read<HomeCubit>().selectCategory(slug),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
