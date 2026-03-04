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

## Features

ImReflect supports the full breadth of the Odin type system:

(TODO: replace description with images)
| Category | Types |
|---|---|
| **Integers** | `i8`, `u8`, `i16`, `u16`, `i32`, `u32`, `i64`, `u64`, `int`, `uint`, `uintptr`, `rune`, and all `le`/`be` variants |
| **Floats** | `f32`, `f64` |
| **Booleans** | `bool`, `b8`, `b16`, `b32`, `b64` |
| **Strings** | `string`, `string16`, `cstring`, `cstring16` |
| **Complex** | `complex64`, `complex128` |
| **Quaternions** | `quaternion128`, `quaternion256` |
| **Enums** | Rendered as a dropdown combo box with all named values |
| **Bit Sets** | Each flag rendered as an interactive checkbox |
| **Bit Fields** | Expanded as a tree of their constituent fields |
| **Structs** | Recursively expanded as a collapsible tree node |
| **Unions** | Shows the active variant tag and recursively renders its data |
| **Raw Unions** | Expanded as a tree node |
| **Pointers** | Shows the pointer address; typed pointers are recursively followed and their pointee is rendered |
| **`any`** | Shows the `typeid` and recursively renders the contained value |
| **`typeid`** | Displays the type name as text |
| **Arrays** | Expanded as indexed tree nodes |
| **Slices** | Expanded as indexed tree nodes |
| **Dynamic Arrays** | Expanded as indexed tree nodes |
| **Enumerated Arrays** | Expanded as a tree node |
| **Multi-Pointers** | Displays the raw pointer address |
| **Maps** | Expanded as indexed tree nodes, each showing key and value |
| **Matrices** | Rendered as a grid of scalar input fields |
| **SIMD Vectors** | Expanded as indexed tree nodes |
| **SOA Pointers** | Expanded as a tree node |
| **Procedures** | Displays the procedure's address |
| **Named types** | Transparently unwrapped to their base type |

All scalar fields (integers, floats, booleans, enums, bit sets) are **editable live** — changes are written directly back to the original data.

---

## Getting Started

### Prerequisites

- [Odin compiler](https://odin-lang.org/docs/install/)
- A working Dear ImGui setup. I maintain the bundled `imgui` package [here](https://github.com/xandaron/odin-dear-imgui) where a vulkan backend can be found.

### Installation

Clone the repository into your project or alongside your packages:

```sh
git clone https://github.com/your-username/Odin-ImReflect
```

Then import the package from your code:

```odin
import imrefl "path/to/imreflect"
```

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
        bootstrap.end_frame()
    }
}
```

| Procedure | Description |
|---|---|
| `init(allocator?)` | Initialises GLFW, creates a 700×700 window, and sets up ImGui with the OpenGL3 backend. Returns `false` on failure. |
| `shutdown()` | Tears down ImGui, the OpenGL3 backend, GLFW, and destroys the window. |
| `start_frame(ui_name)` | Polls events, begins a new ImGui frame, and opens a window with the given name. Returns `false` when the window should close — use it directly as your loop condition. |
| `end_frame()` | Renders the frame, swaps buffers, and flushes the temp allocator. |

> **Note:** The bootstrap package is intentionally minimal — it is designed for quick inspection and demos. For production use you will want to manage your own window, context, and render loop.

### Full Example

The `demo` package exercises nearly every supported type using the bootstrap package:

```odin
import imrefl    "../imreflect"
import bootstrap "../imreflect/bootstrap"

My_Struct :: struct {
    str:       string,
    int32:     i32,
    float:     f32,
    bool:      bool,
    enumValue: My_Enum,
    bits:      My_Bit_Set,
    uni:       My_Union,
    mat:       matrix[4,4]f32,
    mapp:      map[int]string,
    slice:     []int,
    dynArr:    [dynamic]int,
    simd:      #simd[4]int,
    fn:        My_Proc,
    // ...and more
}

main :: proc() {
    if !bootstrap.init() do return
    defer bootstrap.shutdown()

    test: My_Struct
    // ... populate test ...

    for bootstrap.start_frame("Demo") {
        imrefl.draw_value("test", test)
        bootstrap.end_frame()
    }
}
```

To run the demo yourself:

```sh
odin run demo
```

---

## Project Structure

```
Odin-ImReflect/
├── imreflect/
│   ├── imreflect.odin       # Core package — draw_value and all type handlers
│   └── bootstrap/
│       └── bootstrap.odin   # Optional quick-start package (GLFW + OpenGL3 + ImGui setup)
├── imgui/
│   ├── dcimgui.odin         # Dear ImGui bindings (auto-generated by dear_bindings)
│   ├── glfw/                # GLFW backend
│   ├── opengl3/             # OpenGL3 backend
│   └── ...                  # Supporting types and lib
└── demo/
    └── demo.odin            # Full runnable demo application
```

---

## Known Limitations & TODOs

- **Bit fields** — fields are located correctly but might not show correct values and should not be edited.
- **`f16` / `complex32` / `quaternion64`** — not yet supported due to ImGui having no native f16 scalar type.
- **Multi-pointers (`[^]T`)** — length information is not available via reflection, so only the raw address is shown. A future struct tag may be able to annotate a length.
- **Enumerated arrays** — tree node is rendered but element iteration is not yet implemented.
- **SOA pointers** — tree node renders but data is not yet walked.
- **Struct tags** — the `flags_from_field_tag` hook exists and is wired up, but no tags are acted on yet. This is the intended extension point for future per-field customisation (e.g. ranges, read-only, custom labels).
- **Endian-specific integers** (`i16le`, `u32be`, etc.) — mapped through `type_id_to_data_type` conservatively; display may not account for byte-swapping on big-endian hosts.
- **Procedures** — only the function pointer address is shown. Invoking procedures via struct tags is a possible future feature.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

Copyright (c) 2026 Alex Davis