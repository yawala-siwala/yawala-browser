import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../state/browser_state.dart';

/// Omnibox: URL or search phrase, normalised by the state machine on submit.
///
/// Owns a single [TextEditingController] for its whole lifetime (the old
/// implementation built a new controller on every rebuild, which dropped
/// cursor position and re-created the field on every keystroke). The field
/// follows programmatic address changes (tab switches, submit
/// normalisation, back-navigation) but never fights the user mid-typing,
/// because state notifications echo exactly what was typed.
class AddressBar extends StatefulWidget {
  const AddressBar({super.key, required this.state});

  final BrowserState state;

  @override
  State<AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<AddressBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.addressText);
    widget.state.addListener(_syncFromState);
  }

  @override
  void didUpdateWidget(AddressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_syncFromState);
      widget.state.addListener(_syncFromState);
      _syncFromState();
    }
  }

  /// Mirrors state-driven address changes into the field; typed text
  /// already matches the state, so user input is never clobbered. The
  /// controller notifies the TextField itself, so no setState is needed.
  void _syncFromState() {
    if (!mounted) {
      return;
    }
    if (_controller.text != widget.state.addressText) {
      _controller.text = widget.state.addressText;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_syncFromState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final activeTab = widget.state.activeTab;
          return TextField(
            controller: _controller,
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
                onPressed: activeTab == null
                    ? null
                    : () => unawaited(widget.state.submitAddress()),
              ),
            ),
            onChanged: widget.state.setAddressText,
            onSubmitted: activeTab == null
                ? null
                : (_) => unawaited(widget.state.submitAddress()),
          );
        },
      ),
    );
  }
}
