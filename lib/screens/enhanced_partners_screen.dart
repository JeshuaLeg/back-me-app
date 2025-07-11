import 'package:flutter/material.dart';
import '../models/firebase_partner.dart';
import '../services/firebase_partner_service.dart';
import '../main.dart';
import '../utils/date_formatter.dart';

class EnhancedPartnersScreen extends StatefulWidget {
  const EnhancedPartnersScreen({super.key});

  @override
  State<EnhancedPartnersScreen> createState() => _EnhancedPartnersScreenState();
}

class _EnhancedPartnersScreenState extends State<EnhancedPartnersScreen> {
  final FirebasePartnerService _partnerService = FirebasePartnerService();
  List<FirebasePartner> _partners = [];
  List<PartnerInvite> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnersAndInvites();
  }

  Future<void> _loadPartnersAndInvites() async {
    try {
      await _partnerService.initialize();
      
      // For now, use mock data since the methods don't exist yet
      setState(() {
        _partners = [];
        _invites = [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading partners: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A),
              AppTheme.primarySlate.withValues(alpha: 0.05),
              const Color(0xFF0F172A),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  _buildStatsSection(),
                  _buildPartnersSection(),
                  _buildInvitesSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accountability Partners',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build your support network',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentIndigo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.people,
                    color: AppTheme.accentIndigo,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddPartnerDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Partner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showInviteDialog,
                    icon: const Icon(Icons.sms),
                    label: const Text('Invite via SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Partners',
                '${_partners.length}',
                Icons.people,
                AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending Invites',
                '${_invites.length}',
                Icons.schedule,
                AppTheme.warningAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Partners',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 16),
            if (_partners.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No partners yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add accountability partners to help you stay on track with your goals.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...(_partners.map((partner) => _buildPartnerCard(partner))),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(FirebasePartner partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentIndigo.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.accentIndigo,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.recipientName ?? 'Partner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  partner.recipientEmail ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connected ${DateFormatter.formatTimeAgo(partner.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showPartnerActions(partner),
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Invites',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 16),
            if (_invites.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 64,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending invites',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invitations you send will appear here until they are accepted.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...(_invites.map((invite) => _buildInviteCard(invite))),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(PartnerInvite invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningAmber.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sms,
              color: AppTheme.warningAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.recipientName ?? 'Unknown Contact',
                  style: TextStyle(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invite.recipientPhone ?? 'No phone number',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invited ${DateFormatter.formatTimeAgo(invite.createdAt)}',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showInviteActions(invite),
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPartnerDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          'Add Partner',
          style: TextStyle(color: AppTheme.lightText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Partner Name',
                labelStyle: TextStyle(color: AppTheme.mutedText),
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(color: AppTheme.lightText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: AppTheme.mutedText),
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(color: AppTheme.lightText),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _showSuccessMessage('Partner request sent!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentIndigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Partner'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    // Mock contact list for demo
    final contacts = [
      {'name': 'John Doe', 'phone': '+1234567890'},
      {'name': 'Jane Smith', 'phone': '+0987654321'},
      {'name': 'Mike Johnson', 'phone': '+1122334455'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          'Invite via SMS',
          style: TextStyle(color: AppTheme.lightText),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentIndigo,
                  child: Text(
                    contact['name']![0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  contact['name']!,
                  style: TextStyle(color: AppTheme.lightText),
                ),
                subtitle: Text(
                  contact['phone']!,
                  style: TextStyle(color: AppTheme.mutedText),
                ),
                trailing: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSuccessMessage('SMS invitation sent to ${contact['name']!}');
                  },
                  icon: Icon(
                    Icons.send,
                    color: AppTheme.accentIndigo,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  void _showPartnerActions(FirebasePartner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          partner.recipientName ?? 'Partner',
          style: TextStyle(color: AppTheme.lightText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.message, color: AppTheme.accentIndigo),
              title: Text('Send Message', style: TextStyle(color: AppTheme.lightText)),
              onTap: () {
                Navigator.of(context).pop();
                _showSuccessMessage('Messaging feature coming soon!');
              },
            ),
            ListTile(
              leading: Icon(Icons.person_remove, color: AppTheme.errorRose),
              title: Text('Remove Partner', style: TextStyle(color: AppTheme.lightText)),
              onTap: () {
                Navigator.of(context).pop();
                _showSuccessMessage('Partner removed');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteActions(PartnerInvite invite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          'Invite Actions',
          style: TextStyle(color: AppTheme.lightText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.refresh, color: AppTheme.accentIndigo),
              title: Text('Resend Invite', style: TextStyle(color: AppTheme.lightText)),
              onTap: () {
                Navigator.of(context).pop();
                _showSuccessMessage('Invite resent');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppTheme.errorRose),
              title: Text('Cancel Invite', style: TextStyle(color: AppTheme.lightText)),
              onTap: () {
                Navigator.of(context).pop();
                _showSuccessMessage('Invite cancelled');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }
}

// Mock class for PartnerInvite since it doesn't exist
class PartnerInvite {
  final String? recipientName;
  final String? recipientPhone;
  final DateTime createdAt;

  PartnerInvite({
    this.recipientName,
    this.recipientPhone,
    required this.createdAt,
  });
} 