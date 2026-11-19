import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import '../../state/browser_state.dart';

/// Open-tab chips with close buttons and a new-tab action. Renders as a
/// horizontal strip on narrow layouts and a wrapped list on wide ones
/// ([isListView]).
class TabStrip extends StatelessWidget {
  const TabStrip({
    super.key,
    required this.state,
    this.isListView = false,
  });

  final BrowserState state;

  /// Whether the strip renders as a wrapped list (wide workspaces).
  final bool isListView;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final tabs = state.visibleTabs;
        final newTabChip = ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('New tab'),
          onPressed: () => unawaited(state.openTab('about:blank')),
        );

        final chips = <Widget>[
          for (final tab in tabs)
            InputChip(
              label: Text(tab.displayName),
              selected: tab.id == state.activeTab?.id,
              visualDensity: VisualDensity.compact,
              onPressed: () => state.activate(tab.id),
              onDeleted: () => state.close(tab.id),
            ),
          newTabChip,
        ];

        if (isListView) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(YawalaSpacing.md),
            child: Align(
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: YawalaSpacing.sm,
                runSpacing: YawalaSpacing.sm,
                children: chips,
              ),
            ),
          );
        }

        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: YawalaSpacing.md,
              vertical: YawalaSpacing.xs,
            ),
            children: chips,
          ),
        );
      },
    );
  }
}
