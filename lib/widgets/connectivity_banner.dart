import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showRestoredMessage = false;
  Timer? _restoredTimer;
  bool _initialCheckDone = false;

  // Animación de pulso sutil para el indicador
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkInitialConnectivity();
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleResults(results, isInitial: true);
    } catch (e) {
      debugPrint("Error checking connectivity: $e");
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _handleResults(results, isInitial: false);
  }

  void _handleResults(List<ConnectivityResult> results,
      {required bool isInitial}) {
    final bool offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (!mounted) return;

    if (offline) {
      _restoredTimer?.cancel();
      setState(() {
        _isOffline = true;
        _showRestoredMessage = false;
        _initialCheckDone = true;
      });
    } else {
      if (_isOffline && !isInitial && _initialCheckDone) {
        setState(() {
          _isOffline = false;
          _showRestoredMessage = true;
        });
        _restoredTimer?.cancel();
        _restoredTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showRestoredMessage = false;
            });
          }
        });
      } else {
        setState(() {
          _isOffline = false;
          _showRestoredMessage = false;
          _initialCheckDone = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _restoredTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showChip = _isOffline || _showRestoredMessage;
    final Color statusColor =
        _isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981); // Ámbar / Esmeralda
    final IconData statusIcon =
        _isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded;
    final String statusText = _isOffline ? 'Sin conexión' : 'En línea';

    return Stack(
      children: [
        widget.child,

        // Píldora flotante minimalista y elegante en la esquina superior derecha
        Positioned(
          top: 8,
          right: 16,
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.6),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: showChip
                  ? Material(
                      key: ValueKey<bool>(_isOffline),
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xEE0F172A), // Slate 900 translúcido estilo dark glass
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Punto de estado con micro-pulsación
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isOffline ? _pulseAnimation.value : 1.0,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withValues(alpha: 0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 7),
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('hidden')),
            ),
          ),
        ),
      ],
    );
  }
}
