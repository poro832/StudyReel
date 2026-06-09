import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../explore/explore_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';

/// 하단 내비게이션 셸. 피드·탐색·프로필을 탭으로 전환한다.
/// IndexedStack으로 각 탭의 상태를 유지하고, 보이지 않는 피드는
/// VisibilityDetector가 재생을 멈춘다(배경 재생음 방지).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          // 피드는 선택된 탭일 때만 재생(배경 재생음 방지).
          FeedScreen(active: _index == 0),
          const ExploreScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.col.surface,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: context.col.textGray,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle_fill),
            label: '피드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '탐색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
