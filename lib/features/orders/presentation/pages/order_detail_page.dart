import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/storage/shared_prefs.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/orders/data/models/order_model.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final OrderEntity? order;

  const OrderDetailPage({super.key, required this.orderId, this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderEntity? _order;
  bool _isLoading = false;
  String? _error;

  // ⏱ Exponential backoff polling interval: 5 -> 10 -> 20 -> 40 -> 80 -> 160 -> 320 -> 360
  static const List<int> _pollingIntervals = [5, 10, 20, 40, 80, 160, 320, 360];
  int _intervalIndex = 0;
  Timer? _pollingTimer;

  // ⭐ Rating state
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmittingRating = false;
  bool _isRated = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _checkRatedStatus();

    if (_order == null) {
      _fetchOrder();
    } else {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _checkRatedStatus() {
    final id = int.tryParse(widget.orderId) ?? _order?.id ?? 0;
    if (id > 0) {
      _isRated = SharedPrefs.isOrderRated(id);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    if (!mounted) return;

    final status = _order?.status ?? 0;
    // Faqat yakunlanmagan (aktiv) buyurtmada polling ishlaydi (6: Yetkazildi, 1: Bekor qilindi)
    if (status == 6 || status == 1) return;

    final delay = _pollingIntervals[_intervalIndex];
    _pollingTimer = Timer(Duration(seconds: delay), () async {
      if (!mounted) return;
      await _fetchOrderSilently();

      // Intervalni oshirib borish, 360 soniyaga yetganda yana 5 soniyadan boshlanadi
      if (_intervalIndex < _pollingIntervals.length - 1) {
        _intervalIndex++;
      } else {
        _intervalIndex = 0;
      }

      _startPolling();
    });
  }

  Future<void> _fetchOrderSilently() async {
    try {
      final client = ApiClient();
      dynamic response;
      try {
        response = await client.get('orders/${widget.orderId}');
      } catch (_) {
        response = await client.get('orders');
      }

      if (!mounted) return;

      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final updatedOrder = OrderModel.fromJson(data);
        setState(() {
          _order = updatedOrder;
        });
        _checkRatedStatus();
      } else if (response is List) {
        final list = response.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        final match = list.where((o) => o.id.toString() == widget.orderId).firstOrNull;
        if (match != null) {
          setState(() {
            _order = match;
          });
          _checkRatedStatus();
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ApiClient();
      dynamic response;
      try {
        response = await client.get('orders/${widget.orderId}');
      } catch (_) {
        response = await client.get('orders');
      }

      if (!mounted) return;

      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        setState(() {
          _order = OrderModel.fromJson(data);
          _isLoading = false;
        });
        _checkRatedStatus();
        _startPolling();
        return;
      } else if (response is List) {
        final list = response.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        final match = list.where((o) => o.id.toString() == widget.orderId).firstOrNull;
        if (match != null) {
          setState(() {
            _order = match;
            _isLoading = false;
          });
          _checkRatedStatus();
          _startPolling();
          return;
        }
      }

      setState(() {
        _isLoading = false;
        _error = 'error.not_found'.tr();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'error.unknown'.tr();
        });
      }
    }
  }

  Future<void> _submitRating() async {
    final orderId = _order?.id ?? int.tryParse(widget.orderId) ?? 0;
    if (orderId == 0) return;

    setState(() => _isSubmittingRating = true);

    try {
      final client = ApiClient();
      final text = _commentController.text.trim();
      final commentPayload = text.isNotEmpty
          ? 'Baho: $_selectedRating/5. $text'
          : 'Baho: $_selectedRating/5';

      await client.post('orders/$orderId/comment', body: {
        'comment': commentPayload,
      });

      await SharedPrefs.setOrderRated(orderId);

      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
          _isRated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('orders.rate_thank_you'.tr()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
        // Fallback local save even if network failed
        await SharedPrefs.setOrderRated(orderId);
        setState(() => _isRated = true);
      }
    }
  }

  Widget _buildBackButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: isDark ? Colors.white : AppColors.neutral900,
        size: 20,
      ),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/orders');
        }
      },
    );
  }

  int _calculateActiveStep(int status) {
    switch (status) {
      case 1: // REJECTED
        return -1;
      case 2: // PAYMENT_PENDING
      case 3: // APPROVED
        return 0; // 1-bosqich: Qabul qilindi
      case 4: // IN_PROGRESS
        return 1; // 2-bosqich: Tayyorlanmoqda
      case 5: // DELIVERING
      case 7: // PICKUP_READY
        return 2; // 3-bosqich: Yo'lda / Tayyor
      case 6: // COMPLETED
        return 3; // 4-bosqich: Yetkazildi
      default:
        return 0;
    }
  }

  Widget _buildStatusStepper(BuildContext context, OrderEntity o, bool isDark) {
    final activeStep = _calculateActiveStep(o.status);
    final isRejected = o.status == 1;

    if (isRejected) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'orders.status_rejected'.tr(),
                    style: AppTextStyles.h3.copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o.comment != null && o.comment!.isNotEmpty
                        ? o.comment!
                        : 'Buyurtmangiz bekor qilindi',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isPickup = o.type?.toLowerCase().contains('pickup') == true ||
        o.type?.toLowerCase().contains('olib') == true ||
        (o.address == null || o.address!.isEmpty);

    final steps = [
      {'title': 'orders.status_approved'.tr(), 'icon': Icons.receipt_long_rounded},
      {'title': 'orders.status_in_progress'.tr(), 'icon': Icons.soup_kitchen_rounded},
      {
        'title': isPickup ? 'orders.status_pickup_ready'.tr() : 'orders.status_delivering'.tr(),
        'icon': isPickup ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
      },
      {'title': isPickup ? 'Bajarildi' : 'orders.status_completed'.tr(), 'icon': Icons.check_circle_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  o.statusText.startsWith('orders.status_') ? o.statusText.tr() : o.statusText,
                  style: AppTextStyles.h3.copyWith(
                    color: activeStep == 3 ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (o.estimatedTime != null && o.estimatedTime!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        o.estimatedTime!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Stepper Visual Nodes & Connectors (Equal distributed columns with zero-width wrap support)
          LayoutBuilder(
            builder: (context, constraints) {
              final stepCount = steps.length;
              final colWidth = constraints.maxWidth / stepCount;
              final halfCol = colWidth / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Chiziqlar (Orqa fonda)
                  Positioned(
                    top: 19, // 38px aylananing o'rtasi (38 / 2 = 19)
                    left: halfCol,
                    right: halfCol,
                    child: Row(
                      children: List.generate(stepCount - 1, (index) {
                        final isDone = activeStep > index;
                        return Expanded(
                          child: Container(
                            height: 3,
                            color: isDone
                                ? AppColors.success
                                : (isDark ? AppColors.neutral700 : AppColors.neutral200),
                          ),
                        );
                      }),
                    ),
                  ),

                  // 2. Bosqich tugunlari (Aylana va matnlar)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(stepCount, (stepIndex) {
                      final isDone = activeStep > stepIndex;
                      final isActive = activeStep == stepIndex;
                      final icon = steps[stepIndex]['icon'] as IconData;
                      final rawTitle = steps[stepIndex]['title'] as String;

                      // Uzoq so'zlar ("Tayyorlanmoqda") sig'maganda chiroyli bo'linishi uchun zero-width space
                      final displayTitle = rawTitle.replaceAll('Tayyorlanmoqda', 'Tayyor\u200Blanmoqda');

                      Color nodeBg;
                      Color iconColor;
                      if (isDone) {
                        nodeBg = AppColors.success;
                        iconColor = Colors.white;
                      } else if (isActive) {
                        nodeBg = AppColors.primary;
                        iconColor = Colors.white;
                      } else {
                        nodeBg = isDark ? AppColors.neutral800 : AppColors.neutral100;
                        iconColor = isDark ? AppColors.neutral500 : AppColors.neutral400;
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: nodeBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).cardColor,
                                    width: 2.5,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  isDone ? Icons.check_rounded : icon,
                                  color: iconColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                displayTitle,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                softWrap: true,
                                style: AppTextStyles.bodyExtraSmall.copyWith(
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive
                                      ? AppColors.primary
                                      : (isDone
                                          ? (isDark ? Colors.white : AppColors.neutral900)
                                          : AppColors.neutral500),
                                  fontSize: 10,
                                  height: 1.2,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, OrderEntity o, bool isDark) {
    if (o.status != 6) return const SizedBox.shrink();

    if (_isRated) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'orders.rate_thank_you'.tr(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'orders.rate_order'.tr(),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'orders.rate_desc'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 16),

          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              final isFilled = starNum <= _selectedRating;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRating = starNum);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 38,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Feedback comment input
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'orders.rate_comment_hint'.tr(),
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400),
              filled: true,
              fillColor: isDark ? AppColors.neutral800 : AppColors.neutral100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSubmittingRating ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmittingRating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'orders.rate_submit'.tr(),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('#${widget.orderId}', style: AppTextStyles.h2),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: _buildBackButton(context),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('#${widget.orderId}', style: AppTextStyles.h2),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: _buildBackButton(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error ?? 'error.not_found'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchOrder,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('common.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final o = _order!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showPayNow = o.paymentUrl != null && o.status != 6 && o.status != 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('#${o.id}', style: AppTextStyles.h2),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: _buildBackButton(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _fetchOrderSilently();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yangilandi'),
                  duration: Duration(milliseconds: 600),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Interactive Visual Status Stepper
            _buildStatusStepper(context, o, isDark),
            const SizedBox(height: 16),

            // 2. Customer Rating Card (If delivered)
            _buildRatingSection(context, o, isDark),
            const SizedBox(height: 16),

            // 3. Products List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('orders.items'.tr(), style: AppTextStyles.labelLarge),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: o.products.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (_, i) {
                      final item = o.products[i];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: (item.image.isNotEmpty && item.image.startsWith('http'))
                                  ? CachedNetworkImage(
                                      imageUrl: item.image,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const PizzaImagePlaceholder(fit: BoxFit.cover),
                                      errorWidget: (_, __, ___) =>
                                          const PizzaImagePlaceholder(fit: BoxFit.cover),
                                    )
                                  : const PizzaImagePlaceholder(fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: AppTextStyles.labelSmall),
                                if (item.variantName != null)
                                  Text(item.variantName!, style: AppTextStyles.bodyExtraSmall.copyWith(color: AppColors.neutral500)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('x${item.quantity}', style: AppTextStyles.bodySmall),
                              Text('${NumberFormatter.formatSum(item.price)} ${'common.currency'.tr()}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Order Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'product.info'.tr(), 
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (o.address != null && o.address!.isNotEmpty) ...[
                    _DetailRow(label: 'checkout.address'.tr(), value: o.address!),
                    const Divider(height: 24),
                  ],
                  if (o.branch != null && o.branch!.isNotEmpty) ...[
                    _DetailRow(label: 'checkout.branch'.tr(), value: o.branch!),
                    const Divider(height: 24),
                  ],
                  if (o.paymentMethodText != null && o.paymentMethodText!.isNotEmpty) ...[
                    _DetailRow(label: 'checkout.payment'.tr(), value: o.paymentMethodText!),
                    if (o.comment != null && o.comment!.isNotEmpty) const Divider(height: 24),
                  ],
                  if (o.comment != null && o.comment!.isNotEmpty)
                    _DetailRow(label: 'checkout.comment'.tr(), value: o.comment!),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Totals Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PriceRow(label: 'cart.subtotal'.tr(), price: o.subtotalPrice),
                  if (o.deliveryPrice > 0)
                     Padding(
                       padding: const EdgeInsets.only(top: 12),
                       child: _PriceRow(label: 'cart.delivery'.tr(), price: o.deliveryPrice),
                     ),
                  if (o.discountAmount > 0)
                     Padding(
                       padding: const EdgeInsets.only(top: 12),
                       child: _PriceRow(label: 'cart.discount'.tr(), price: o.discountAmount, isNegative: true),
                     ),
                  const Divider(height: 32),
                  _PriceRow(label: 'cart.total'.tr(), price: o.totalPrice, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (showPayNow || o.status == 6 || (o.phone != null && o.phone!.isNotEmpty))
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              child: SafeArea(
                child: Builder(
                  builder: (context) {
                    if (showPayNow) {
                      return SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final url = o.paymentUrl;
                            if (url != null && url.isNotEmpty) {
                              final uri = Uri.tryParse(url);
                              if (uri != null) {
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  debugPrint('Could not launch payment URL: $e');
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'orders.pay_now'.tr(),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    if (o.status != 6 && o.status != 1 && o.phone != null && o.phone!.isNotEmpty) {
                      return SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse('tel:${o.phone}');
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.phone, color: AppColors.primary),
                          label: Text(
                            'orders.call_branch'.tr(),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      );
                    }

                    if (o.status == 6) {
                      return SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleReorder(context, o),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'orders.reorder'.tr(),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return const SizedBox.shrink();
                  },
                ),
              ),
            )
          : null,
    );
  }

  void _handleReorder(BuildContext context, OrderEntity order) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'orders.reorder_confirm_title'.tr(),
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(dialogContext).textTheme.headlineMedium?.color,
            ),
          ),
          content: Text(
            'orders.reorder_confirm_desc'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'common.no'.tr(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _executeReorder(context, order);
              },
              child: Text(
                'common.yes'.tr(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _executeReorder(BuildContext context, OrderEntity order) {
    final homeState = context.read<HomeCubit>().state;
    if (homeState is! HomeLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('orders.reorder_error'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final fullProducts = homeState.fullProducts;
    bool someFailed = false;

    // Clear cart first
    context.read<CartCubit>().clear();

    for (final orderItem in order.products) {
      final matchedProductList = fullProducts.where((p) => p.slug == orderItem.slug);
      if (matchedProductList.isEmpty) {
        someFailed = true;
        continue;
      }
      final matchedProduct = matchedProductList.first;

      VariantEntity? matchedVariant;
      if (orderItem.variantName != null) {
        final matchedVariantList = matchedProduct.variants.where((v) => v.title == orderItem.variantName);
        if (matchedVariantList.isEmpty) {
          someFailed = true;
          continue;
        }
        matchedVariant = matchedVariantList.first;
      }

      for (int i = 0; i < orderItem.quantity; i++) {
        context.read<CartCubit>().addToCart(matchedProduct, variant: matchedVariant);
      }
    }

    if (someFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('orders.reorder_error'.tr()),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('orders.reorder_success'.tr()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    context.go('/cart');
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double price;
  final bool isNegative;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.price,
    this.isNegative = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.labelLarge.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        Text(
          "${isNegative ? '- ' : ''}${NumberFormatter.formatSum(price)} ${'common.currency'.tr()}",
          style: isTotal
              ? AppTextStyles.h4.copyWith(color: AppColors.primary)
              : AppTextStyles.labelSmall.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
