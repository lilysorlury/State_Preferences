import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _favoriteController = TextEditingController();

  bool _controllersInitialized = false;
  bool _favoritesLoaded = false;
  List<String> _favorites = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_controllersInitialized) return;

    final provider = Provider.of<UserProvider>(context, listen: false);

    _nameController = TextEditingController(text: provider.user.name);
    _emailController = TextEditingController(text: provider.user.email);
    _controllersInitialized = true;

    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    if (!mounted) return;

    setState(() {
      _favorites = favorites;
      _favoritesLoaded = true;
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
  }

  Future<void> _addFavorite() async {
    final favorite = _favoriteController.text.trim();

    if (favorite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorit tidak boleh kosong')),
      );
      return;
    }

    if (_favorites.any(
      (item) => item.toLowerCase() == favorite.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Favorit sudah ada')));
      return;
    }

    setState(() {
      _favorites.add(favorite);
      _favoriteController.clear();
    });

    await _saveFavorites();
  }

  Future<void> _removeFavorite(int index) async {
    setState(() {
      _favorites.removeAt(index);
    });

    await _saveFavorites();
  }

  @override
  void dispose() {
    if (_controllersInitialized) {
      _nameController.dispose();
      _emailController.dispose();
    }

    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Validasi input kosong
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan email wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi karakter berbahaya pada nama
    final dangerousPattern = RegExp(
      r'<\s*/?\s*script\b[^>]*>',
      caseSensitive: false,
    );

    if (dangerousPattern.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh mengandung tag script!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ambil data provider dan SharedPreferences
    final provider = Provider.of<UserProvider>(context, listen: false);

    final prefs = await SharedPreferences.getInstance();

    // SIMULASI: email yang sudah digunakan akun lain
    await prefs.setString('used_email', 'duplikat@example.com');

    final usedEmail = prefs.getString('used_email');

    // Cek apakah email digunakan akun lain
    if (usedEmail != null &&
        usedEmail.isNotEmpty &&
        usedEmail.toLowerCase() == email.toLowerCase() &&
        email.toLowerCase() != provider.user.email.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email sudah digunakan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (usedEmail != null &&
        usedEmail.isNotEmpty &&
        usedEmail.toLowerCase() == email.toLowerCase() &&
        email.toLowerCase() != provider.user.email.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email sudah digunakan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simpan profil jika validasi berhasil
    final updatedUser = provider.user.copyWith(
      name: name,
      email: email,
      isLoggedIn: true,
    );

    await provider.updateUser(updatedUser);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil diperbarui!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await Provider.of<UserProvider>(context, listen: false).logout();

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);

    if (!_controllersInitialized && !provider.isLoading) {
      _nameController = TextEditingController(text: provider.user.name);
      _emailController = TextEditingController(text: provider.user.email);
      _controllersInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }

                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Daftar Favorit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _favoriteController,
                        decoration: const InputDecoration(
                          labelText: 'Tambah hobi atau favorit',
                          hintText: 'Contoh: Membaca',
                          prefixIcon: Icon(Icons.favorite),
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _addFavorite(),
                      ),
                      const SizedBox(height: 8),

                      ElevatedButton.icon(
                        onPressed: _addFavorite,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Favorit'),
                      ),
                      const SizedBox(height: 12),

                      if (!_favoritesLoaded)
                        const Center(child: CircularProgressIndicator())
                      else if (_favorites.isEmpty)
                        const Text('Belum ada favorit.')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _favorites.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                ),
                                title: Text(_favorites[index]),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Hapus favorit',
                                  onPressed: () => _removeFavorite(index),
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 24),

                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Keamanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data disimpan di SharedPreferences '
                                '(plaintext). Jangan simpan password atau '
                                'data sensitif di sini. Gunakan secure '
                                'storage untuk data sensitif.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
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
}
