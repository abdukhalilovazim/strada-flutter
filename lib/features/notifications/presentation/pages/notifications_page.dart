import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final String type; // 'order' | 'promo' | 'system'
  final IconData icon;
  final String? route;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.icon,
    this.route,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'all';

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Xush kelibsiz!',
      body: 'Strada Pizza ilovasiga xush kelibsiz. Eng issiq va mazali pitsalar sizni kutmoqda!',
      time: '1 soat oldin',
      type: 'system',
      icon: Icons.local_pizza_rounded,
      route: '/home',
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Aksiya: 2+1 pitsa bepul!',
      body: 'Har 2 ta katta pitsa buyurtma qilganingizda, Margarita pitsasi mutlaqo bepul qo\'shib beriladi!',
      time: 'Bugun, 12:40',
      type: 'promo',
      icon: Icons.local_offer_rounded,
      route: '/promotions',
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Yangi promokod: STRADA20',
      body: 'Buyurtmangizga 20 000 so\'m chegirma olish uchun STRADA20 promokodini qo\'llang.',
      time: 'Kecha, 18:20',
      type: 'promo',
      icon: Icons.confirmation_number_outlined,
      route: '/promotions',
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Tezkor yetkazib berish!',
      body: 'Strada Pizza Yunusobod filiali orqali buyurtmangiz 35 daqiqa ichida yetkaziladi.',
      time: '2 kun oldin',
      type: 'order',
      icon: Icons.delivery_dining_rounded,
      route: '/home',
      isRead: true,
    ),
  ];

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    return _notifications.where((n) => n.type == _selectedFilter).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcha bildirishnomalar o\'qilgan deb belgilandi'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'profile.notifications'.tr().isNotEmpty
                  ? 'profile.notifications'.tr()
                  : 'Bildirishnomalar',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
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
        centerTitle: true,
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
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                if (val == 'read') _markAllAsRead();
                if (val == 'clear') _clearAll();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Hammasini o\'qish',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Text(
                        'Tozalash',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 4),
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
        children: [
          // Filter Chips
          if (_notifications.isNotEmpty)
            Container(
              color: isDark ? AppColors.darkSurface : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _buildFilterChip(
                    id: 'all',
                    label: 'Barchasi',
                    count: _notifications.length,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    id: 'promo',
                    label: 'Aksiyalar',
                    icon: Icons.local_offer_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    id: 'order',
                    label: 'Buyurtmalar',
                    icon: Icons.delivery_dining_outlined,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

          // Main Notifications List / Empty state
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _filteredNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _filteredNotifications[index];
                      return _buildNotificationCard(item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    int? count,
    IconData? icon,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == id;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedFilter = id);
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
            if (count != null) ...[
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

  Widget _buildNotificationCard(NotificationItem item, bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => item.isRead = true);
        if (item.route != null && item.route!.isNotEmpty) {
          if (item.route == '/home' || item.route == '/promotions' || item.route == '/orders') {
            context.go(item.route!);
          } else {
            context.push(item.route!);
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !item.isRead
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7)),
            width: !item.isRead ? 1.4 : 1.0,
          ),
          boxShadow: [
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
                color: item.type == 'promo'
                    ? const Color(0xFFFF9800).withValues(alpha: 0.12)
                    : item.type == 'order'
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                color: item.type == 'promo'
                    ? const Color(0xFFFF9800)
                    : item.type == 'order'
                        ? AppColors.success
                        : AppColors.primary,
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
                            fontWeight: !item.isRead ? FontWeight.w800 : FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.neutral900,
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      height: 1.35,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.time,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
              'Hozircha bildirishnomalar yo\'q',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Yangi aksiyalar, maxsus takliflar va buyurtmangiz holati shu yerda aks etadi.',
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
                label: const Text('Menyuga qaytish', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
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
