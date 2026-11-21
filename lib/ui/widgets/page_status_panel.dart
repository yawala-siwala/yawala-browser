import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import '../../state/browser_state.dart';

/// Clean status view for the active tab: URL/host, load state, engine
/// attachment, history depth and a back control.
class PageStatusPanel extends StatelessWidget {
  const PageStatusPanel({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final tab = state.activeTab;
        if (tab == null) {
          return const Center(
            child: Text('No tabs open - create one to start browsing.'),
          );
        }
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final handle = state.engineHandleFor(tab.id);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(YawalaSpacing.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(YawalaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (tab.isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.public,
                          size: 20,
                          color: scheme.primary,
                        ),
                      const SizedBox(width: YawalaSpacing.sm),
                      Expanded(
                        child: Text(
                          tab.displayName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Back',
                        onPressed:
                            state.canGoBack ? () => unawaited(state.goBack()) : null,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ],
                  ),
                  const Divider(height: YawalaSpacing.lg),
                  _statusRow(context, 'URL', tab.url),
                  _statusRow(context, 'Host', tab.host),
                  _statusRow(
                    context,
                    'Engine',
                    handle == null
                        ? 'not attached (fallback)'
                        : 'attached: ${handle.engineId}',
                  ),
                  _statusRow(
                    context,
                    'Back history',
                    '${state.historyDepthFor(tab.id)} entries',
                  ),
                  _statusRow(
                    context,
                    'Privacy',
                    state.lastClearedAt == null
                        ? 'cookies/cache not cleared this session'
                        : 'cleared at '
                            '${formatIsoDate(state.lastClearedAt!)}',
                  ),
                  const SizedBox(height: YawalaSpacing.md),
                  // Wrap instead of Row: the two buttons flow onto a second
                  // line on narrow viewports instead of overflowing.
                  Wrap(
                    spacing: YawalaSpacing.sm,
                    runSpacing: YawalaSpacing.sm,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => unawaited(state.attachEngineToActiveTab()),
                        icon: const Icon(Icons.extension),
                        label: const Text('Attach engine'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            unawaited(state.openInCustomTab(tab.url)),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open externally'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YawalaSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
