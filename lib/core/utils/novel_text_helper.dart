class NovelTextHelper {
  NovelTextHelper._();

  static final RegExp _urduRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  /// Returns true if the text consists predominantly of Urdu/Arabic script characters.
  static bool isUrduText(String text) {
    if (text.trim().isEmpty) return false;
    final totalLetters = text.replaceAll(RegExp(r'[\s\d\p{P}]', unicode: true), '').length;
    if (totalLetters == 0) return false;
    final urduLetters = _urduRegex.allMatches(text).length;
    return (urduLetters / totalLetters) >= 0.25;
  }

  /// Splits novel manuscript prose (English or Urdu) into clean reading lines / paragraphs.
  /// Handles varied author conventions: double newlines, single newlines, dialogue quotes,
  /// and long continuous walls of text (splitting at natural sentence boundaries).
  static List<String> splitProseIntoLines(String prose) {
    final trimmed = prose.trim();
    if (trimmed.isEmpty) return const [];

    final rawBlocks = trimmed
        .split(RegExp(r'\r?\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final lines = <String>[];

    for (final block in rawBlocks) {
      final isUrdu = isUrduText(block);
      final wordCount = block.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      // If a block is moderately sized or short (e.g. standard dialogue or paragraph), keep it intact.
      if (wordCount <= 65) {
        lines.add(block);
        continue;
      }

      // If author wrote or pasted a long continuous wall of text without newlines,
      // break it into coherent reading chunks at sentence boundaries.
      final subLines = _breakLongBlockIntoSentences(block, isUrdu: isUrdu);
      if (subLines.isNotEmpty) {
        lines.addAll(subLines);
      } else {
        lines.add(block);
      }
    }

    return lines;
  }

  static List<String> _breakLongBlockIntoSentences(String text, {required bool isUrdu}) {
    final delimiterPattern = isUrdu
        ? RegExp(r'(?<=[۔؟!])\s+')
        : RegExp(r'(?<=[.?!])\s+');

    final sentences = text
        .split(delimiterPattern)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.length <= 1) return [text];

    final chunks = <String>[];
    final currentChunk = StringBuffer();
    var currentWords = 0;

    for (final sentence in sentences) {
      final wordsInSentence = sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      if (currentWords + wordsInSentence > 50 && currentChunk.isNotEmpty) {
        chunks.add(currentChunk.toString().trim());
        currentChunk.clear();
        currentWords = 0;
      }

      if (currentChunk.isNotEmpty) {
        currentChunk.write(' ');
      }
      currentChunk.write(sentence);
      currentWords += wordsInSentence;
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString().trim());
    }

    return chunks.isNotEmpty ? chunks : [text];
  }
}
