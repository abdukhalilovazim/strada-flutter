import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/services/deep_link_service.dart';

void main() {
  group('DeepLinkService app.pizzastrada.uz Tests', () {
    final service = DeepLinkService.instance;

    test('Parses app.pizzastrada.uz universal links', () {
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/home')), '/home');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/promotions')), '/promotions');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/cart')), '/cart');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/checkout')), '/checkout');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/orders')), '/orders');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/profile')), '/profile');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/profile/edit')), '/profile/edit');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/branches')), '/branches');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/notifications')), '/notifications');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/saved-addresses')), '/saved-addresses');
      expect(service.parseUriToRoute(Uri.parse('https://app.pizzastrada.uz/product/pepperoni')), '/product/pepperoni');
    });

    test('Parses custom scheme links (strada://, pizzastrada://)', () {
      expect(service.parseUriToRoute(Uri.parse('strada://home')), '/home');
      expect(service.parseUriToRoute(Uri.parse('strada://cart')), '/cart');
      expect(service.parseUriToRoute(Uri.parse('strada://product/margarita')), '/product/margarita');
      expect(service.parseUriToRoute(Uri.parse('pizzastrada://promotions')), '/promotions');
    });

    test('buildUrl generates app.pizzastrada.uz URL', () {
      expect(DeepLinkService.buildUrl('/promotions'), 'https://app.pizzastrada.uz/promotions');
      expect(DeepLinkService.buildUrl('product/cheese'), 'https://app.pizzastrada.uz/product/cheese');
    });
  });
}
