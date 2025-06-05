import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SocialFooter extends StatelessWidget {
  const SocialFooter({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _shareApp(BuildContext context) {
    Share.share(
      'Check out MeHal Gebeya - Your one-stop shop for Ethiopian products! Download now: [App Store Link]',
      subject: 'MeHal Gebeya - Ethiopian E-commerce App',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            'Follow Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: FontAwesomeIcons.facebook,
                  color: const Color(0xFF1877F2),
                  onTap: () => _launchUrl('https://facebook.com/mehalgebeya'),
                ),
                _buildSocialButton(
                  icon: FontAwesomeIcons.telegram,
                  color: const Color(0xFF0088cc),
                  onTap: () => _launchUrl('https://t.me/mehalgebeya'),
                ),
                _buildSocialButton(
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF25D366),
                  onTap: () => _launchUrl('https://wa.me/message/YOUR_WHATSAPP_NUMBER'),
                ),
                _buildSocialButton(
                  icon: FontAwesomeIcons.twitter,
                  color: const Color(0xFF1DA1F2),
                  onTap: () => _launchUrl('https://twitter.com/mehalgebeya'),
                ),
                _buildSocialButton(
                  icon: FontAwesomeIcons.instagram,
                  color: const Color(0xFFE4405F),
                  onTap: () => _launchUrl('https://instagram.com/mehalgebeya'),
                ),
                _buildSocialButton(
                  icon: FontAwesomeIcons.share,
                  color: Colors.grey.shade700,
                  onTap: () => _shareApp(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '© ${DateTime.now().year} MeHal Gebeya. All rights reserved.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
} 