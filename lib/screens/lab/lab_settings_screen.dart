import 'package:flutter/material.dart';

class LabSettingsScreen extends StatelessWidget {
  const LabSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Manage laboratory preferences and configurations', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('General Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.business, color: Color(0xFF64748B)),
                    title: const Text('Laboratory Details', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Update lab name, address, and contact info'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.print, color: Color(0xFF64748B)),
                    title: const Text('Report Formatting', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Configure letterhead and footer for PDF reports'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.chat, color: Color(0xFF64748B)),
                    title: const Text('WhatsApp Integration', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Manage API keys and messaging templates'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts, color: Color(0xFF64748B)),
                    title: const Text('Staff Management', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Add or remove laboratory staff members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
