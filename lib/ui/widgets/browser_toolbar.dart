import 'package:flutter/material.dart';

import '../../state/app_state.dart';

/// Search / filter bar shown above the tabs list.
class BrowserToolbar extends StatelessWidget {
  const BrowserToolbar({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Search open tabs',
              ),
              onChanged: state.setFilter,
            ),
          ),
          ListenableBuilder(
            listenable: state,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Chip(label: Text('${state.items.length} tabs')),
            ),
          ),
        ],
      ),
    );
  }
}