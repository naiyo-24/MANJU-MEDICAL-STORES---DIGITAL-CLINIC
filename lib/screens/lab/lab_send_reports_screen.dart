import 'package:flutter/material.dart';

class LabSendReportsScreen extends StatelessWidget {
  const LabSendReportsScreen({super.key});

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
                  Text('Send Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Share generated reports with patients via WhatsApp', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients, phone number...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Batch Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), // Green for WhatsApp
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send_outlined, size: 48, color: Color(0xFF94A3B8)),
                    SizedBox(height: 16),
                    Text('No pending reports to send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    SizedBox(height: 4),
                    Text('Reports marked as ready will appear here.', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
