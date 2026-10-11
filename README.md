# tillora_pos

Tillora POS - local-first point of sale for desktop and mobile

## Folder structure

Feature-first clean architecture. Dependencies point inwards:
`presentation → domain ← data → infrastructure`, and everything may use `core`.

```
lib/
  main.dart
  app/                 Bootstrap, dependency injection (get_it), router (go_router)
  core/                Pure, app-wide code with no I/O
    errors/            AppException (data layer), Failure + Result (domain/UI)
    usecases/          UseCase<T, Params> base class, NoParams
    theme/ responsive/ platform/ utils/ l10n/ config/
    widgets/           Shared UI widgets
  infrastructure/      Talks to the outside world; used only by features' data layers
    database/          AppDatabase, tables/, dao/, migrations/
    hardware/          Receipt/label printer, cash drawer, scale, scanner, customer display
    backup/ logging/
  features/<area>/<feature>/
    domain/            entities/, repositories/ (interfaces), usecases/ — plain Dart, no Flutter
    data/              models/, datasources/, repositories/ (implementations)
    presentation/      bloc/, screens/, layouts/ (desktop/mobile), widgets/
test/                  Mirrors lib/ (core/, infrastructure/, features/...)
```

Rules:
- `domain` imports only `core` and its own feature's domain.
- `data` implements `domain` repositories, catches `AppException`s and returns `Result`.
- `presentation` reaches `domain` only through use cases injected via `app/di`.
- Features never import another feature's `data` or `presentation`.
