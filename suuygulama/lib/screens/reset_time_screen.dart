import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class ResetTimeScreen extends StatefulWidget {
  const ResetTimeScreen({super.key});

  @override
  State<ResetTimeScreen> createState() => _ResetTimeScreenState();
}

class _ResetTimeScreenState extends State<ResetTimeScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 0, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadResetTime();
  }

  Future<void> _loadResetTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reset_time_hour') ?? 0;
    final minute = prefs.getInt('reset_time_minute') ?? 0;
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveResetTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reset_time_hour', _selectedTime.hour);
    await prefs.setInt('reset_time_minute', _selectedTime.minute);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.softPinkButton,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      await _saveResetTime();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gün sıfırlama saati ${_selectedTime.format(context)} olarak ayarlandı',
          ),
          backgroundColor: AppColors.softPinkButton,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      appBar: AppBar(
        title: const Text(
          'Gün Sıfırlama Saati',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Uygulama verileri belirlediğiniz saatte sıfırlanır',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4A5568),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softPinkButton.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.softPinkButton,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.softPinkButton,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.softPinkButton,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Saat seçmek için yukarıdaki alana dokunun',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

