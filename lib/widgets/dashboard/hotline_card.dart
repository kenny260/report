import 'package:flutter/material.dart';

/// One contact entry (icon, title, number or email).
class HotlineCard extends StatelessWidget {
  final String title;
  final String contact;
  final IconData icon;
  final MaterialColor color;

  const HotlineCard({
    super.key,
    required this.title,
    required this.contact,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color[50],
          child: Icon(icon, color: color[700]),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(contact, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
