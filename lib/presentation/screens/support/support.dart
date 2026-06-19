import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class SupportTab extends StatelessWidget {
  const SupportTab({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'We\'re here to help. Reach out any time.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            // Contact Cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(text: 'CONTACT US'),
                    const SizedBox(height: 12),
                    _ContactCard(
                      icon: Icons.chat_bubble_outline,
                      iconColor: const Color(0xFF25D366),
                      iconBg: const Color(0xFFEAFFF3),
                      title: 'WhatsApp',
                      subtitle: 'Chat with us directly — fastest response',
                      action: 'Open WhatsApp',
                      onTap: () => _launchUrl('https://wa.me/254734232994'),
                    ),
                    const SizedBox(height: 12),
                    _ContactCard(
                      icon: Icons.email_outlined,
                      iconColor: AppColors.primary,
                      iconBg: const Color(0xFFEAFFF3),
                      title: 'Email Support',
                      subtitle: 'support@darasahub.com',
                      action: 'Send Email',
                      onTap: () => _launchUrl('mailto:support@darasahub.com'),
                      onLongPress: () => _copyToClipboard(context, 'support@darasahub.com', 'Email'),
                    ),
                    const SizedBox(height: 12),
                    _ContactCard(
                      icon: Icons.phone_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Call Us',
                      subtitle: '+254 734 232 994',
                      action: 'Call Now',
                      onTap: () => _launchUrl('tel:+254734232994'),
                      onLongPress: () => _copyToClipboard(context, '+254734232994', 'Phone number'),
                    ),
                  ],
                ),
              ),
            ),

            // FAQ Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(text: 'FREQUENTLY ASKED'),
                    const SizedBox(height: 12),
                    _FaqTile(
                      question: 'How do I unlock full access?',
                      answer:
                      'After signing up and verifying your email, sign in and tap "Unlock Full Access". You\'ll be guided through an payment to activate your subscription.',
                    ),
                    _FaqTile(
                      question: 'I paid but the app is still locked. What do I do?',
                      answer:
                      'Payments are confirmed automatically within a few minutes. If access isn\'t restored after 10 minutes, contact us on WhatsApp with your transaction code and we\'ll sort it out immediately.',
                    ),
                    _FaqTile(
                      question: 'Can I use the app on multiple devices?',
                      answer:
                      'Yes. Your account and progress sync across all devices. Simply sign in with the same email and password.',
                    ),
                    _FaqTile(
                      question: 'How many times can I take a practice test?',
                      answer:
                      'Unlimited. You can retake any of the 19 units as many times as you need. We recommend revisiting units where your score is below 80%.',
                    ),
                    _FaqTile(
                      question: 'I forgot my password. How do I reset it?',
                      answer:
                      'On the sign-in screen, tap "Forgot password?" and enter your email. You\'ll receive a reset link within a few minutes.',
                    ),
                  ],
                ),
              ),
            ),

            // Legal / Privacy Section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(text: 'LEGAL'),
                    const SizedBox(height: 12),
                    _ContactCard(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFF5F3FF),
                      title: 'Privacy Policy',
                      subtitle: 'How we collect and use your data',
                      action: 'Read',
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    const SizedBox(height: 12),
                    _ContactCard(
                      icon: Icons.delete_outline,
                      iconColor: Colors.redAccent,
                      iconBg: const Color(0xFFFFF1F1),
                      title: 'Delete My Account',
                      subtitle: 'Request permanent account & data deletion',
                      action: 'Request',
                      onTap: () => _launchUrl(
                          'mailto:masomo@darasahub.com?subject=Account%20Deletion%20Request&body=Please%20delete%20my%20account%20and%20all%20associated%20data.'),
                    ),
                  ],
                ),
              ),
            ),

            // App info footer
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFFF3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car_outlined,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DarasaDrive Academy',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Version 1.0.0 · Kenya',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

// ── Privacy Policy Bottom Sheet ───────────────────────────────────────────────

