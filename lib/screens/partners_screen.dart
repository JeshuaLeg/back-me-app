import 'package:flutter/material.dart';
import '../main.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Accountability Partners'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddPartnerDialog(context),
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A),
              AppTheme.primarySlate.withOpacity(0.05),
              const Color(0xFF0F172A),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Increased bottom spacing for nav clearance
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 80,
                  color: AppTheme.mutedText,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Partners Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add accountability partners to help you stay on track with your goals.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.mutedText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _showAddPartnerDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Partner'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPartnerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Accountability Partner'),
        content: const Text('Feature coming soon! You\'ll be able to add friends and family members who can help keep you accountable to your goals.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 