import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../widgets/browser_card.dart';
import '../widgets/browser_toolbar.dart';

/// Main screen of Yawala Browser: toolbar, tabs list and primary action.
class BrowserHomeScreen extends StatelessWidget {
  const BrowserHomeScreen({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yawala Browser')),
      body: Column(
        children: [
          BrowserToolbar(state: state),
          Expanded(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = state.items.toList(growable: false);
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Nothing found - try a different search.'),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      WebTabCard(item: items[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New tab',
        onPressed: () => state.openNewTab('about:blank'),
        child: const Icon(Icons.add),
      ),
    );
  }
}