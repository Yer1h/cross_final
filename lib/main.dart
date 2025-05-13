import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:invent_app_redesign/providers/theme_provider.dart';
import 'package:invent_app_redesign/providers/locale_provider.dart';
import 'package:invent_app_redesign/screens/home_screen.dart';
import 'package:invent_app_redesign/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class DefaultFirebaseOptions {
  static var currentPlatform;
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Inventory App',
            theme: themeProvider.currentTheme,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ru'),
              Locale('kk'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) {
                  return HomeScreen();
                }
                return LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
