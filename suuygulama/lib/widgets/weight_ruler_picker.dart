import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class WeightRulerPicker extends StatefulWidget {
  final double initialValue;
  final bool isKg;
  final ValueChanged<double> onValueChanged;

  const WeightRulerPicker({
    super.key,
    required this.initialValue,
    required this.isKg,
    required this.onValueChanged,
  });

  @override
  State<WeightRulerPicker> createState() => _WeightRulerPickerState();
}

class _WeightRulerPickerState extends State<WeightRulerPicker> {
  late ScrollController _scrollController;
  late int _selectedValue;
  late List<int> _values;

  @override
  void initState() {
    super.initState();
    _updateValues();
    
    // Başlangıç değerini ayarla
    final initialValue = widget.isKg
        ? widget.initialValue.round()
        : (widget.initialValue * 2.20462).round();
    _selectedValue = initialValue.clamp(_values.first, _values.last);
    
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Scroll pozisyonunu başlangıç değerine ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToValue(_selectedValue);
    });
  }

  void _updateValues() {
    if (widget.isKg) {
      // kg modunda 30-250 arası tam sayılar
      _values = List.generate(221, (index) => 30 + index);
    } else {
      // lbs modunda 66-551 arası tam sayılar (30kg=66lbs, 250kg=551lbs)
      _values = List.generate(486, (index) => 66 + index);
    }
  }

  @override
  void didUpdateWidget(WeightRulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isKg != widget.isKg) {
      _updateValues();
      // Birim değiştiğinde değeri dönüştür
      // widget.initialValue her zaman kg cinsinden
      final newValue = widget.isKg
          ? widget.initialValue.round() // kg moduna geçildi
          : (widget.initialValue * 2.20462).round(); // lbs moduna geçildi
      _selectedValue = newValue.clamp(_values.first, _values.last);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToValue(_selectedValue);
      });
    }
  }

  void _scrollToValue(int value) {
    final index = _values.indexOf(value);
    if (index != -1) {
      final itemWidth = 60.0; // Her öğenin genişliği
      final targetOffset = index * itemWidth - (MediaQuery.of(context).size.width / 2 - itemWidth / 2);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScroll() {
    final itemWidth = 60.0;
    final centerOffset = _scrollController.offset + (MediaQuery.of(context).size.width / 2);
    final index = (centerOffset / itemWidth).round();
    
    if (index >= 0 && index < _values.length) {
      final newValue = _values[index];
      if (newValue != _selectedValue) {
        setState(() {
          _selectedValue = newValue;
        });
        // kg'ye çevirerek callback'i çağır
        final valueInKg = widget.isKg ? newValue.toDouble() : newValue / 2.20462;
        widget.onValueChanged(valueInKg);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = 60.0;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // Ruler ListView
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: screenWidth / 2 - itemWidth / 2),
            itemCount: _values.length,
            itemBuilder: (context, index) {
              final value = _values[index];
              final isSelected = value == _selectedValue;
              
              return Container(
                width: itemWidth,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sayı
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: isSelected ? 32 : 18,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? AppColors.softPinkButton : Colors.grey[400],
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Çizgi
                    Container(
                      width: isSelected ? 3 : 1,
                      height: isSelected ? 40 : 20,
                      color: isSelected ? AppColors.softPinkButton : Colors.grey[300],
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Merkez çizgisi (seçim göstergesi)
          Positioned(
            left: screenWidth / 2 - 1,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: AppColors.softPinkButton,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.softPinkButton.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          
          // Seçilen değer gösterimi (üstte)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.softPinkButton.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.softPinkButton,
                    width: 2,
                  ),
                ),
                child: Text(
                  '${_selectedValue} ${widget.isKg ? 'kg' : 'lbs'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softPinkButton,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

