import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Opens WhatsApp with a pre-filled message containing the invite link
  static Future<bool> sendInviteLink({
    required String phoneNumber,
    required String clientName,
    required String inviteUrl,
  }) async {
    final message = Uri.encodeComponent(
      'Hi $clientName, please complete your profile and measurements for your order: $inviteUrl',
    );

    // Clean phone number (remove +, spaces, dashes)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');

    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Copies the invite link to clipboard
  static Future<void> copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }
}
