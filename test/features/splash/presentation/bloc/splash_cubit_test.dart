import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/domain/repositories/home_repository.dart';
import 'package:pizza_strada/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:pizza_strada/features/splash/presentation/bloc/splash_state.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SplashCubit splashCubit;
  late MockHomeRepository mockHomeRepository;

  setUp(() {
    const MethodChannel('plugins.itmatrix.me/flutter_secure_storage')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null; // Always return null (unauthenticated) for tests
    });
    
    mockHomeRepository = MockHomeRepository();
    splashCubit = SplashCubit(mockHomeRepository);
  });

  tearDown(() {
    splashCubit.close();
  });

  const tSettingsOpen = SettingsEntity(
    discount: 0,
    canOrder: true,
    supportPhone: '123456',
    paymentMethods: [],
  );

  const tSettingsClosed = SettingsEntity(
    discount: 0,
    canOrder: false,
    supportPhone: '123456',
    paymentMethods: [],
  );

  group('SplashCubit', () {
    test('initial state should be SplashInitial', () {
      expect(splashCubit.state, SplashInitial());
    });

    blocTest<SplashCubit, SplashState>(
      'emits [SplashLoading, SplashMaintenance] when canOrder is false',
      build: () {
        when(() => mockHomeRepository.getSettings())
            .thenAnswer((_) async => const Right(tSettingsClosed));
        return splashCubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        SplashLoading(),
        const SplashMaintenance('Hozirda buyurtmalar qabul qilinmaydi. Ish vaqti: 09:00 - 23:00'),
      ],
    );

    blocTest<SplashCubit, SplashState>(
      'emits [SplashLoading, SplashUnauthenticated] when canOrder is true and no token',
      build: () {
        when(() => mockHomeRepository.getSettings())
            .thenAnswer((_) async => const Right(tSettingsOpen));
        return splashCubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        SplashLoading(),
        SplashUnauthenticated(),
      ],
    );
  });
}
