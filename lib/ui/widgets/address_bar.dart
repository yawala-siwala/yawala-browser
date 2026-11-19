import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../state/browser_state.dart';

/// Omnibox: URL or search phrase, normalised by the state machine on submit.
class AddressBar extends StatelessWidget {
  const AddressBar({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final activeTab = state.activeTab;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: TextEditingController(text: state.addressText)
              ..selection = TextSelection.collapsed(
                offset: state.addressText.length,
              ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.language),
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: activeTab == null
                  ? 'Open a tab to start browsing'
                  : 'Search or enter address',
              suffixIcon: IconButton(
                tooltip: 'Go',
                icon: const Icon(Icons.arrow_forward),
                onPressed:
                    activeTab == null ? null : () => unawaited(state.submitAddress()),
              ),
            ),
            onChanged: state.setAddressText,
            onSubmitted: activeTab == null
                ? null
                : (_) => unawaited(state.submitAddress()),
          ),
        );
      },
    );
  }
}
