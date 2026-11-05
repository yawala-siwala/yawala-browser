/// An open tab in the Yawala Browser session.
class WebTab {
  const WebTab({
    required this.id,
    required this.title,
    required this.url,
    this.isLoading = false,
  });

  final String id;
  final String title;
  final String url;
  final bool isLoading;

  String get host => Uri.tryParse(url)?.host ?? url;
  String get displayName => title.isEmpty ? host : title;
  String get subtitle => url;
  String get meta => isLoading ? 'loading...' : 'idle';

  bool matches(String query) =>
      displayName.toLowerCase().contains(query) ||
      host.toLowerCase().contains(query);

  WebTab copyWith({String? title, bool? isLoading}) => WebTab(
        id: id,
        title: title ?? this.title,
        url: url,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  String toString() => 'WebTab($id, $url)';
}