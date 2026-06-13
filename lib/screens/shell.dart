import 'package:flutter/material.dart';

import '../theme.dart';
import 'birdpedia_screen.dart';
import 'flock_screen.dart';
import 'home_screen.dart';
import 'log_sighting_sheet.dart';
import 'map_screen.dart';

/// Root scaffold: four tabs plus a raised center "log a bird" action.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  // Overridable for demos/screenshots: flutter run --dart-define=BC_INITIAL_TAB=1
  int _index = const int.fromEnvironment('BC_INITIAL_TAB');

  // Tabs are built lazily on first visit (then kept alive by the
  // IndexedStack) so startup doesn't fire every screen's image loads at once.
  late final List<bool> _visited = [
    for (var i = 0; i < 4; i++) i == _index,
  ];

  static const _tabs = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
    (icon: Icons.map_outlined, active: Icons.map_rounded, label: 'Map'),
    (icon: Icons.menu_book_outlined, active: Icons.menu_book_rounded, label: 'Birdpedia'),
    (icon: Icons.groups_outlined, active: Icons.groups_rounded, label: 'Flock'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _visited[0] ? const HomeScreen() : const SizedBox.shrink(),
          _visited[1] ? const MapScreen() : const SizedBox.shrink(),
          _visited[2] ? const BirdpediaScreen() : const SizedBox.shrink(),
          _visited[3] ? const FlockScreen() : const SizedBox.shrink(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        button: true,
        label: 'Log a bird sighting',
        child: FloatingActionButton(
          onPressed: () {
            Haptic.tap();
            showLogSightingSheet(context);
          },
          backgroundColor: BcColors.cherry,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: BcColors.card,
        elevation: 0,
        height: 76,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            _navItem(0),
            _navItem(1),
            const SizedBox(width: 72), // notch space
            _navItem(2),
            _navItem(3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final tab = _tabs[i];
    final selected = _index == i;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '${tab.label} tab',
        child: InkResponse(
          onTap: () {
            if (_index != i) Haptic.tick();
            setState(() {
              _index = i;
              _visited[i] = true;
            });
          },
          radius: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                child: Icon(
                  selected ? tab.active : tab.icon,
                  key: ValueKey(selected),
                  color: selected ? BcColors.ink : BcColors.muted,
                  size: 26,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? BcColors.ink : BcColors.muted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
