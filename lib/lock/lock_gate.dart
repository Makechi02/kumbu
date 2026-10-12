import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../theme.dart';

/// Covers the whole app with a lock screen until the phone's biometric
/// (or screen lock) check passes. Locks again whenever the app goes to the background.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _locked = true;
  bool _authenticating = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_authenticating) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    // The system prompt itself can trigger lifecycle changes, so don't re-enter.
    if (_authenticating) return;
    _authenticating = true;

    var ok = false;
    var message = '';
    try {
      if (!await _auth.isDeviceSupported()) {
        ok = true; // Nothing to check against, so don't lock the user out.
      } else {
        ok = await _auth.authenticate(
          localizedReason: 'Unlock your journal',
          options: const AuthenticationOptions(stickyAuth: true),
        );
      }
    } on PlatformException {
      message = 'Set a screen lock on this phone, then try again.';
    } finally {
      _authenticating = false;
    }

    if (!mounted) return;
    setState(() {
      _locked = !ok;
      _message = ok ? '' : message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 40,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Kumbu', style: serif(context, 30)),
                    const SizedBox(height: 4),
                    Text('Locked', style: TextStyle(color: colors.muted)),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_message, style: TextStyle(color: colors.muted)),
                    ],
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _unlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}