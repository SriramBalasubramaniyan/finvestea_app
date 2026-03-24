import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'firebase_options.dart';

// Notifies the GoRouter whenever Firebase auth state changes so the
// router's redirect function re-runs without recreating the whole router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase (handles file storage + portfolios metadata table)
  await Supabase.initialize(
    url: 'https://byymyctsomukxojxpwdt.supabase.co',
    anonKey:
        'sb_publishable_0AGlYFvtj7mzrbCJtDApEQ_dGtwdEyu',
  );

  runApp(const FinvesteaApp());
}

class FinvesteaApp extends StatefulWidget {
  const FinvesteaApp({super.key});

  @override
  State<FinvesteaApp> createState() => _FinvesteaAppState();
}

class _FinvesteaAppState extends State<FinvesteaApp> {
  late final _AuthNotifier _authNotifier;
  late final GoRouter appRouter;

  @override
  void initState() {
    super.initState();
    _authNotifier = _AuthNotifier();
    appRouter = createRouter(_authNotifier);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finvestea',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
