/// Vocabulary tool — cross-feature public boundary (#1124).
///
/// The practice-tools registry (practice feature) mounts [VocabBookPanel] as the
/// language discipline's 단어장 tab through this facade instead of importing
/// presentation widgets directly (flutter-architecture: cross-feature = facade).
library;

export 'presentation/widgets/vocab_book_panel.dart' show VocabBookPanel;
