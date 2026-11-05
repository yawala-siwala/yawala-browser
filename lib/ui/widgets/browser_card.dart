import 'package:flutter/material.dart';

import '../../domain/model.dart';

/// List row for a single WebTab.
class WebTabCard extends StatelessWidget {
  const WebTabCard({super.key, required this.item});

  final WebTab item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.public),
        title: Text(item.displayName),
        subtitle: Text(item.subtitle),
        trailing: Text(item.meta),
      ),
    );
  }
}