import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dormitory_list_screen.dart';
import 'screens/apartment_list_screen.dart';
import 'screens/house_list_screen.dart';
import 'screens/listing_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'services/message_notification_service.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ThemeController.instance.loadTheme();
  await MessageNotificationService.instance.initialize(GlobalKey<NavigatorState>());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: MessageNotificationService.instance.navigatorKey,
          title: 'Roomie - Ev Arkadaşı Bul',
          themeMode: ThemeController.instance.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)),
            brightness: Brightness.light,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4CAF50),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const HomeScreen(),
            '/messages': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
              final String? openChatWith = args != null ? args['openChatWith'] as String? : null;
              final String? openChatWithName = args != null ? args['openChatWithName'] as String? : null;
              if (openChatWith != null && openChatWith.isNotEmpty) {
                return ChatScreen(otherUserId: openChatWith, otherUserName: openChatWithName ?? openChatWith);
              }
              return const MessagesScreen();
            },
            '/dormitory-list': (context) => const DormitoryListScreen(),
            '/apartment-list': (context) => const ApartmentListScreen(),
            '/house-list': (context) => const HouseListScreen(),
            '/listing-detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
              final listing = args != null ? args['listing'] as Map<String, dynamic>? : null;
              return ListingDetailScreen(listing: listing ?? const {});
            },
            '/profile': (context) => const ProfileScreen(),
            '/user-profile': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
              final userId = args?['userId'] as String? ?? '';
              return UserProfileScreen(userId: userId);
            },
            '/settings': (context) => const SettingsScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
          },
        );
      },
    );
  }
}

