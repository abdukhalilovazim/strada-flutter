import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/theme/app_theme.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/pages/story_viewer_page.dart';

void main() {
  final sampleStories = [
    const StoryEntity(
      id: 1,
      title: 'Yangi pitsalar 🍕',
      previewImage: 'https://example.com/thumb1.jpg',
      slides: [
        StorySlideEntity(
          id: 101,
          imageUrl: 'https://example.com/slide1.jpg',
          title: 'Haqiqiy Italyancha Pitsalar',
          description: 'Yupqa xamir va mayin pishloq',
          buttonText: 'Buyurtma berish',
          buttonUrl: '/home',
        ),
        StorySlideEntity(
          id: 102,
          imageUrl: 'https://example.com/slide2.jpg',
          title: 'Ikkinchi slayd',
          description: 'Katta chegirma',
          buttonText: 'Aksiyaga o\'tish',
          buttonUrl: '/promotions',
        ),
      ],
      isViewed: false,
    ),
    const StoryEntity(
      id: 2,
      title: 'Aksiya 2+1 🎁',
      previewImage: 'https://example.com/thumb2.jpg',
      slides: [
        StorySlideEntity(
          id: 201,
          imageUrl: 'https://example.com/slide3.jpg',
          title: '2+1 pitsa bepul',
          description: 'Margarita bepul',
          buttonText: 'Aksiyani ko\'rish',
          buttonUrl: '/promotions',
        ),
      ],
      isViewed: true,
    ),
  ];

  testWidgets('StoryViewerPage displays slides, progress bars, and navigates between slides',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StoryViewerPage(
          stories: sampleStories,
          initialStoryIndex: 0,
        ),
      ),
    );

    // Initial slide
    expect(find.text('Yangi pitsalar 🍕'), findsOneWidget);
    expect(find.text('Haqiqiy Italyancha Pitsalar'), findsOneWidget);
    expect(find.text('Buyurtma berish'), findsOneWidget);

    // Tap right area to advance to next slide
    await tester.tapAt(const Offset(300, 300));
    await tester.pump();

    // Second slide
    expect(find.text('Ikkinchi slayd'), findsOneWidget);
    expect(find.text('Aksiyaga o\'tish'), findsOneWidget);

    // Tap close button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  });
}

