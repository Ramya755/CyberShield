import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/threat.dart';
import '../data/api/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  final bool isDark;
  final VoidCallback onThemeChanged;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const SmsScreen(),
      const LinksScreen(),
      const ReportScreen(),
      ProfileScreen(
        isDark: widget.isDark,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home_outlined, 'Home', 0),
            navItem(Icons.chat_bubble_outline, 'SMS', 1),
            navItem(Icons.link, 'Links', 2),
            navItem(Icons.info_outline, 'Report', 3),
            navItem(Icons.person_outline, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String title, int index) {
    final active = selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? Colors.blue : Colors.grey, size: 25),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: active ? Colors.blue : Colors.grey,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= HOME SCREEN =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Threat>> _threatsFuture;

  @override
  void initState() {
    super.initState();
    _threatsFuture = ApiService.getRecentThreats();
  }

  // This must return a Future for RefreshIndicator to work
  Future<void> _refreshThreats() async {
    setState(() {
      _threatsFuture = ApiService.getRecentThreats();
    });
    await _threatsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshThreats, // FIXED: Used onRefresh instead of onPressed
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hello,\nStay Safe Today!',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh threats',
                      onPressed: _refreshThreats, // Standard buttons use onPressed
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildScoreCard(cardColor),
                const SizedBox(height: 30),
                const Text(
                  'Recent Threats',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Threat>>(
                  future: _threatsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No threats detected."));
                    } else {
                      return Column(
                        children: snapshot.data!
                            .take(5)
                            .map((threat) => ThreatTileData(threat: threat))
                            .toList(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(Color cardColor) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('CyberShield Score', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 28),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 170,
                    width: 170,
                    child: CircularProgressIndicator(
                      value: 0.87,
                      strokeWidth: 18,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      color: Colors.green,
                    ),
                  ),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('87', style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
                      Text('out of 100', style: TextStyle(color: Colors.blue, fontSize: 15)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text('↗ +5 from last week', 
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _refreshThreats, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ================= PLACEHOLDER SCREENS =================
class SmsScreen extends StatelessWidget { const SmsScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('SMS Screen'))); }
class LinksScreen extends StatelessWidget { const LinksScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Links Screen'))); }
class ReportScreen extends StatelessWidget { const ReportScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Report Screen'))); }

// ================= PROFILE SCREEN =================
class ProfileScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notifications = true;

  Future<void> _editName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await user.updateDisplayName(newName);
        setState(() {}); // Force UI update
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true ? user!.displayName! : "No name set";
    final email = user?.email ?? "No email";

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      height: 75,
                      width: 75,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0066FF),
                            Color(0xFF00FF99),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                onPressed: _editName,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email,
                            style: TextStyle(
                              color: textColor?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "CyberShield Score: 87/100",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Protection Settings
            Text(
              "Protection Settings",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Colors.blue,
                    ),
                    title: Text(
                      "Notifications",
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: const Text("Get alerts for threats"),
                    trailing: Switch(
                      value: notifications,
                      onChanged: (v) {
                        setState(() {
                          notifications = v;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      widget.isDark ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.blue,
                    ),
                    title: Text(
                      widget.isDark ? "Dark Mode" : "Light Mode",
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: const Text("Toggle app theme"),
                    trailing: Switch(
                      value: widget.isDark,
                      onChanged: (v) {
                        widget.onThemeChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Security
            Text(
              "Security",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  securityTile(
                    Icons.lock,
                    "Change Password",
                    "Update your password",
                    const ChangePasswordScreen(),
                  ),
                  securityTile(
                    Icons.privacy_tip,
                    "Privacy Policy",
                    "Read our privacy policy",
                    const PrivacyPolicyScreen(),
                  ),
                  securityTile(
                    Icons.info,
                    "About",
                    "Version 1.0.0",
                    const AboutScreen(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget securityTile(
    IconData icon,
    String title,
    String subtitle,
    Widget screen,
  ) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => screen,
          ),
        );
      },
    );
  }
}

// Placeholder classes
class ChangePasswordScreen extends StatelessWidget { const ChangePasswordScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Change Password")), body: const Center(child: Text("Change Password screen under construction"))); }
class PrivacyPolicyScreen extends StatelessWidget { const PrivacyPolicyScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Privacy Policy")), body: const Center(child: Text("Privacy Policy screen under construction"))); }
class AboutScreen extends StatelessWidget { const AboutScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("About")), body: const Center(child: Text("About screen under construction"))); }

// ================= THREAT TILES =================
class ThreatTileData extends StatelessWidget {
  final Threat threat;
  const ThreatTileData({super.key, required this.threat});
  @override
  Widget build(BuildContext context) {
    final color = threat.riskScore > 70 ? Colors.red : Colors.orange;
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.warning, color: color)),
      title: Text(threat.url),
      subtitle: Text("Risk Score: ${threat.riskScore}%"),
    );
  }
}