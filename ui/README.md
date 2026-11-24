# `laplaceliu/tycho_ui`

Flutter-inspired pure-MoonBit declarative UI framework built on `laplaceliu/tycho_2d` and `laplaceliu/tycho`.

## Highlights
- **Three Trees + Layer Compositing**: `Widget` → `ElementNode` (keyed Diff reconciliation) → `RenderNode` (single-pass `BoxConstraints` + `RepaintBoundary` `DisplayList` cache) → `Layer`.
- **Fine-Grained Reactivity**: `Signal[T]` / `Computed[T]` automatically subscribe only the `Element`s that read them.
- **Rich Layout & Controls**: `Row`/`Column` (`gap`, `Expanded`, `Flexible`), `Stack`/`Positioned`, `Wrap`, `ThemeData` (Dark/Light), `filled_button`, `outlined_button`, `checkbox`, `switch_toggle`, `slider`, `progress_bar`, `text_field`, `frosted_dialog`, and virtualized `list_view_builder` (constant node count for 100,000+ rows).
- **Desktop Input & Testing**: `GestureArena` (tap vs drag disambiguation), `MouseRegion` hover tracking, `AppRunner` window loop, and headless `WidgetTester`.
