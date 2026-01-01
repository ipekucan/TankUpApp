/// Challenge Level Model
/// Represents a single level/day in the challenge map
class ChallengeLevelModel {
  final int id;
  final int dayNumber;
  final bool isCompleted;
  final bool isLocked;
  final bool isActive;
  final String? challengeTitle;
  final String? challengeDescription;

  ChallengeLevelModel({
    required this.id,
    required this.dayNumber,
    this.isCompleted = false,
    this.isLocked = true,
    this.isActive = false,
    this.challengeTitle,
    this.challengeDescription,
  });

  /// Create a copy with updated values
  ChallengeLevelModel copyWith({
    int? id,
    int? dayNumber,
    bool? isCompleted,
    bool? isLocked,
    bool? isActive,
    String? challengeTitle,
    String? challengeDescription,
  }) {
    return ChallengeLevelModel(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
      isActive: isActive ?? this.isActive,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeDescription: challengeDescription ?? this.challengeDescription,
    );
  }
}
