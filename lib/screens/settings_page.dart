import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invent_app_redesign/providers/theme_provider.dart';
import 'package:invent_app_redesign/providers/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invent_app_redesign/services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? _buildUnauthenticatedUI(context)
            : ListView(
          children: [
            _buildUserInfo(user),
            const SizedBox(height: 24),
            _buildSectionTitle('Preferences'),
            _buildThemeSelector(themeProvider, context),
            _buildLanguageSelector(localeProvider, context),
            const SizedBox(height: 24),
            _buildSectionTitle('Account'),
            _buildAccountSettings(context, user),
            const SizedBox(height: 32),
            _buildLogoutButton(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'Authentication Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Please sign in to access all settings and personalize your experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(User user) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logged in as',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              user.email ?? 'No email found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider, BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: themeProvider.themeName,
            items: const [
              DropdownMenuItem(value: 'light', child: Text('Light Theme')),
              DropdownMenuItem(value: 'dark', child: Text('Dark Theme')),
            ],
            onChanged: (value) => themeProvider.setTheme(value!),
            hint: const Text('Select Theme'),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(LocaleProvider localeProvider, BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: localeProvider.locale.languageCode,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ru', child: Text('Русский')),
              DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
            ],
            onChanged: (value) => localeProvider.setLanguage(value!),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, User user) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lock_reset),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          shape: _listTileBorder(context),
          onTap: () async {
            final email = user.email;
            if (email != null) {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset instructions sent to your email')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            }
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          trailing: const Icon(Icons.chevron_right, color: Colors.red),
          shape: _listTileBorder(context),
          onTap: () => _confirmAccountDeletion(context),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, ColorScheme colorScheme) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async => await _authService.signOut(),
    );
  }

  RoundedRectangleBorder _listTileBorder(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Theme.of(context).dividerColor),
    );
  }

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is permanent and will remove all your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account successfully deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}