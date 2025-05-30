import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invent_app_redesign/screens/home_screen.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({Key? key}) : super(key: key);

  @override
  _PinLoginScreenState createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _pinController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isPinSet = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _checkIfPinIsSet();
  }

  Future<void> _checkIfPinIsSet() async {
    String? storedPin = await _storage.read(key: 'user_pin');
    setState(() {
      _isPinSet = storedPin != null;
    });
  }

  Future<void> _setPin(String pin) async {
    await _storage.write(key: 'user_pin', value: pin);
    setState(() {
      _isPinSet = true;
      _errorMessage = 'PIN set successfully!';
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<bool> _verifyPin(String pin) async {
    String? storedPin = await _storage.read(key: 'user_pin');
    return storedPin == pin;
  }

  void _onPinSubmitted(String pin) async {
    if (_isPinSet) {
      bool isValid = await _verifyPin(pin);
      if (isValid) {
        setState(() {
          _errorMessage = null;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN';
        });
      }
    } else {
      await _setPin(pin);
      _pinController.clear();
    }
  }

  Future<void> _resetPin() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (isGuest || user == null) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset PIN'),
          content: const Text('As a guest, resetting the PIN will clear it without verification. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _storage.delete(key: 'user_pin');
        setState(() {
          _isPinSet = false;
          _errorMessage = 'PIN reset. Please set a new PIN.';
          _pinController.clear();
        });
      }
    } else {
      setState(() {
        _isResetting = true;
      });
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email and password to verify your identity.'),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final credential = EmailAuthProvider.credential(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(credential);
                  await _storage.delete(key: 'user_pin');
                  setState(() {
                    _isPinSet = false;
                    _errorMessage = 'PIN reset. Please set a new PIN.';
                    _pinController.clear();
                  });
                  Navigator.pop(context);
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Authentication failed. Please try again.';
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      );
      setState(() {
        _isResetting = false;
        _emailController.clear();
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isPinSet ? 'Enter PIN' : 'Set PIN',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  _isPinSet ? 'Enter your 4-digit PIN' : 'Create a 4-digit PIN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                PinCodeTextField(
                  appContext: context,
                  length: 4,
                  controller: _pinController,
                  onCompleted: _onPinSubmitted,
                  obscureText: true,
                  obscuringCharacter: '*',
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 60,
                    fieldWidth: 50,
                    activeColor: Colors.blue,
                    selectedColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                  animationType: AnimationType.fade,
                  animationDuration: const Duration(milliseconds: 200),
                  keyboardType: TextInputType.number,
                  enableActiveFill: false,
                  enabled: !_isResetting,
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: _errorMessage!.contains('success')
                            ? Colors.green
                            : Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isPinSet)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: TextButton(
                      onPressed: _isResetting ? null : _resetPin,
                      child: const Text(
                        'Forgot PIN?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}