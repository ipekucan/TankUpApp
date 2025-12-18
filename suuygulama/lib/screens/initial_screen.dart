import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'name_input_screen.dart';
import 'main_navigation_screen.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // İsim kontrolü - eğer isim yoksa NameInputScreen'e yönlendir
        if (!userProvider.hasName) {
          return const NameInputScreen();
        }
        // İsim varsa MainNavigationScreen'e geç
        return const MainNavigationScreen();
      },
    );
  }
}

