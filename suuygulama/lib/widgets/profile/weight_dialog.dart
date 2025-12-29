import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_text_styles.dart';

/// Dialog for selecting weight with unit toggle.
class WeightDialog extends StatefulWidget {
  final UserProvider userProvider;
  final Function(String) onSuccess;

  const WeightDialog({
    super.key,
    required this.userProvider,
    required this.onSuccess,
  });

  /// Shows the weight selection dialog
  static Future<void> show(
    BuildContext context,
    UserProvider userProvider,
    Function(String) onSuccess,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => WeightDialog(
        userProvider: userProvider,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<WeightDialog> {
  late bool _isKg;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _isKg = widget.userProvider.isMetric;
    final currentWeightKg = widget.userProvider.userData.weight ?? 0.0;
    _textController = TextEditingController();
    
    if (currentWeightKg > 0) {
      _textController.text = _isKg
          ? currentWeightKg.toStringAsFixed(1)
          : (currentWeightKg * 2.20462).toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateUnit(bool newIsKg) {
    if (!mounted) return;
    setState(() {
      if (_textController.text.isNotEmpty) {
        final currentValue = double.tryParse(_textController.text) ?? 0.0;
        final valueInKg = _isKg ? currentValue : currentValue / 2.20462;
        final newValue = newIsKg ? valueInKg : valueInKg * 2.20462;
        _textController.text = newValue.toStringAsFixed(1);
      }
      _isKg = newIsKg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          title: Text(
            'Kilo Seçiniz',
            style: AppTextStyles.heading2.copyWith(
              fontSize: AppConstants.extraLargeFontSize,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: AppConstants.largePadding),
                  
                  // Modern Pill Toggle (Birim Seçici)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppConstants.circularBorderRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _updateUnit(true));
                          },
                          child: AnimatedContainer(
                            duration: AppConstants.defaultAnimationDuration,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.largePadding,
                              vertical: AppConstants.defaultSpacing,
                            ),
                            decoration: BoxDecoration(
                              color: _isKg ? AppColors.softPinkButton : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'kg',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: _isKg ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _updateUnit(false));
                          },
                          child: AnimatedContainer(
                            duration: AppConstants.defaultAnimationDuration,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.largePadding,
                              vertical: AppConstants.defaultSpacing,
                            ),
                            decoration: BoxDecoration(
                              color: !_isKg ? AppColors.softPinkButton : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              'lbs',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: !_isKg ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: AppConstants.extraLargePadding),
                  
                  // Büyük TextField
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _textController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A5568),
                        ),
                        decoration: InputDecoration(
                          hintText: '0.0',
                          hintStyle: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            borderSide: BorderSide(
                              color: AppColors.softPinkButton,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            borderSide: BorderSide(
                              color: AppColors.softPinkButton,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            borderSide: BorderSide(
                              color: AppColors.softPinkButton,
                              width: 3,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.extraLargeSpacing,
                            vertical: AppConstants.largePadding,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppConstants.largePadding),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: AppTextStyles.buttonText),
            ),
            ElevatedButton(
              onPressed: () async {
                final textValue = _textController.text.trim();
                if (textValue.isNotEmpty) {
                  final enteredValue = double.tryParse(textValue) ?? 0.0;
                  if (enteredValue > 0) {
                    final weightInKg = _isKg ? enteredValue : enteredValue / 2.20462;
                    await widget.userProvider.updateProfile(weight: weightInKg);
                    await widget.userProvider.setIsMetric(_isKg);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    widget.onSuccess('Kilonuz başarıyla kaydedildi!');
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softPinkButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.mediumBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.extraLargePadding,
                  vertical: AppConstants.defaultSpacing,
                ),
              ),
              child: Text(
                'Tamam',
                style: AppTextStyles.buttonText,
              ),
            ),
          ],
        );
      },
    );
  }
}

