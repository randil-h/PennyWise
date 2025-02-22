import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:local_auth/local_auth.dart';

import 'theme_notifier.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'profile.dart';
import 'onboardingScreen1.dart';
import 'login.dart';
import 'home_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('login');
  await Hive.openBox('accounts');
  await Hive.openBox('imagePaths');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: FinanceTrackerApp(),
    ),
  );
}

class FinanceTrackerApp extends StatefulWidget {
  @override
  _FinanceTrackerAppState createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          title: 'PennyWise',
          theme: ThemeData(
            primarySwatch: Colors.red,
            brightness: themeNotifier.isDarkTheme
                ? Brightness.dark
                : Brightness.light,
          ),
          home: FutureBuilder<bool>(
            future: _checkFirstTimeUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return snapshot.data == true ? OnboardingScreen() : AuthCheckScreen();
              }
            },
          ),
          routes: {
            '/login': (context) => Login(),
            '/home': (context) => HomeWrapper(),
          },
        );
      },
    );
  }

  Future<bool> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;
    return isFirstTimeUser;
  }
}

class AuthCheckScreen extends StatefulWidget {
  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final Box _boxLogin = Hive.box("login");

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    bool isAuthenticated = await _authenticate();
    if (isAuthenticated) {
      String? userId = _boxLogin.get("userId");
      if (userId != null) {
        _navigateToHome(userId);
      } else {
        _navigateToLogin();
      }
    } else {
      _navigateToLogin();
    }
  }

  Future<bool> _authenticate() async {
    try {
      bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }
      bool isAuthenticated = await _localAuthentication.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  void _navigateToHome(String userId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomePage(userId: userId)),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String username = "Username";
  String email = "email@example.com";

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      HomeScreen(userId: widget.userId),
      StatisticsScreen(userId: widget.userId),
      Profile(userId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      
    );
  }
}