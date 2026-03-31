import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../../scanner/presentation/camera_screen.dart';
import '../../scanner/presentation/manual_entry_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(
      child: Text(
        'Splits Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBody: true,
      body: _screens[_currentIndex],

      floatingActionButton: const AnimatedGradientFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomAppBar(
            color: Colors.white.withOpacity(0.05),
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            notchMargin: 10.0,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.grid_view_rounded, 0, "Dashboard"),
                  const SizedBox(width: 40),
                  _buildNavItem(Icons.call_split_rounded, 1, "Splits"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white38,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// --- The Custom Animated Gradient FAB ---
class AnimatedGradientFab extends StatefulWidget {
  const AnimatedGradientFab({super.key});

  @override
  State<AnimatedGradientFab> createState() => _AnimatedGradientFabState();
}

class _AnimatedGradientFabState extends State<AnimatedGradientFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeOutBack, // Bouncy pop-out effect
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Left Popup Button (Manual Entry)
          _buildExpandingAction(
            isLeft: true,
            icon: Icons.edit_document,
            color: const Color(0xFFF8BBD0),
            onPressed: () {
              _toggle();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
              );
            },
          ),

          // Right Popup Button (Camera Scan)
          _buildExpandingAction(
            isLeft: false,
            icon: Icons.camera_alt,
            color: const Color(0xFFE1BEE7),
            onPressed: () {
              _toggle();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
            },
          ),

          // Main Center FAB
          Container(
            height: 65,
            width: 65,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFE0F7FA), Color(0xFFF8BBD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFF8BBD0),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: child.key == const ValueKey('close')
                      ? Tween<double>(
                          begin: -0.125,
                          end: 0.0,
                        ).animate(animation)
                      : Tween<double>(
                          begin: 0.125,
                          end: 0.0,
                        ).animate(animation),
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _isOpen
                    ? const Icon(
                        Icons.close,
                        key: ValueKey('close'),
                        size: 28,
                        color: Colors.black87,
                      )
                    : const Icon(
                        Icons.add,
                        key: ValueKey('scan'),
                        size: 28,
                        color: Colors.black87,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandingAction({
    required bool isLeft,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        const distanceX = 65.0;
        const distanceY = 70.0;

        final dx = distanceX * _expandAnimation.value * (isLeft ? -1 : 1);
        final dy = -distanceY * _expandAnimation.value;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: _expandAnimation.value,
            child: FloatingActionButton.small(
              heroTag: icon.toString(),
              onPressed: onPressed,
              backgroundColor: color,
              elevation: 4,
              child: Icon(icon, color: Colors.black87),
            ),
          ),
        );
      },
    );
  }
}
