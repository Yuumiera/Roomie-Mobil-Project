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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roomie - Ev Arkadaşı Bul',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
        // Detail route expects arguments: { listing: Map<String, dynamic> }
        '/listing-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final listing = args != null ? args['listing'] as Map<String, dynamic>? : null;
          return ListingDetailScreen(listing: listing ?? const {});
        },
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

