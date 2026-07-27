/// Strip HTML tags and decode entities from user input to prevent stored XSS on web.
///
/// Entities are decoded BEFORE tag stripping so that encoded payloads such as
/// `&lt;script&gt;` are turned into real tags and then removed. `&amp;` is
/// decoded last to avoid re-introducing tags from double-encoded input.
String sanitizeInput(String input) {
  final decoded = input
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
  return decoded.replaceAll(RegExp(r'<[^>]*>'), '');
}
