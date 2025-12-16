import 'package:flutter/material.dart';
import '../../config/routes.dart';

class SelectUserScreen extends StatelessWidget {
  const SelectUserScreen({super.key});

  // App Theme Colors
  static const _primaryColor = Color(0xFF6366F1); // Indigo
  static const _secondaryColor = Color(0xFFF97316); // Orange for child
  static const _bgColor = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              const Text(
                'Kid Guard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Digital parenting made simple',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),

              const Spacer(flex: 2),

              // Selection Label
              Text(
                'I am a...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 20),

              // Parent Card
              _UserCard(
                title: 'Parent',
                subtitle: 'Monitor and manage activity',
                icon: Icons.person_rounded,
                color: _primaryColor,
                onTap: () => Navigator.pushNamed(context, AppRoutes.login),
              ),

              const SizedBox(height: 12),

              // Child Card
              _UserCard(
                title: 'Child',
                subtitle: 'Connect to parent account',
                icon: Icons.child_care_rounded,
                color: _secondaryColor,
                onTap: () => Navigator.pushNamed(context, AppRoutes.childPin),
              ),

              const Spacer(flex: 3),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Secure & Private',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _UserCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
