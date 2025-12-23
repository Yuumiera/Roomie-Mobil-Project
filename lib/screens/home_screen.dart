import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _onCategorySelected(String category) {
    switch (category) {
      case 'Dormitory':
        Navigator.pushNamed(context, '/dormitory-list');
        break;
      case 'Apartment':
        Navigator.pushNamed(context, '/apartment-list');
        break;
      case 'House':
        Navigator.pushNamed(context, '/house-list');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3), // Same as login background
      appBar: AppBar(
        title: const Text(
          'Home Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF4CAF50),
            height: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Welcome text
              Text(
                'Choose Your Accommodation Type',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B4513),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Find the perfect place to call home',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFFCD853F),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Category Cards
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dormitory Card
                    _buildCategoryCard(
                      title: 'Dormitory',
                      icon: Icons.bed,
                      color: const Color(0xFF4CAF50), // Green from login
                      onTap: () => _onCategorySelected('Dormitory'),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Apartment Card
                    _buildCategoryCard(
                      title: 'Apartment',
                      icon: Icons.apartment,
                      color: const Color(0xFF8B4513), // Brown from login
                      onTap: () => _onCategorySelected('Apartment'),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // House Card
                    _buildCategoryCard(
                      title: 'House',
                      icon: Icons.home,
                      color: const Color(0xFFD4AF37), // Gold from login
                      onTap: () => _onCategorySelected('House'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1), // Home is index 1
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B4513),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find your perfect ${title.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFCD853F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
