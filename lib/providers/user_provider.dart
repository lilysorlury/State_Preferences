import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;

  User get user => _user;
  bool get isLoading => _isLoading;

  // Memuat data user dari SharedPreferences
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    _user = User(name: name, email: email, isLoggedIn: isLoggedIn);

    _isLoading = false;
    notifyListeners();
  }

  // Menyimpan dan memperbarui data user
  Future<void> updateUser(User newUser) async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    _user = newUser;
    _isLoading = false;
    notifyListeners();
  }

  // Logout: menghapus nama dan mengubah status login
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    _user = _user.copyWith(name: '', isLoggedIn: false);

    notifyListeners();
  }
}

// Wrapper menggunakan ChangeNotifierProvider
class UserProviderWrapper extends StatelessWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserProvider>(
      create: (_) => UserProvider()..loadUser(),
      child: child,
    );
  }
}
