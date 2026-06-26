import '../theme/expertise_color_resolver.dart';

/// Back-compat alias for the generalized [ExpertiseColorPair] (#967).
typedef InstrumentColorPair = ExpertiseColorPair;

/// Music instrument -> color pair for schedule views.
///
/// Thin alias over the discipline-scoped
/// [ExpertiseColorResolverRegistry.music] (#967). Kept for existing call sites;
/// the color map SSOT now lives in the resolver registry.
class InstrumentColors {
  InstrumentColors._();

  /// Color pair for a music instrument name. Delegates to the music resolver.
  static ExpertiseColorPair getColor(String instrument) =>
      ExpertiseColorResolverRegistry.music.resolve(instrument);
}
