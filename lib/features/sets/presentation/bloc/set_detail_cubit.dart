import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/storage/shared_prefs.dart';
import '../../data/models/set_detail_model.dart';

abstract class SetDetailState extends Equatable {
  const SetDetailState();

  @override
  List<Object?> get props => [];
}

class SetDetailLoading extends SetDetailState {}

class SetDetailLoaded extends SetDetailState {
  final SetDetailModel set;
  final Map<int, List<SetGroupItemModel>> selections; // groupId -> selected items
  final int quantity;

  const SetDetailLoaded({
    required this.set,
    required this.selections,
    this.quantity = 1,
  });

  /// Barcha majburiy guruhlar to'ldirilganmi?
  bool get isValid {
    for (final group in set.groups) {
      final selectedCount = (selections[group.id] ?? []).length;
      if (selectedCount < group.minSelections) {
        return false;
      }
    }
    return true;
  }

  /// Qaysi guruhlar to'ldirilmagan?
  List<String> get uncompletedGroupTitles {
    final uncompleted = <String>[];
    for (final group in set.groups) {
      final selectedCount = (selections[group.id] ?? []).length;
      if (selectedCount < group.minSelections) {
        uncompleted.add(group.title);
      }
    }
    return uncompleted;
  }

  double get totalPrice => set.price * quantity;

  SetDetailLoaded copyWith({
    SetDetailModel? set,
    Map<int, List<SetGroupItemModel>>? selections,
    int? quantity,
  }) {
    return SetDetailLoaded(
      set: set ?? this.set,
      selections: selections ?? this.selections,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [set, selections, quantity];
}

class SetDetailError extends SetDetailState {
  final String message;

  const SetDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class SetDetailCubit extends Cubit<SetDetailState> {
  final ApiClient _client;

  // In-memory tezkor kesh
  static final Map<String, SetDetailModel> _memoryCache = {};

  SetDetailCubit([ApiClient? client])
      : _client = client ?? ApiClient(),
        super(SetDetailLoading());

  static String _getLangKey() {
    final context = AppConstants.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      return EasyLocalization.of(context)?.locale.languageCode ?? 'ru';
    }
    return 'ru';
  }

  /// Kesh kalitini hisoblash (slug + language)
  static String _buildCacheKey(String slug) {
    final lang = _getLangKey();
    return 'cached_set_${slug}_$lang';
  }

  /// Keshni tozalash (majburiy yangilash yoki test uchun)
  static void clearCache([String? slug]) {
    if (slug != null) {
      _memoryCache.removeWhere((k, _) => k.contains('cached_set_$slug'));
    } else {
      _memoryCache.clear();
    }
  }

  Future<void> loadSet(String slug, {bool forceRefresh = false}) async {
    final cacheKey = _buildCacheKey(slug);
    bool hasCachedData = false;

    // 1-daraja: In-Memory kesh (0ms kechikish)
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final cachedModel = _memoryCache[cacheKey]!;
      _emitLoaded(cachedModel);
      hasCachedData = true;
    }

    // 2-daraja: Local persistent storage (SharedPrefs)
    if (!hasCachedData && !forceRefresh) {
      final cachedJsonStr = SharedPrefs.getString(cacheKey);
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJsonStr);
          if (decoded is Map<String, dynamic>) {
            final cachedModel = SetDetailModel.fromJson(decoded);
            _memoryCache[cacheKey] = cachedModel;
            _emitLoaded(cachedModel);
            hasCachedData = true;
          }
        } catch (_) {}
      }
    }

    // Agar keshda yo'q bo'lsa, yuklash indikatorini chiqaramiz
    if (!hasCachedData && state is! SetDetailLoaded) {
      emit(SetDetailLoading());
    }

    // 3-daraja: Tarmoqdan yangilash (Background refresh or Initial load)
    try {
      final response = await _client.get('sets/$slug');
      final dynamic rawData = (response is Map<String, dynamic> && response.containsKey('data'))
          ? response['data']
          : response;

      if (rawData is Map<String, dynamic>) {
        final setModel = SetDetailModel.fromJson(rawData);
        _memoryCache[cacheKey] = setModel;
        try {
          SharedPrefs.setString(cacheKey, jsonEncode(rawData));
        } catch (_) {}

        // Foydalanuvchi hali tanlov qilib ulgurmagan bo'lsa yoki birinchi yuklanish bo'lsa yangilaymiz
        if (!hasCachedData || state is! SetDetailLoaded) {
          _emitLoaded(setModel);
        } else {
          // Kesh allaqachon ko'rsatilgan bo'lsa, mavjud tanlovlarni saqlagan holda modelni yangilaymiz
          final loaded = state as SetDetailLoaded;
          emit(loaded.copyWith(set: setModel));
        }
      } else {
        if (!hasCachedData && state is! SetDetailLoaded) {
          emit(const SetDetailError('Set ma\'lumotlarini yuklab bo\'lmadi'));
        }
      }
    } catch (e) {
      // Agar keshda ma'lumot bo'lsa, xatolik chiqarmay kesh bilan ishlashni davom ettiramiz
      if (!hasCachedData && state is! SetDetailLoaded) {
        emit(SetDetailError(e.toString()));
      }
    }
  }

  void _emitLoaded(SetDetailModel setModel) {
    final initialSelections = <int, List<SetGroupItemModel>>{};

    for (final group in setModel.groups) {
      if (group.selectionType == 'FIXED') {
        final fixed = group.items.where((i) => i.isFixed).toList();
        initialSelections[group.id] = fixed.isNotEmpty ? fixed : List<SetGroupItemModel>.from(group.items);
      } else if (group.selectionType == 'SINGLE_CHOICE' && group.items.length == 1) {
        initialSelections[group.id] = [group.items.first];
      } else {
        initialSelections[group.id] = [];
      }
    }

    emit(SetDetailLoaded(
      set: setModel,
      selections: initialSelections,
      quantity: 1,
    ));
  }

  void toggleItem(SetGroupModel group, SetGroupItemModel item) {
    if (state is! SetDetailLoaded) return;
    if (group.selectionType == 'FIXED') return; // O'zgarmas taomlar qulflangan

    final loaded = state as SetDetailLoaded;
    final currentMap = Map<int, List<SetGroupItemModel>>.from(loaded.selections);
    final currentList = List<SetGroupItemModel>.from(currentMap[group.id] ?? []);

    if (group.selectionType == 'SINGLE_CHOICE') {
      // Bir tanlovli: bosilganini tanlaymiz
      currentMap[group.id] = [item];
    } else if (group.selectionType == 'MULTIPLE_CHOICE') {
      final index = currentList.indexWhere((i) => i.isSame(item));
      if (index >= 0) {
        currentList.removeAt(index);
      } else {
        if (currentList.length < group.maxSelections) {
          currentList.add(item);
        } else if (group.maxSelections == 1) {
          currentList.clear();
          currentList.add(item);
        }
      }
      currentMap[group.id] = currentList;
    }

    emit(loaded.copyWith(selections: currentMap));
  }

  void incrementQuantity() {
    if (state is! SetDetailLoaded) return;
    final loaded = state as SetDetailLoaded;
    if (loaded.quantity < 99) {
      emit(loaded.copyWith(quantity: loaded.quantity + 1));
    }
  }

  void decrementQuantity() {
    if (state is! SetDetailLoaded) return;
    final loaded = state as SetDetailLoaded;
    if (loaded.quantity > 1) {
      emit(loaded.copyWith(quantity: loaded.quantity - 1));
    }
  }
}

