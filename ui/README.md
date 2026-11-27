# `laplaceliu/tycho_ui`

Flutter-inspired pure-MoonBit declarative UI framework built on `laplaceliu/tycho_2d`, `laplaceliu/tycho`, and `laplaceliu/tycho_math`.

## Highlights
- **Three Trees + Layer Compositing**: `Widget` → `ElementNode` (keyed Diff reconciliation) → `RenderNode` (single-pass `BoxConstraints` + `RepaintBoundary` `DisplayList` cache) → `Layer`.
- **Fine-Grained Reactivity**: `Signal[T]` / `Computed[T]` automatically subscribe only the `Element`s that read them; subscriptions are released when a rebuild stops reading a signal or when an element unmounts, and dirty tracking is scoped to one `UiTree` (no process-global state).
- **Optional Parameters**: widget constructors take native MoonBit optional parameters (`width? : Float`), so call sites read `sized_box(width=390.0, child=card)` instead of wrapping every argument in `Some(...)`.
- **Grouped Decoration**: `container` takes `decoration : DecoratedProps` (`fill`, `shader`, `border_color`/`border_width`, `radius` + per-corner `tl`/`tr`/`br`/`bl`, `shadow_dx`/`shadow_dy`/`shadow_blur`/`shadow_color`) instead of 13 separate arguments, so a bordered, rounded, shadowed surface is one constructor call: `container(decoration=DecoratedProps::new(fill=bg, radius=8.0, border_width=1.5, border_color=line), child=body)`.
- **Rich Layout & Controls**: `Row`/`Column` (`gap`, `Expanded`, `Flexible`), `Stack`/`Positioned`, `Wrap`, `ThemeData` (Dark/Light), `filled_button`, `outlined_button`, `checkbox`, `switch_toggle`, `slider`, `progress_bar`, `text_field`, `frosted_dialog`, and virtualized `list_view_builder` (constant node count for 100,000+ rows).
- **Desktop Input & Testing**: `GestureArena` (tap vs drag disambiguation), `MouseRegion` hover tracking, `AppRunner` window loop, and headless `WidgetTester`.