class _PrivacyPolicySheet extends StatelessWidget {
  const _PrivacyPolicySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.privacy_tip_outlined,
                          color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: const [
                    _PolicyMeta(
                      text: 'Our Privacy policy',
                    ),
                    SizedBox(height: 20),
                    _PolicySection(
                      title: '1. Who We Are',
                      body:
                      'DarasaDrive Academy ("we", "us", or "our") is a mobile application operated by DarasaHub Holdings Ltd, a company registered in Kenya. We help learner drivers prepare for the NTSA theory and practical driving tests.\n\nContact: masomo@darasahub.com',
                    ),
                    _PolicySection(
                      title: '2. Information We Collect',
                      body:
                      'Account data – your full name, email address, and M-Pesa phone number when you register.\n\n'
                          'Payment data – Transaction codes processed via Safaricom Daraja API. We do not store card numbers or PINs.\n\n'
                          'Usage data – test scores, units completed, session timestamps, and device type. This data is tied to your account to power progress tracking.\n\n'
                          'We do not collect location data, contacts, camera, or microphone access.',
                    ),
                    _PolicySection(
                      title: '3. How We Use Your Information',
                      body:
                      '• Provide and personalise the DarasaDrive service\n'
                          '• Process M-Pesa payments and verify subscription status\n'
                          '• Track and display your test progress\n'
                          '• Respond to support requests\n'
                          '• Improve app performance and fix bugs\n\n'
                          'We do not use your data to serve advertisements.',
                    ),
                    _PolicySection(
                      title: '4. Legal Basis for Processing',
                      body:
                      'We process your data on the following bases under the Kenya Data Protection Act 2019:\n\n'
                          '• Contract – processing necessary to deliver the service you signed up for.\n'
                          '• Legitimate interest – anonymised analytics to improve the product.\n'
                          '• Consent – where you have given clear permission',
                    ),
                    _PolicySection(
                      title: '5. Data Sharing',
                      body:
                      'We share your data only with:\n\n'
                          '• Supabase (database and authentication hosting)\n'
                          '• Safaricom Daraja API (M-Pesa payment processing)\n\n'
                          'We do not sell, rent, or share your personal data with advertisers or any other third parties. All sub-processors are bound by data processing agreements.',
                    ),
                    _PolicySection(
                      title: '6. Data Retention',
                      body:
                      'We keep your account data for as long as your account is active. If you delete your account, we erase your personal data.',
                    ),
                    _PolicySection(
                      title: '7. Your Rights',
                      body:
                      'Under the Kenya Data Protection Act 2019, you have the right to:\n\n'
                          '• Access the personal data we hold about you\n'
                          '• Correct inaccurate data\n'
                          '• Request deletion of your data ("right to be forgotten")\n'
                          '• Object to or restrict certain processing\n'
                          '• Withdraw consent at any time\n\n'
                          'To exercise any of these rights, email us at masomo@darasahub.com. We will respond within 14 days.',
                    ),
                    _PolicySection(
                      title: '8. Account & Data Deletion',
                      body:
                      'You can request full deletion of your account and all associated data at any time by:\n\n'
                          '• Tapping "Delete My Account" on the Support screen, or\n'
                          '• Emailing masomo@darasahub.com with the subject "Account Deletion Request"\n\n'
                          'Deletion is permanent and irreversible. Your progress, bookings, and payment history will be removed from our system.',
                    ),
                    _PolicySection(
                      title: '9. Security',
                      body:
                      'We use industry-standard security measures including TLS encryption in transit, hashed passwords, and row-level security policies in Supabase. Access to production data is restricted to authorised personnel only.',
                    ),
                    _PolicySection(
                      title: '10. Children\'s Privacy',
                      body:
                      'DarasaDrive is intended for users aged 16 and above (the minimum age to obtain a Kenyan learner\'s licence). We do not knowingly collect personal data from children under 16. If you believe a child has provided us data, please contact us and we will delete it promptly.',
                    ),
                    _PolicySection(
                      title: '11. Changes to This Policy',
                      body:
                      'We may update this Privacy Policy from time to time. We will notify you of material changes via the app or email at least 14 days before they take effect. Continued use of the app after that date constitutes acceptance of the updated policy.',
                    ),
                    _PolicySection(
                      title: '12. Contact Us',
                      body:
                      'DarasaHub holdings Ltd\nEmail: masomo@darasahub.com\nNairobi, Kenya',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PolicyMeta extends StatelessWidget {
  const _PolicyMeta({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: Text(action,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(widget.question,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                                height: 1.3)),
                      ),
                      const SizedBox(width: 8),
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted, size: 20),
                      ),
                    ],
                  ),
                ),
                SizeTransition(
                  sizeFactor: _animation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(widget.answer,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13, height: 1.5)),
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