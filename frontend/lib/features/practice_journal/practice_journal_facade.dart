/// Practice Journal facade — cross-feature public provider boundary.
///
/// Other features (e.g. practice recording) wire in journal behaviour
/// through this facade instead of importing presentation/providers directly.
library;

export 'presentation/providers/practice_journal_provider.dart'
    show practiceJournalRepositoryProvider, practiceLedgerProvider;
