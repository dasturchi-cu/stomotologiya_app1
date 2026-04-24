import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stomotologiya_app/screens/auth/login_screen_new.dart';
import 'package:stomotologiya_app/screens/home.dart';
import 'dart:async';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _auth = Supabase.instance.client.auth;
  bool _isLoading = true;
  bool _isBanned = false;
  String _banMessage = '';
  RealtimeChannel? _profileChannel;
  Timer? _banPollTimer;

  @override
  void initState() {
    super.initState();
    _auth.onAuthStateChange.listen((data) {
      _evaluateUserStatus(data.session?.user);
    });
    _evaluateUserStatus(_auth.currentUser);
  }

  Future<void> _evaluateUserStatus(User? user) async {
    try {
      if (user == null) {
        _stopBanWatch();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isBanned = false;
          _banMessage = '';
        });
        return;
      }

      _startBanWatch(user.id);

      final userJson = user.toJson();
      final appMetadata = (userJson['app_metadata'] as Map?) ?? const {};
      final userMetadata = (userJson['user_metadata'] as Map?) ?? const {};
      final bannedUntilRaw = userJson['banned_until']?.toString();

      bool isBannedByAuth = false;
      if (appMetadata['banned'] == true || userMetadata['banned'] == true) {
        isBannedByAuth = true;
      }
      if (appMetadata['disabled'] == true || userMetadata['disabled'] == true) {
        isBannedByAuth = true;
      }
      if (bannedUntilRaw != null && bannedUntilRaw.isNotEmpty) {
        final bannedUntil = DateTime.tryParse(bannedUntilRaw);
        if (bannedUntil != null && bannedUntil.isAfter(DateTime.now().toUtc())) {
          isBannedByAuth = true;
        }
      }

      bool isDisabledInProfiles = false;
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('disabled')
            .eq('id', user.id)
            .maybeSingle();
        isDisabledInProfiles = row != null && row['disabled'] == true;
      } catch (_) {
        // profiles jadvali bo'lmasa ham Auth metadata ban ishlashi kerak.
      }

      final isDisabled = isBannedByAuth || isDisabledInProfiles;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isBanned = isDisabled;
        _banMessage = isDisabled
            ? 'Siz ban oldingiz. Bandan chiqish uchun 903009848 raqamiga bog\'laning.'
            : '';
      });
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startBanWatch(String userId) {
    // Avoid duplicate subscriptions/timers
    _stopBanWatch();

    // Realtime watch: if admin sets profiles.disabled=true, show ban immediately.
    _profileChannel = Supabase.instance.client.channel('profiles-ban-$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) async {
          final newRow = payload.newRecord;
          final disabled = newRow['disabled'] == true;
          if (!mounted) return;
          if (disabled) {
            setState(() {
              _isBanned = true;
              _banMessage =
                  'Siz ban oldingiz. Bandan chiqish uchun 903009848 raqamiga bog\'laning.';
            });
          }
        },
      )
      ..subscribe();

    // Fallback poll (in case realtime is not enabled for the table/project)
    _banPollTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('disabled')
            .eq('id', userId)
            .maybeSingle();
        final disabled = row != null && row['disabled'] == true;
        if (!mounted) return;
        if (disabled && !_isBanned) {
          setState(() {
            _isBanned = true;
            _banMessage =
                'Siz ban oldingiz. Bandan chiqish uchun 903009848 raqamiga bog\'laning.';
          });
        }
      } catch (_) {
        // ignore
      }
    });
  }

  void _stopBanWatch() {
    _banPollTimer?.cancel();
    _banPollTimer = null;
    if (_profileChannel != null) {
      Supabase.instance.client.removeChannel(_profileChannel!);
      _profileChannel = null;
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    setState(() {
      _isBanned = false;
      _banMessage = '';
    });
  }

  @override
  void dispose() {
    _stopBanWatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isBanned) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Hisob bloklangan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _banMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _logout,
                  child: const Text('Chiqish'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_auth.currentSession != null) {
      return const HomeScreen();
    }

    return const LoginScreenNew();
  }
}
