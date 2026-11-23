import 'package:material_ui/material_ui.dart';

import '../../state/browser_state.dart';
import '../widgets/address_bar.dart';
import '../widgets/browser_toolbar.dart';
import '../widgets/page_status_panel.dart';
import '../widgets/tab_strip.dart';
import '../widgets/web_page_view.dart';

/// Responsive browser workspace: omnibox, tab management and a clean
/// page/tab status view. Narrow layouts use a horizontal tab strip above
/// the status panel; wide layouts show a two-pane workspace.
class BrowserHomeScreen extends StatelessWidget {
  const BrowserHomeScreen({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yawala Browser'),
        actions: [
          IconButton(
            tooltip: 'Open in Custom Tab / system browser',
            icon: const Icon(Icons.open_in_new),
            onPressed: _openCustomTab,
          ),
          IconButton(
            tooltip: 'Clear cookies & cache',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () => _confirmAndClear(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final pagePane = ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final engine = state.engineFor(state.activeTab?.id ?? '');
              return engine == null
                  ? PageStatusPanel(state: state)
                  : WebPageView(state: state);
            },
          );
          if (wide) {
            return Column(
              children: [
                AddressBar(state: state),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            BrowserToolbar(state: state),
                            Expanded(
                              child: TabStrip(state: state, isListView: true),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 2, child: pagePane),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              AddressBar(state: state),
              TabStrip(state: state),
              const Divider(height: 1),
              Expanded(child: pagePane),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCustomTab() async {
    await state.openInCustomTab();
  }

  Future<void> _confirmAndClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear cookies & cache?'),
        content: const Text(
          'Stored cookies and cached web data will be removed for all '
          'websites. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await state.clearCookiesAndCache();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cookies and cache cleared.')),
    );
  }
}
