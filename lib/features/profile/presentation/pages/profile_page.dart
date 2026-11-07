import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// 👤 ProfilePage powered 100% by Server-Driven UI (SDUI)
/// Compliant with Apple Guideline 2.5.2 & Google Play policies.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => SDUIPageCubit(slug: 'profile')..load(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'profile.title'.tr(),
            style: AppTextStyles.h2.copyWith(
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            ),
          ),
        ),
        body: BlocBuilder<SDUIPageCubit, SDUIPageState>(
          builder: (context, state) {
            if (state is SDUIPageLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is SDUIPageFailure) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.neutral400),
                    const SizedBox(height: 12),
                    Text(
                      'Internet bilan aloqa yo\'q',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SDUIPageCubit>().load(forceRefresh: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            }

            if (state is SDUIPageLoaded) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SDUIRenderer(
                  key: ValueKey('profile_sdui_${state.page.versionUuid}'),
                  page: state.page,
                  leadingSlivers: const [],
                  onRefresh: () => context.read<SDUIPageCubit>().load(forceRefresh: true),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
