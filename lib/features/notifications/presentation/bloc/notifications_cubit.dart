import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecases.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final String selectedFilter;

  const NotificationsLoaded({
    required this.notifications,
    this.selectedFilter = 'all',
  });

  List<NotificationEntity> get filteredNotifications {
    if (selectedFilter == 'all') return notifications;
    if (selectedFilter == 'promo') {
      return notifications.where((n) => n.type == NotificationType.promo).toList();
    }
    if (selectedFilter == 'order') {
      return notifications.where((n) => n.type == NotificationType.order).toList();
    }
    return notifications.where((n) => n.type.name == selectedFilter).toList();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  int countForFilter(String filter) {
    if (filter == 'all') return notifications.length;
    if (filter == 'promo') {
      return notifications.where((n) => n.type == NotificationType.promo).length;
    }
    if (filter == 'order') {
      return notifications.where((n) => n.type == NotificationType.order).length;
    }
    return notifications.where((n) => n.type.name == filter).length;
  }

  NotificationsLoaded copyWith({
    List<NotificationEntity>? notifications,
    String? selectedFilter,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [notifications, selectedFilter];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

@lazySingleton
class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkAllNotificationsReadUseCase _markAllNotificationsRead;
  final MarkNotificationReadUseCase _markNotificationRead;

  NotificationsCubit(
    this._getNotifications,
    this._markAllNotificationsRead,
    this._markNotificationRead,
  ) : super(NotificationsInitial());

  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    try {
      final items = await _getNotifications();
      emit(NotificationsLoaded(notifications: items));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final items = await _getNotifications();
      final currentFilter = (state is NotificationsLoaded)
          ? (state as NotificationsLoaded).selectedFilter
          : 'all';
      emit(NotificationsLoaded(notifications: items, selectedFilter: currentFilter));
    } catch (_) {}
  }

  void setFilter(String filter) {
    if (state is NotificationsLoaded) {
      emit((state as NotificationsLoaded).copyWith(selectedFilter: filter));
    }
  }

  Future<void> markAllAsRead() async {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      final allIds = current.notifications.map((n) => n.id).toList();
      final updated = current.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(current.copyWith(notifications: updated));

      try {
        await _markAllNotificationsRead(allIds);
      } catch (_) {}
    }
  }

  Future<void> markAsRead(String id) async {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      final updated = current.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      emit(current.copyWith(notifications: updated));

      try {
        await _markNotificationRead(id);
      } catch (_) {}
    }
  }
}
