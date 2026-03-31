import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wallet_pulse/features/splits/presentation/splits_screen.dart';
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

  final List<Widget> _screens = [const HomeScreen(), const SplitsScreen()];

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

class AnimatedGradientFab extends StatefulWidget {
  const AnimatedGradientFab({super.key});

  @override
  State<AnimatedGradientFab> createState() => _AnimatedGradientFabState();
}

class _AnimatedGradientFabState extends State<AnimatedGradientFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  OverlayEntry? _overlayEntry;
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeOutBack,
      parent: _controller,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isDismissed) {
      _showOverlay();
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _showOverlay() {
    final renderBox = _fabKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final fabSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggle,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.black.withOpacity(0.7 * _controller.value),
                    ),
                  ),
                );
              },
            ),

            // Left Popup Button (Manual Entry)
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                final dx = -65.0 * _expandAnimation.value;
                final dy = -70.0 * _expandAnimation.value;
                return Positioned(
                  left: offset.dx + (fabSize.width / 2) - 20 + dx,
                  top: offset.dy + (fabSize.height / 2) - 20 + dy,
                  child: Transform.scale(
                    scale: _expandAnimation.value,
                    child: FloatingActionButton.small(
                      heroTag: 'manual',
                      backgroundColor: const Color(0xFFF8BBD0),
                      elevation: 4,
                      onPressed: () {
                        _toggle(); // Close menu
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManualEntryScreen(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.edit_document,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Right Popup Button (Camera Scan)
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                final dx = 65.0 * _expandAnimation.value;
                final dy = -70.0 * _expandAnimation.value;
                return Positioned(
                  left: offset.dx + (fabSize.width / 2) - 20 + dx,
                  top: offset.dy + (fabSize.height / 2) - 20 + dy,
                  child: Transform.scale(
                    scale: _expandAnimation.value,
                    child: FloatingActionButton.small(
                      heroTag: 'scan',
                      backgroundColor: const Color(0xFFE1BEE7),
                      elevation: 4,
                      onPressed: () {
                        _toggle();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraScreen(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: GestureDetector(
                onTap: _toggle,
                child: Container(
                  height: fabSize.height,
                  width: fabSize.width,
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
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -math.pi / 4 * _controller.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 1.0 - _controller.value,
                              child: const Icon(
                                Icons.document_scanner_outlined,
                                size: 28,
                                color: Colors.black87,
                              ),
                            ),
                            Opacity(
                              opacity: _controller.value,
                              child: const Icon(
                                Icons.close,
                                size: 28,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _fabKey,
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
          BoxShadow(color: Color(0xFFF8BBD0), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _toggle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.document_scanner_outlined,
          size: 28,
          color: Colors.black87,
        ),
      ),
    );
  }
}
