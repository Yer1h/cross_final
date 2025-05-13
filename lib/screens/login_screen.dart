import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';  // Не забудь импортировать свой HomeScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignIn = true;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      showMsg("Please enter both email and password.");
      return;
    }
    if (password.length < 6) {
      showMsg("Password must be at least 6 characters.");
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      showMsg("Sign up successful! You can now sign in.");
      setState(() {
        isSignIn = true;
        emailController.clear();
        passwordController.clear();
      });
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'This email is already in use.';
          break;
        case 'invalid-email':
          errorMsg = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMsg = 'The password is too weak.';
          break;
        default:
          errorMsg = 'Sign up error: ${e.message}';
      }
      showMsg(errorMsg);
    } catch (e) {
      showMsg("Unexpected error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      showMsg("Please enter both email and password.");
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Firebase will auto-redirect via authStateChanges
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMsg = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMsg = 'The email address is not valid.';
          break;
        default:
          errorMsg = 'Sign in failed: ${e.message}';
      }
      showMsg(errorMsg);
    } catch (e) {
      showMsg("Unexpected error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.qr_code_2, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              "INVENT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => setState(() => isSignIn = true),
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            fontWeight: isSignIn ? FontWeight.bold : FontWeight.normal,
                            color: isSignIn ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () => setState(() => isSignIn = false),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontWeight: !isSignIn ? FontWeight.bold : FontWeight.normal,
                            color: !isSignIn ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !isLoading,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();
                            isSignIn
                                ? signIn(email, password)
                                : signUp(email, password);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111827),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isSignIn ? "Sign In" : "Sign Up",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                  const SizedBox(height: 16),
                  // Добавили кнопку для гостя 👇
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Continue as guest',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
