import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/home_entities.dart';
import '../bloc/home_cubit.dart';

class StoryViewerPage extends StatefulWidget {
  final List<StoryEntity> stories;
  final int initialStoryIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialStoryIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> with SingleTickerProviderStateMixin {
  late int _currentStoryIndex;
  late int _currentSlideIndex;
  late AnimationController _animController;
  bool _isPaused = false;
  double _dragOffsetY = 0.0;

  StoryEntity get _currentStory => widget.stories[_currentStoryIndex];
  List<StorySlideEntity> get _slides {
    if (_currentStory.slides.isNotEmpty) {
      return _currentStory.slides;
    }
    return [
      StorySlideEntity(
        id: _currentStory.id,
        imageUrl: _currentStory.previewImage,
      ),
    ];
  }

  StorySlideEntity get _currentSlide {
    final slides = _slides;
    final safeIndex = _currentSlideIndex.clamp(0, slides.length - 1);
    return slides[safeIndex];
  }

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex.clamp(0, widget.stories.length - 1);
    _currentSlideIndex = 0;

    _animController = AnimationController(vsync: this);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSlideComplete();
      }
    });

    _markCurrentStoryViewed();
    _startSlideTimer();
  }

  void _markCurrentStoryViewed() {
    try {
      final story = _currentStory;
      context.read<HomeCubit>().markStoryViewed(story.id);
    } catch (_) {
      // HomeCubit might not be present in standalone tests or dialog contexts
    }
  }

  void _startSlideTimer() {
    final durationSec = _currentSlide.durationSeconds > 0 ? _currentSlide.durationSeconds : 5;
    _animController.duration = Duration(seconds: durationSec);
    _animController.forward(from: 0.0);
  }

  void _onSlideComplete() {
    if (_currentSlideIndex < _slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _startSlideTimer();
    } else {
      _nextStory();
    }
  }

  void _nextSlide() {
    HapticFeedback.selectionClick();
    if (_currentSlideIndex < _slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _startSlideTimer();
    } else {
      _nextStory();
    }
  }

  void _previousSlide() {
    HapticFeedback.selectionClick();
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _startSlideTimer();
    } else {
      _prevStory();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _currentSlideIndex = 0;
      });
      _markCurrentStoryViewed();
      _startSlideTimer();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _currentSlideIndex = 0;
      });
      _markCurrentStoryViewed();
      _startSlideTimer();
    } else {
      _startSlideTimer();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _animController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final slide = _currentSlide;
    final slidesCount = _slides.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 0 || _dragOffsetY > 0) {
            setState(() {
              _dragOffsetY += details.delta.dy;
            });
          }
        },
        onVerticalDragEnd: (details) {
          if (_dragOffsetY > 120 || details.primaryVelocity! > 600) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _dragOffsetY = 0.0;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0.0, _dragOffsetY, 0.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background image
              CachedNetworkImage(
                imageUrl: slide.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.neutral900,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                  ),
                ),
              ),

              // 2. Top subtle dark gradient for readable controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Touch Areas: Left (30%) & Right (70%) navigation with Long Press Pause
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _previousSlide,
                        onLongPressStart: (_) => _pause(),
                        onLongPressEnd: (_) => _resume(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _nextSlide,
                        onLongPressStart: (_) => _pause(),
                        onLongPressEnd: (_) => _resume(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Top Bars: Progress indicators & Header info
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Segmented Progress Bars
                      Row(
                        children: List.generate(slidesCount, (index) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Container(
                                  height: 3,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  child: AnimatedBuilder(
                                    animation: _animController,
                                    builder: (context, _) {
                                      double progress = 0.0;
                                      if (index < _currentSlideIndex) {
                                        progress = 1.0;
                                      } else if (index == _currentSlideIndex) {
                                        progress = _animController.value;
                                      }
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(color: Colors.white),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Story Header Row (Thumbnail, Title & Close Button)
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: story.previewImage,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.white24),
                                errorWidget: (_, __, ___) => const Icon(Icons.local_pizza_rounded, size: 20, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Strada Pizza',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
