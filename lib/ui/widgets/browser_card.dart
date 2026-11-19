import 'package:material_ui/material_ui.dart';

import '../../domain/model.dart';

/// List row for a single WebTab: activate on tap, close via the trailing
/// button, with a spinner while the page is loading.
class WebTabCard extends StatelessWidget {
  const WebTabCard({
    super.key,
    required this.item,
    this.selected = false,
    this.onTap,
    this.onClose,
  });

  final WebTab item;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: item.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.public,
                color:
                    selected ? Theme.of(context).colorScheme.primary : null,
              ),
        title: Text(item.displayName),
        subtitle: Text(item.subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.meta),
            if (onClose != null)
              IconButton(
                tooltip: 'Close tab',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
          ],
        ),
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
