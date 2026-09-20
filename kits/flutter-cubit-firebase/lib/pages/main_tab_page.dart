import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/profile_tab.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _selectedIndex = 0;

  static const List<_TabItem> _tabItems = [
    _TabItem(icon: Icons.home, label: '홈'),
    _TabItem(icon: Icons.search, label: '탐색'),
    _TabItem(icon: Icons.person, label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeTab(),
          SearchTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: _tabItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ))
          .toList(),
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

}

// 탭 아이템 클래스
class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.label,
  });
}