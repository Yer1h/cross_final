import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ДОБАВИЛИ импорт Firebase
import 'add_product_screen.dart';
import 'barcode_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'login_screen.dart';
import 'all_products_page.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final user = FirebaseAuth.instance.currentUser;
  bool get isGuest => user == null;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isGuest = user == null;

        List<Widget> _pages = [
        const DashboardPage(),
        isGuest ? GuestBlockPage(onBackToHome: () {
          setState(() {
            _selectedIndex = 0;
          });
        }) : const AddProductScreen(),
        isGuest ? GuestBlockPage(onBackToHome: () {
          setState(() {
            _selectedIndex = 0;
          });
        }) : const BarcodePage(),
        isGuest ? GuestBlockPage(onBackToHome: () {
          setState(() {
            _selectedIndex = 0;
          });
        }) : const HistoryPage(),
        isGuest ? GuestBlockPage(onBackToHome: () {
          setState(() {
            _selectedIndex = 0;
          });
        }) : SettingsPage(),
      ];


        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF111827),
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add item'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Barcode'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

}

class GuestBlockPage extends StatelessWidget {
  final VoidCallback? onBackToHome;

  const GuestBlockPage({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Restricted Access',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please log in to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: const Text('Login'),
          ),

          ],
        ),
      ),
    );
  }
}



class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  final List<String> recentItems = const ['Item Namy', 'Item Amy'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Welcome back",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text("Here’s a quick look at your inventory."),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
              QuickActionCard(
              icon: Icons.list,
              label: 'All Items',
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Restricted Access'),
                      content: const Text('Please log in to view all products.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                            );
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllProductsPage()),
                  );
                }
              },
            ),
                QuickActionCard(
                  icon: Icons.add,
                  label: 'Add New',
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      // Покажи диалог, что нужна регистрация
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Restricted Access'),
                          content: const Text('Please log in to add new items.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // Навигация на LoginScreen
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Пускаем в AddProductScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductScreen(),
                        ),
                      );
                    }
                  },
                ),
                const QuickActionCard(icon: Icons.add_shopping_cart, label: 'Low Stock'),
                const QuickActionCard(icon: Icons.qr_code_scanner, label: 'Scan Barcode'),

              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Recent Updates",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ...recentItems.map(
              (item) => ListTile(
                leading: const Icon(Icons.inventory),
                title: Text(item),
                subtitle: const Text("Just now"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F2937),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
