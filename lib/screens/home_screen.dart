import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0 = Home, 1 = Profile

  // Future for user data (only load when needed)
  Future<Map<String, dynamic>?>? _userFuture;

  void _loadUserData() {
    setState(() {
      _userFuture = AuthService.me();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "Home" : "My Profile"),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadUserData,
              tooltip: 'Refresh Profile',
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await TokenService.clear();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 1: Home / Dashboard - Simple welcome screen (buttons hata diye)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_rounded,
                  size: 120,
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 24),
                Text(
                  "Welcome to Dashboard",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Your account is ready",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Profile Details (loads only when Profile tab is selected)
          FutureBuilder<Map<String, dynamic>?>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (_userFuture == null) {
                return const Center(
                  child: Text("Select Profile tab to view your details"),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text("Error: ${snapshot.error.toString()}"),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Try Again"),
                        onPressed: _loadUserData,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text("No profile data available"));
              }

              final user = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (user['full_name'] as String? ?? "?")
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                                    .take(2)
                                    .join(),
                                style: TextStyle(
                                  fontSize: 48,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              user['full_name'] ?? 'User',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user['email'] ?? 'No email',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Details
                    _buildDetailTile(Icons.person, "Full Name", user['full_name'] ?? "N/A"),
                    _buildDetailTile(Icons.email, "Email", user['email'] ?? "N/A"),
                    _buildDetailTile(Icons.phone, "Phone", user['phone'] ?? "N/A"),
                    if (user['created_at'] != null)
                      _buildDetailTile(
                        Icons.calendar_today,
                        "Joined On",
                        user['created_at'].toString().split('T')[0],
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1 && _userFuture == null) {
            _loadUserData();
          }
        },
        selectedItemColor: Colors.blue.shade700,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }
}