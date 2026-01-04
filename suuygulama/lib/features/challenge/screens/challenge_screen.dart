import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../../providers/daily_hydration_provider.dart';
import '../../../utils/app_colors.dart';

import '../../../screens/shop_screen.dart';
import '../models/challenge_level_model.dart';

/// Custom Painter for Level Progress Arcs
/// Draws 4 separate segments (25% each) that can be filled based on progress
class LevelProgressPainter extends CustomPainter {
  final double progress; // 0 to 4, representing 0 to 100%

  LevelProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4; // Leave some space for the progress arcs
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 // Much thicker stroke for chunky rings
      ..strokeCap = StrokeCap.round; // Rounded ends
    
    // Draw empty arcs (white outline)
    paint.color = Colors.white;
    
    // Each arc represents 25% (90 degrees), with small gaps between
    const arcAngle = math.pi / 2 * 0.8; // 80% of 90 degrees, leaving 20% gap
    const gapAngle = math.pi / 2 * 0.2; // 20% gap
    
    for (int i = 0; i < 4; i++) {
      final startAngle = i * (arcAngle + gapAngle) - math.pi / 2; // Start from top
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcAngle,
        false,
        paint,
      );
    }
    
    // Draw filled arcs based on progress
    paint.color = const Color(0xFFF1DF80); // Gold
    
    final filledSegments = progress.clamp(0, 4).floor();
    final partialProgress = progress - filledSegments;
    
    for (int i = 0; i < filledSegments; i++) {
      final startAngle = i * (arcAngle + gapAngle) - math.pi / 2; // Start from top
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcAngle,
        false,
        paint,
      );
    }
    
    // Draw partial progress if applicable
    if (partialProgress > 0 && filledSegments < 4) {
      final startAngle = filledSegments * (arcAngle + gapAngle) - math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcAngle * partialProgress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LevelProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Challenge Screen - Gamified Onboarding Flow
/// Features:
/// - Gamified onboarding with floating star, welcome card, and breathing start button
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with TickerProviderStateMixin {
  late AnimationController _starController;
  late Animation<double> _starAnimation;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  final bool _showOnboarding = true;
  bool _showWelcomeCard = false;
  bool _startButtonBreathing = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers safely
    _starController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _starController, curve: Curves.easeInOut));
    
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    // Dispose animation controllers to prevent memory leaks
    _starController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  /// Generate the challenge path with the repeating pattern
  /// 7 Blue Drop Buttons followed by 1 Gold Chest Button
  List<ChallengeLevelModel> _generateChallengePath() {
    final List<ChallengeLevelModel> levels = [];
    
    for (int i = 1; i <= 30; i++) {
      final isGoldChest = (i % 8 == 0); // Every 8th item is a gold chest
      
      levels.add(ChallengeLevelModel(
        id: i,
        dayNumber: i,
        isCompleted: i <= 5, // First 5 days completed as example
        isLocked: i > 6,     // Lock future levels
        isActive: i == 6,    // Day 6 is active
        challengeTitle: isGoldChest ? 'Hazine Sandığı' : 'Su Damlası',
        challengeDescription: isGoldChest 
          ? 'Özel hazine sandığı! Ekstra coin kazan.'
          : 'Günlük su içme görevi',
      ));
    }
    
    return levels;
  }

  void _startOnboarding() {
    setState(() {
      _showWelcomeCard = true;
    });
  }

  void _closeWelcomeCard() {
    setState(() {
      _showWelcomeCard = false;
      _startButtonBreathing = true;
    });
    _breathingController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDACAB1), // Root background as requested
      body: Stack(
        children: [
          // Layer 1 (Bottom): The Scrollable Map
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 160), // Add space at top to prevent content hiding
                  _buildStartButton(),
                  const SizedBox(height: 40), // Space after start button
                  ..._buildChallengeSteps(context),
                ],
              ),
            ),
          ),
          
          // Layer 2 (Top): The Fixed Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),

          // Layer 3: Back Button (Bottom Left)
          Positioned(
            bottom: 30,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF5D4037),
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Layer 4 (Overlay): The Onboarding Modal
          if (_showWelcomeCard) _buildWelcomeCard(),
          
          // Floating Star for Onboarding
          if (_showOnboarding)
            Positioned(
              bottom: 20,
              right: 20,
              child: AnimatedBuilder(
                animation: _starAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_starAnimation.value),
                    child: GestureDetector(
                      onTap: _startOnboarding,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'challenge_market_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShopScreen(),
            ),
          );
        },
        backgroundColor: AppColors.softPinkButton,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.shopping_bag,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // Build the fixed header with title, coin badge, and weekly tracker
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFDACAB1), // Same background color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title and Coin Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title with Gold/White Gradient
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFFFD700), Colors.white], // Gold to White gradient
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Mücadele Yolu',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Right Button: Coin Badge (same as TankRoomScreen)
              _buildCoinBadge(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weekly Tracker: 7 Circles
          _buildWeeklyTracker(),
        ],
      ),
    );
  }

  // Build the coin badge widget (same as TankRoomScreen)
  Widget _buildCoinBadge() {
    return SizedBox(
      width: 70, // Set a specific width to provide bounded constraints
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Pill (Text Capsule) - Glassmorphic
          Positioned(
            left: 20, // Leave space for overlapping coin
            top: 5, // Center vertically with coin
            child: Container(
              height: 30,
              padding: const EdgeInsets.only(left: 24, right: 16, top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9), // Glassmorphic white
                borderRadius: BorderRadius.circular(15), // Stadium
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Consumer<DailyHydrationProvider>(
                builder: (context, dailyHydrationProvider, _) {
                  return Text(
                    '${dailyHydrationProvider.tankCoins}',
                    style: const TextStyle(
                      color: Color(0xFFE59F4F), // Orange/Dark Grey
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  );
                },
              ),
            ),
          ),
          // Foreground Coin Circle - 3D Metallic Gold
          Positioned(
            left: 0,
            top: 0, // Aligned to top
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF59D), // Light gold (highlight)
                    Color(0xFFFFD700), // Pure gold
                    Color(0xFFFFB300), // Darker gold/orange
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  // Strong shadow for pop effect
                  BoxShadow(
                    color: const Color(0xFFE59F4F).withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.monetization_on_rounded,
                  color: Color(0xFFFFFFFF), // White icon
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build weekly tracker with 7 circles
  Widget _buildWeeklyTracker() {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < days.length; i++)
          _buildDayTracker(days[i], i == 0), // First day is active as example
      ],
    );
  }

  // Build individual day tracker
  Widget _buildDayTracker(String day, bool isActive) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34, // Slightly increased size
          height: 34,
          decoration: BoxDecoration(
            color: isActive 
              ? const Color(0xFFF1DF80) // Active: Gold
              : const Color(0xFF615D51), // Inactive: Dark Grey
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isActive ? Icons.check : Icons.local_cafe_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Build the START button with breathing animation
  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _startButtonBreathing ? _breathingAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _startButtonBreathing = false;
              });
              _breathingController.stop();
              _breathingController.value = 0.0;
              // Show the first challenge details
              if (_generateChallengePath().isNotEmpty) {
                _showChallengeDetails(context, _generateChallengePath()[0]);
              }
            },
            child: Container(
              width: 140,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF817C6A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF6B675A), // One shade darker
                  width: 1,
                ),
                boxShadow: [ // 3D effect with strong bottom shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 6), // Strong bottom shadow
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'START',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // Increased font size
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChallengeDetails(BuildContext context, ChallengeLevelModel level) {
    // For first challenge, show special sheet as per requirements
    if (level.dayNumber == 1) {
      _showFirstMissionSheet(context, level);
    } else {
      // Show challenge details sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _ChallengeDetailsSheet(level: level),
      );
    }
  }

  void _showFirstMissionSheet(BuildContext context, ChallengeLevelModel level) {
    // Show first mission sheet as per requirements
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Günlük Hedef',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Task
              Text(
                'Bugün 1 L su iç.',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softPinkButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tamam',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build all challenge steps
  List<Widget> _buildChallengeSteps(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final levels = _generateChallengePath();
    
    return List.generate(levels.length, (index) {
      final level = levels[index];
      final isGoldChest = (index + 1) % 8 == 0; // Every 8th item is gold
      final centerX = screenWidth / 2;
      final offsetX = math.sin(index / 1.8) * (centerX - 80); // Curvier wave, constrained to prevent clipping
      
      return Padding(
        padding: EdgeInsets.only(
          top: index == 0 ? 0 : 40, // Increased vertical spacing
          left: offsetX > 0 ? 0 : offsetX.abs(),
          right: offsetX < 0 ? 0 : offsetX.abs(),
        ),
        child: isGoldChest 
          ? _buildGoldChestButton(context, level, index)
          : _buildBlueDropButtonWithProgress(context, level, index),
      );
    });
  }

  // Build Blue Drop Button with Thick Rounded Progress Arcs
  Widget _buildBlueDropButtonWithProgress(BuildContext context, ChallengeLevelModel level, int index) {
    // Simulate progress for demo - in real app this would come from actual progress
    double progress = 0.0;
    if (level.isCompleted) {
      progress = 4.0; // 100%
    } else if (level.isActive) {
      progress = 2.0; // 50% for active
    } else {
      progress = 0.0; // 0% for locked
    }
    
    return SizedBox(
      width: 84, // Slightly larger
      height: 84,
      child: CustomPaint(
        painter: LevelProgressPainter(progress: progress),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF98C5C5), // New color as requested
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  // Build Gold Chest Button with Yellow-Orange Gradient and Outer Glow
  Widget _buildGoldChestButton(BuildContext context, ChallengeLevelModel level, int index) {
    return Container(
      width: 88, // Slightly larger than drop buttons
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ // Yellow-Orange Gradient
            const Color(0xFFFFF59D),
            const Color(0xFFFFD700),
            const Color(0xFFFFB300),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [ // Strong outer glow (shadow with high blur)
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
            blurRadius: 25,
            spreadRadius: 6,
            offset: Offset.zero,
          ),
        ],
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  // Build the Welcome Game Card overlay
  Widget _buildWelcomeCard() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Buraya hoş geldin! Birlikte mücadele etmeye hazır mısın? Akvaryumunun ve senin suya ihtiyacın var. Hadi başlayalım!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: _closeWelcomeCard,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF817C6A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Challenge Details Sheet
class _ChallengeDetailsSheet extends StatelessWidget {
  final ChallengeLevelModel level;

  const _ChallengeDetailsSheet({required this.level});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: level.dayNumber % 8 == 0 
                        ? Colors.transparent
                        : const Color(0xFF98C5C5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: level.dayNumber % 8 == 0
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : [],
                    ),
                    child: Icon(
                      level.dayNumber % 8 == 0
                        ? Icons.inventory_2_outlined
                        : Icons.water_drop_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gün ${level.dayNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          level.challengeTitle ?? '',
                          style: const TextStyle(
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                level.challengeDescription ?? '',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatusChip(level.isCompleted, 'Tamamlandı'),
                  const SizedBox(width: 12),
                  _buildStatusChip(!level.isLocked, 'Kilitsiz'),
                  const SizedBox(width: 12),
                  _buildStatusChip(level.isActive, 'Aktif'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(bool condition, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: condition ? const Color(0xFFFF8A80) : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: condition ? Colors.white : Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
