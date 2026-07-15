/// Utility to handle URL transformations, specifically for cloud storage links.
class UrlHelpers {
  /// Converts a Google Drive "view" link to a direct download link.
  ///
  /// Example input: https://drive.google.com/file/d/1ABC123_XYZ/view?usp=sharing
  /// Example output: https://drive.google.com/uc?export=download&id=1ABC123_XYZ
  static String getDirectPdfUrl(String url) {
    if (!url.contains('drive.google.com')) return url;

    // Matches /d/FILE_ID/ or id=FILE_ID
    final regExp = RegExp(r'(?:/d/|id=)([\w-]+)');
    final match = regExp.firstMatch(url);

    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    return url;
  }
}
