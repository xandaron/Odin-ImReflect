# ImReflect

An [Odin](https://odin-lang.org/) package built on top of [Dear ImGui](https://github.com/ocornut/imgui) that uses Odin's runtime type reflection to automatically generate editable inspector UI for any value at runtime.

---

## Overview

ImReflect walks the Odin type system at runtime and renders an appropriate ImGui widget for every field it encounters. Pass any value to `draw_value` and get a full recursive inspector tree for free.

This makes it ideal for:

- **Game/engine tooling** — inspect entity components, settings structs, or world state while the program is running.
- **Debugging** — see and edit live data without recompiling or adding print statements.
- **Rapid prototyping** — expose tunable parameters instantly without writing any UI code.

---

## Usage

The entire public API is a single procedure:

```odin
draw_value :: proc(name: string, value: any, flags: Draw_Flags = nil)
```

Call it inside your ImGui frame, inside any window:

```odin
imgui.Gui_Begin("Inspector", nil, nil)

imrefl.draw_value("my_struct", my_struct)

imgui.Gui_End()
```

That's it. ImReflect will recursively build the entire UI for you.

### Flags

`draw_value` accepts a `Draw_Flags` bit set as an optional third argument to control rendering behaviour.

| Flag | Tag | Description |
|---|---|---|
| `Read_Only` | `read-only` | Disables all editable widgets, rendering the value for inspection only. |
| `Padding` | `padding` | Used to stop a struct field from being drawn. |

Flags can also be applied on a per-field basis using the `imrefl` struct tag. Multiple values can be comma-separated.

```odin
My_Struct :: struct {
    editable_field:   int,
    read_only_field:  int `imrefl:"read-only"`,
    _:                [4]byte `imrefl:"padding"`,
}
```

Flags propagate to nested types meaning a top level `Read_Only` flag will make all sub fields `Read_Only`.

### Quick Start with the Bootstrap Package

If you just want to get something on screen as fast as possible, the `bootstrap` sub-package wraps all of the GLFW + OpenGL3 + ImGui initialisation boilerplate into four calls:

```odin
import imrefl      "path/to/imreflect"
import bootstrap   "path/to/imreflect/bootstrap"

main :: proc() {
    if !bootstrap.init() {
        return
    }
    defer bootstrap.shutdown()

    my_data: My_Struct
    // ... populate my_data ...

    for bootstrap.start_frame("Inspector") {
        imrefl.draw_value("my_data", my_data)
        bootstrap.end_frame() // Calls free_all(context.temp_allocator)
    }
}
```

> **Note:** The bootstrap package is intentionally minimal — it is designed for quick inspection and demos. For production use you will want to manage your own window, context, and render loop.

### Full Example

The `demo` package exercises nearly every supported type using the bootstrap package. See [`demo/demo.odin`](demo/demo.odin) for the full source.

To run the demo yourself:

```sh
odin run demo
```

---

## Known Limitations & TODOs

- **Bit fields** — fields are located correctly but might not show correct values and should not be edited.
- **`f16` / `complex32` / `quaternion64`** — not yet supported due to ImGui having no native f16 scalar type.
- **128-bit types** — not yet supported due to ImGui having no native 128-bit scalar type.
- **Multi-pointers (`[^]T`)** — length information is not available via reflection, so only the raw address is shown. A future struct tag may be able to annotate a length.
- **Enumerated arrays** — tree node is rendered but element iteration is not yet implemented.
- **SOA pointers** — tree node renders but no data is displayed.
- **Struct tags** — only `read-only` is currently recognised. Planned expansion to support things like value ranges, custom labels, and more.
- **Endian-specific integers** (`i16le`, `u32be`, etc.) — mapped through `type_id_to_data_type` conservatively; display may not account for byte-swapping on big-endian hosts.
- **Procedures** — only the function pointer address is shown. Invoking procedures via struct tags is a possible future feature.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

Copyright (c) 2026 Alex Davis
