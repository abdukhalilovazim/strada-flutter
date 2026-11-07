import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class BranchItem {
  final String id;
  final String title;
  final String address;
  final String phone;
  final String workingHours;
  final double lat;
  final double lng;

  const BranchItem({
    required this.id,
    required this.title,
    required this.address,
    required this.phone,
    required this.workingHours,
    required this.lat,
    required this.lng,
  });

  factory BranchItem.fromJson(Map<String, dynamic> json) {
    return BranchItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Pizza Strada',
      address: json['address']?.toString() ?? 'Samarqand shahri',
      phone: json['phone']?.toString() ?? '+998 90 600 00 00',
      workingHours: json['working_hours']?.toString() ?? '10:00 - 23:00',
      lat: double.tryParse(json['latitude']?.toString() ?? '39.6542') ?? 39.6542,
      lng: double.tryParse(json['longitude']?.toString() ?? '66.9597') ?? 66.9597,
    );
  }
}

/// 🏢 100% Native Branches Page
class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  final ApiClient _client = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();
  List<BranchItem> _branches = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const List<BranchItem> _defaultBranches = [
    BranchItem(
      id: '1',
      title: 'Pizza Strada — Markaziy',
      address: "Samarqand sh., Mirzo Ulug'bek ko'chasi, 45",
      phone: '+998 90 600 00 00',
      workingHours: '10:00 - 23:00',
      lat: 39.6542,
      lng: 66.9597,
    ),
    BranchItem(
      id: '2',
      title: 'Pizza Strada — Registon',
      address: "Samarqand sh., Registon maydoni yaqinida, 12",
      phone: '+998 90 600 00 01',
      workingHours: '10:00 - 23:00',
      lat: 39.6508,
      lng: 66.9750,
    ),
    BranchItem(
      id: '3',
      title: 'Pizza Strada — Dagbitskaya',
      address: "Samarqand sh., Dagbitskaya ko'chasi, 8",
      phone: '+998 90 600 00 02',
      workingHours: '10:00 - 23:00',
      lat: 39.6620,
      lng: 66.9450,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    try {
      final response = await _client.get('branches');
      if (response is List && mounted) {
        final parsed = response
            .map((e) => BranchItem.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _branches = parsed.isNotEmpty ? parsed : _defaultBranches;
        });
      } else {
        if (mounted) setState(() => _branches = _defaultBranches);
      }
    } catch (_) {
      if (mounted) setState(() => _branches = _defaultBranches);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(BranchItem branch) async {
    // Open in Yandex Maps or fallback to browser
    final yandexUri = Uri.parse('yandexmaps://maps.yandex.ru/?pt=${branch.lng},${branch.lat}&z=16&l=map');
    final geoUri = Uri.parse('geo:${branch.lat},${branch.lng}?q=${branch.lat},${branch.lng}(${Uri.encodeComponent(branch.title)})');
    final webUri = Uri.parse('https://yandex.uz/maps/?pt=${branch.lng},${branch.lat}&z=16&l=map');

    if (await canLaunchUrl(yandexUri)) {
      await launchUrl(yandexUri);
    } else if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _branches.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.title.toLowerCase().contains(q) || b.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'profile.branches'.tr(),
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.neutral900, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchBranches,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Search Field
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 20, color: AppColors.neutral500),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Filial yoki ko\'cha nomini qidirish...',
                              hintStyle: TextStyle(fontSize: 14, color: AppColors.neutral400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? Colors.white : AppColors.neutral900,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.neutral400),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Hech qanday filial topilmadi',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((branch) => _buildBranchCard(context, branch, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildBranchCard(BuildContext context, BranchItem branch, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ochiq',
                        style: AppTextStyles.bodyExtraSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.neutral500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.address,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Working Hours
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.neutral500),
              const SizedBox(width: 8),
              Text(
                branch.workingHours,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callPhone(branch.phone),
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('Qo\'ng\'iroq'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openMap(branch),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text('Xaritada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

