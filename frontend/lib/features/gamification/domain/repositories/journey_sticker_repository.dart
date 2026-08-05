import '../entities/journey_sticker.dart';

/// Repository interface for the computed journey sticker catalog.
///
/// Read-only by design — the catalog is derived from existing logs on every
/// call, there is nothing for the client to write back (P3b, doc 46 §5).
abstract class JourneyStickerRepository {
  Future<JourneyStickerCatalog> getCatalog(String studentId);
}
