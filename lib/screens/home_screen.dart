import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import 'reservations_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../pages/chat_page.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    //const SearchScreen(),
    const ReservationsScreen(),
    const HistoryScreen(),
    const ChatPage(), //
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inici',
          ),
          /*const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Cercar zona',
          ),*/
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Reserves',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                  Colors.black54,
                  BlendMode.srcIn
              ),
              child: Image.asset('assets/images/logo_parkswap_IA_png.png', width: 24, height: 24),
            ),
            activeIcon: Image.asset('assets/images/logo_parkswap_IA_png.png', width: 24, height: 24),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}