import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Custom weight picker bottom sheet with dual scroll wheels
class WeightPickerBottomSheet extends StatefulWidget {
  final int initialWeight;
  final String initialUnit;
  final Function(int weight, String unit) onConfirm;
  
  const WeightPickerBottomSheet({
    super.key,
    required this.initialWeight,
    required this.initialUnit,
    required this.onConfirm,
  });
  
  @override
  State<WeightPickerBottomSheet> createState() => _WeightPickerBottomSheetState();
}

class _WeightPickerBottomSheetState extends State<WeightPickerBottomSheet> {
  late FixedExtentScrollController _weightController;
  late FixedExtentScrollController _unitController;
  late int _currentWeight;
  late String _currentUnit;
  
  @override
  void initState() {
    super.initState();
    _currentWeight = widget.initialWeight;
    _currentUnit = widget.initialUnit;
    
    // Initialize controllers with initial values
    _weightController = FixedExtentScrollController(
      initialItem: _currentWeight - 30, // Offset for range 30-450
    );
    _unitController = FixedExtentScrollController(
      initialItem: _currentUnit == 'kg' ? 0 : 1,
    );
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _unitController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.5,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Handle bar
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
          const Text(
            'Kilonuzu Seçin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C5282),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Dual picker with highlight
          Expanded(
            child: Center(
              child: SizedBox(
                width: 280, // Compact width constraint
                child: Stack(
                  children: [
                    // Selection highlight overlay
                    Center(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAqua.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    // Pickers
                    Row(
                      children: [
                        // Weight value picker
                        Expanded(
                          flex: 2,
                          child: ListWheelScrollView.useDelegate(
                            controller: _weightController,
                            itemExtent: 50,
                            physics: const FixedExtentScrollPhysics(),
                            diameterRatio: 1.5,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _currentWeight = 30 + index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final weight = 30 + index;
                                final isSelected = weight == _currentWeight;
                                return Center(
                                  child: Text(
                                    '$weight',
                                    style: TextStyle(
                                      fontSize: isSelected ? 28 : 20,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                      color: isSelected 
                                          ? AppColors.secondaryAqua 
                                          : Colors.grey[500],
                                    ),
                                  ),
                                );
                              },
                              childCount: 421, // 30-450
                            ),
                          ),
                        ),
                        
                        // Unit picker
                        Expanded(
                          flex: 1,
                          child: ListWheelScrollView.useDelegate(
                            controller: _unitController,
                            itemExtent: 50,
                            physics: const FixedExtentScrollPhysics(),
                            diameterRatio: 1.5,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _currentUnit = index == 0 ? 'kg' : 'lbs';
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final unit = index == 0 ? 'kg' : 'lbs';
                                final isSelected = unit == _currentUnit;
                                return Center(
                                  child: Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: isSelected ? 28 : 20,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                      color: isSelected 
                                          ? AppColors.secondaryAqua 
                                          : Colors.grey[500],
                                    ),
                                  ),
                                );
                              },
                              childCount: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy text
          Text(
            'Bilgileriniz sadece hesaplama içindir, kaydedilmez.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Done button
          GestureDetector(
            onTap: () {
              widget.onConfirm(_currentWeight, _currentUnit);
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.secondaryAqua,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Tamam',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
