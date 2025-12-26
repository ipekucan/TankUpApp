class DrinkEntry {
  final String drinkId; // İçecek ID'si (water, coffee, tea vb.)
  final double amount; // İçilen miktar (ml)
  final double effectiveAmount; // Hidrasyon faktörüne göre efektif miktar (ml)
  final DateTime timestamp; // İçme zamanı

  DrinkEntry({
    required this.drinkId,
    required this.amount,
    required this.effectiveAmount,
    required this.timestamp,
  });

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'drinkId': drinkId,
      'amount': amount,
      'effectiveAmount': effectiveAmount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // JSON'dan oluşturma
  factory DrinkEntry.fromJson(Map<String, dynamic> json) {
    return DrinkEntry(
      drinkId: json['drinkId'] as String,
      amount: (json['amount'] as num).toDouble(),
      effectiveAmount: (json['effectiveAmount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}


