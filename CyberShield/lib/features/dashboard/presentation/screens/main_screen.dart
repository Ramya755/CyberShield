import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  int cyberShieldScore = 100;

  void updateCyberShieldScore(int score) {
    setState(() {
      cyberShieldScore = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onScoreCalculated: updateCyberShieldScore),
      const SmsScreen(),
      const LinksScreen(),
      const ReportScreen(),
      ProfileScreen(
        isDark: widget.isDark,
        onThemeChanged: widget.onThemeChanged,
        cyberShieldScore: cyberShieldScore,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
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
  const HomeScreen({super.key, required this.onScoreCalculated});

  final ValueChanged<int> onScoreCalculated;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _linkThreats = [];

  @override
  void initState() {
    super.initState();
    _calculateAndNotifyScore();
  }

  void _calculateAndNotifyScore() {
    final score = _calculateDynamicScore();
    widget.onScoreCalculated(score);
  }

  /// Calculate CyberShield Score from SMS and Link detection data
  int _calculateDynamicScore() {
    try {
      // Get SMS detection stats (if provider is available)
      int totalScanned = 0;
      int totalScams = 0;
      int safeMessages = 0;

      try {
        final smsProvider = context.read<ScamDetectionProvider?>();
        if (smsProvider != null) {
          totalScanned = smsProvider.totalScanned;
          totalScams = smsProvider.totalScams;
          safeMessages = smsProvider.safeMessages;
        }
      } catch (e) {
        debugPrint('SMS Provider not available: $e');
      }

      // Get Link scanning stats (if provider is available)
      int linkThreatsDetected = _linkThreats.length;
      int dangerousLinks = _linkThreats.where((t) => (t['riskScore'] as int?) ?? 0 > 70).length;

      // Calculate score based on detection data
      int score = 100;

      // SMS scoring
      if (totalScanned > 0) {
        final scamPercentage = (totalScams / totalScanned) * 100;
        score -= (scamPercentage * 0.3).toInt(); // 30% weight
      }

      // Link scoring
      if (linkThreatsDetected > 0) {
        final dangerousPercentage = (dangerousLinks / linkThreatsDetected) * 100;
        score -= (dangerousPercentage * 0.2).toInt(); // 20% weight
      }

      // Threat diversity bonus/penalty
      int threatTypes = 0;
      if (totalScams > 0) threatTypes++;
      if (dangerousLinks > 0) threatTypes++;

      if (threatTypes > 1) {
        score -= 15; // Multiple threat types detected
      }

      // Safety bonus if no threats
      if (totalScams == 0 && linkThreatsDetected == 0) {
        score = 100;
      }

      return score.clamp(0, 100);
    } catch (e) {
      debugPrint('Error calculating score: $e');
      return 85; // Safe default
    }
  }

  Future<void> _refreshThreats() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _calculateAndNotifyScore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final score = _calculateDynamicScore();

    // Notify parent of score changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onScoreCalculated(score);
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshThreats,
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
                      onPressed: _refreshThreats,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildScoreCard(cardColor, score),
                const SizedBox(height: 30),
                const Text(
                  'Recent Threats',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildThreatsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreatsList() {
    try {
      // Try to get SMS provider for recent detections
      final smsProvider = context.read<ScamDetectionProvider?>();
      if (smsProvider != null && smsProvider.messages.isNotEmpty) {
        return Column(
          children: smsProvider.recentDetections
              .take(5)
              .map((detection) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      child: Icon(
                        detection.isScam ? Icons.warning : Icons.check_circle,
                        color: detection.isScam ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(detection.appName),
                    subtitle: Text(
                      detection.isScam ? '⚠️ Scam Detected' : '✅ Safe',
                      style: TextStyle(
                        color: detection.isScam ? Colors.red : Colors.green,
                      ),
                    ),
                  ))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('SMS Provider not available: $e');
    }

    // Fallback to mock data
    return const Center(
  child: Padding(
    padding: EdgeInsets.all(20),
    child: Text(
      'No recent threats detected',
      style: TextStyle(fontSize: 16),
    ),
  ),
);
  }

  Widget _buildScoreCard(Color cardColor, int score) {
    Color scoreColor;
    String scoreStatus;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreStatus = 'Excellent Protection';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreStatus = 'Good Protection';
    } else if (score >= 40) {
      scoreColor = Colors.orangeAccent;
      scoreStatus = 'Fair Protection';
    } else {
      scoreColor = Colors.red;
      scoreStatus = 'At Risk';
    }

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
                      value: score / 100,
                      strokeWidth: 18,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      color: scoreColor,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'out of 100',
                        style: TextStyle(color: Colors.blue, fontSize: 15),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                scoreStatus,
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on SMS and Link scanning activity',
                style: TextStyle(
                  color: Colors.grey.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= PLACEHOLDER SCREENS =================

class SmsScreen extends StatelessWidget {
  const SmsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('SMS Screen')));
}

class LinksScreen extends StatelessWidget {
  const LinksScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Links Screen')));
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Report Screen')));
}

// ================= PROFILE SCREEN =================

class ProfileScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;
  final int cyberShieldScore;

  const ProfileScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
    required this.cyberShieldScore,
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
        setState(() {});
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
    final displayName =
        user?.displayName?.isNotEmpty == true ? user!.displayName! : "No name set";
    final email = user?.email ?? "No email";

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          colors: [Color(0xFF0066FF), Color(0xFF00FF99)],
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
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: _editName,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email,
                            style: TextStyle(color: textColor?.withOpacity(0.7)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "CyberShield Score: ${widget.cyberShieldScore}/100",
                                style: const TextStyle(
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
                    leading: const Icon(Icons.notifications, color: Colors.blue),
                    title: Text("Notifications", style: TextStyle(color: textColor)),
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
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 18),
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
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}

// ================= PROFILE SUB SCREENS =================

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Change Password")),
        body: const Center(child: Text("Change Password screen under construction")),
      );
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Privacy Policy")),
        body: const Center(child: Text("Privacy Policy screen under construction")),
      );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("About")),
        body: const Center(child: Text("About screen under construction")),
      );
}

// ================= THREAT TILE =================

class ThreatTile extends StatelessWidget {
  final Map<String, dynamic> threat;

  const ThreatTile({super.key, required this.threat});

  @override
  Widget build(BuildContext context) {
    final riskScore = threat['riskScore'] as int? ?? 0;
    final url = threat['url'] as String? ?? 'Unknown';
    final type = threat['type'] as String? ?? 'Unknown';
    
    final color = riskScore > 70 ? Colors.red : Colors.orange;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(Icons.warning, color: color),
      ),
      title: Text(url),
      subtitle: Text('$type • Risk Score: $riskScore%'),
    );
  }
}