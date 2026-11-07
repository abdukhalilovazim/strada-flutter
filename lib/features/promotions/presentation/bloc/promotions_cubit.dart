import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import '../../data/datasources/promotions_remote_data_source.dart';
import '../../domain/entities/promotion_deal_entity.dart';

abstract class PromotionsState extends Equatable {
  const PromotionsState();

  @override
  List<Object?> get props => [];
}

class PromotionsInitial extends PromotionsState {}

class PromotionsLoading extends PromotionsState {}

class PromotionsLoaded extends PromotionsState {
  final List<PromotionDealEntity> deals;
  final List<ProductEntity> discountProducts;

  const PromotionsLoaded({
    required this.deals,
    required this.discountProducts,
  });

  @override
  List<Object?> get props => [deals, discountProducts];
}

class PromotionsFailure extends PromotionsState {
  final String message;

  const PromotionsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class PromotionsCubit extends Cubit<PromotionsState> {
  final PromotionsRemoteDataSource _dataSource;

  PromotionsCubit([PromotionsRemoteDataSource? dataSource])
      : _dataSource = dataSource ?? PromotionsRemoteDataSourceImpl(),
        super(PromotionsInitial());

  Future<void> loadPromotions({bool forceRefresh = false}) async {
    if (!forceRefresh && state is PromotionsLoaded) return;

    if (state is! PromotionsLoaded) {
      emit(PromotionsLoading());
    }

    try {
      final payload = await _dataSource.getPromotions();
      emit(PromotionsLoaded(
        deals: payload.deals,
        discountProducts: payload.discountProducts,
      ));
    } catch (e) {
      emit(PromotionsFailure(e.toString()));
    }
  }
}

