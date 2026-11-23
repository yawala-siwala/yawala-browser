import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import '../../state/browser_state.dart';

/// Live web-page workspace for the active tab: real WebView rendering with
/// back/forward/reload controls. Web history takes precedence; the app-level
/// history backs the Web back button up when the page stack is exhausted.
class WebPageView extends StatelessWidget {
  const WebPageView({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    final engine = state.engineFor(state.activeTab?.id ?? '');
    if (engine == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Web back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => unawaited(_goBack()),
              ),
              IconButton(
                tooltip: 'Web forward',
                icon: const Icon(Icons.arrow_forward),
                onPressed: () async {
                  if (await engine.canGoForward()) {
                    await engine.forward();
                  }
                },
              ),
              IconButton(
                tooltip: 'Reload page',
                icon: const Icon(Icons.refresh),
                onPressed: () => unawaited(engine.reload()),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: YawalaSpacing.md),
                  child: ListenableBuilder(
                    listenable: state,
                    builder: (context, _) {
                      final tab = state.activeTab;
                      return Text(
                        tab?.isLoading == true
                            ? 'Loading ${tab?.host ?? ''}...'
                            : tab?.displayName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: engine.buildView()),
      ],
    );
  }

  /// Real web history first; the app-level back stack fills in when the
  /// page has nowhere to go back to (e.g. first load of the session).
  Future<void> _goBack() async {
    final engine = state.engineFor(state.activeTab?.id ?? '');
    if (engine == null) {
      return;
    }
    if (await engine.canGoBack()) {
      await engine.back();
    } else {
      await state.goBack();
    }
  }
}
