/// Practice Journal facade — cross-feature public provider boundary.
///
/// Other features (e.g. practice recording) wire in journal behaviour
/// through this facade instead of importing presentation/providers directly.
library;

export 'domain/entities/bound_volume.dart' show BoundVolume;
export 'presentation/providers/practice_journal_provider.dart'
    show
        boundVolumesProvider,
        practiceJournalRepositoryProvider,
        practiceLedgerProvider;
