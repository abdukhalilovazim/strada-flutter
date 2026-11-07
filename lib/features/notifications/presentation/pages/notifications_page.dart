import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecases.dart';
import '../bloc/notifications_cubit.dart';

class NotificationsPage extends StatelessWidget {
  final NotificationsCubit? cubit;
  const NotificationsPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _NotificationsView(),
      );
    }

    try {
      context.read<NotificationsCubit>();
      return const _NotificationsView();
    } catch (_) {
      return BlocProvider(
        create: (_) {
          try {
            return getIt<NotificationsCubit>()..loadNotifications();
          } catch (_) {
            // Fallback for standalone tests or when DI is not initialized
            final repo = NotificationRepositoryImpl(NotificationRemoteDataSourceImpl());
            return NotificationsCubit(
              GetNotificationsUseCase(repo),
              MarkAllNotificationsReadUseCase(repo),
              MarkNotificationReadUseCase(repo),
            )..loadNotifications();
          }
        },
        child: const _NotificationsView(),
      );
    }
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  IconData _resolveIcon(String iconKey, NotificationType type) {
    switch (iconKey) {
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'coupon':
        return Icons.confirmation_number_outlined;
      case 'order':
        return Icons.delivery_dining_rounded;
      default:
        return type.isPromo
            ? Icons.local_offer_rounded
            : type.isOrder
                ? Icons.delivery_dining_rounded
                : Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
      return '$mins daqiqa oldin';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      final hourStr = dateTime.hour.toString().padLeft(2, '0');
      final minuteStr = dateTime.minute.toString().padLeft(2, '0');
      return 'Bugun, $hourStr:$minuteStr';
    } else if (difference.inHours < 48) {
      final hourStr = dateTime.hour.toString().padLeft(2, '0');
      final minuteStr = dateTime.minute.toString().padLeft(2, '0');
      return 'Kecha, $hourStr:$minuteStr';
    } else {
      final dayStr = dateTime.day.toString().padLeft(2, '0');
      final monthStr = dateTime.month.toString().padLeft(2, '0');
      return '$dayStr.$monthStr.${dateTime.year}';
    }
  }

  void _showNotificationDetail(BuildContext context, NotificationEntity item) {
    HapticFeedback.lightImpact();
    context.read<NotificationsCubit>().markAsRead(item.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badgeColor = item.type.isPromo
        ? const Color(0xFFFF9800)
        : item.type.isOrder
            ? AppColors.success
            : AppColors.primary;

    final badgeTitle = item.type.isPromo
        ? 'notifications.type_promo'.tr()
        : item.type.isOrder
            ? 'notifications.type_order'.tr()
            : 'notifications.type_system'.tr();

    final icon = _resolveIcon(item.icon, item.type);
    final formattedTime = _formatTime(item.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Icon, Badge, Time & Close button
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: badgeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeTitle,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 13, color: AppColors.neutral400),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutral400,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                item.title,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 12),

              // Full description body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                  ),
                ),
                child: Text(
                  item.body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.neutral300 : AppColors.neutral800,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Primary CTA button (if route present)
              if (item.route != null && item.route!.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (item.route == '/home' || item.route == '/promotions' || item.route == '/orders') {
                        context.go(item.route!);
                      } else {
                        context.push(item.route!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      item.actionLabel ?? 'common.view'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Secondary Close button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.neutral800,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('common.close'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final notifications = state is NotificationsLoaded ? state.notifications : <NotificationEntity>[];
        final filteredList = state is NotificationsLoaded ? state.filteredNotifications : <NotificationEntity>[];
        final unreadCount = state is NotificationsLoaded ? state.unreadCount : 0;
        final selectedFilter = state is NotificationsLoaded ? state.selectedFilter : 'all';
        final isLoading = state is NotificationsLoading;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'notifications.title'.tr(),
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            centerTitle: false,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.neutral900,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    tooltip: 'notifications.mark_all_read'.tr(),
                    icon: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 22),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<NotificationsCubit>().markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('notifications.all_read_success'.tr()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.neutral200,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter Chips Bar - Full Width Background
              if (notifications.isNotEmpty)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context: context,
                          id: 'all',
                          label: 'notifications.filter_all'.tr(),
                          count: state is NotificationsLoaded ? state.countForFilter('all') : notifications.length,
                          isSelected: selectedFilter == 'all',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context: context,
                          id: 'promo',
                          label: 'notifications.filter_promos'.tr(),
                          count: state is NotificationsLoaded ? state.countForFilter('promo') : null,
                          icon: Icons.local_offer_outlined,
                          isSelected: selectedFilter == 'promo',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context: context,
                          id: 'order',
                          label: 'notifications.filter_orders'.tr(),
                          count: state is NotificationsLoaded ? state.countForFilter('order') : null,
                          icon: Icons.delivery_dining_outlined,
                          isSelected: selectedFilter == 'order',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

              // Main Notifications List / Empty state / Loading state
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : filteredList.isEmpty
                        ? _buildEmptyState(context, isDark)
                        : RefreshIndicator(
                            onRefresh: () => context.read<NotificationsCubit>().refresh(),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, index) {
                                final item = filteredList[index];
                                return _buildNotificationCard(context, item, isDark);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String id,
    required String label,
    int? count,
    IconData? icon,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<NotificationsCubit>().setFilter(id);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : const Color(0xFFF1F3F5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : (isDark ? AppColors.neutral400 : AppColors.neutral600),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : (isDark ? AppColors.neutral300 : AppColors.neutral700),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? AppColors.neutral700 : AppColors.neutral300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.neutral900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationEntity item, bool isDark) {
    final icon = _resolveIcon(item.icon, item.type);
    final formattedTime = _formatTime(item.createdAt);

    final itemColor = item.type.isPromo
        ? const Color(0xFFFF9800)
        : item.type.isOrder
            ? AppColors.success
            : AppColors.primary;

    return InkWell(
      onTap: () => _showNotificationDetail(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? (isDark ? AppColors.darkCard.withValues(alpha: 0.6) : const Color(0xFFFAFBFC))
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !item.isRead
                ? AppColors.primary.withValues(alpha: 0.45)
                : (isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7)),
            width: !item.isRead ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (!item.isRead)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.isRead
                    ? (isDark ? AppColors.neutral800 : AppColors.neutral100)
                    : itemColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: item.isRead ? (isDark ? AppColors.neutral400 : AppColors.neutral500) : itemColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: !item.isRead ? FontWeight.w800 : FontWeight.w600,
                            color: item.isRead
                                ? (isDark ? AppColors.neutral300 : AppColors.neutral700)
                                : (isDark ? Colors.white : AppColors.neutral900),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      height: 1.35,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formattedTime,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral400,
                          fontSize: 11,
                        ),
                      ),
                      if (item.isRead) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'notifications.read_status'.tr(),
                          style: const TextStyle(
                            color: AppColors.neutral400,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Arrow to indicate clickable detail
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? AppColors.neutral500 : AppColors.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'notifications.empty_title'.tr(),
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'notifications.empty_desc'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.neutral400 : AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text('notifications.go_to_menu'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
