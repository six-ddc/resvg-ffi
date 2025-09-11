# resvg-lua-ffi

Lightning-fast SVG rendering for Lua applications

A high-performance LuaJIT FFI binding for [resvg](https://github.com/RazrFalcon/resvg), providing native-speed SVG rendering capabilities to Lua applications.

## Features

- **High Performance**: Direct FFI bindings to resvg's C API for native rendering speed
- **Complete SVG Support**: Full SVG 1.1 and SVG 2 support through resvg
- **Cross-platform**: Works on Windows, macOS, Linux, and Android
- **Pure Lua**: No C compilation required for Lua code, just the prebuilt resvg library
- **Comprehensive API**: Full access to resvg's rendering, transformation, and node manipulation features
- **LSP Support**: Fully annotated with LuaDoc comments for excellent IDE integration

## Requirements

- LuaJIT 2.0+ or Lua 5.1+ with FFI support
- Prebuilt resvg dynamic library (included for major platforms)

## Installation

### Using the Prebuilt Libraries

Prebuilt libraries are included for common platforms:
- macOS (x86_64, aarch64)
- Linux (x86_64, aarch64)
- Android (armv7, aarch64, x86_64)

Simply copy the appropriate library from `prebuilt/` to your project directory or system library path.

### Building from Source

To build the resvg C library from source:

```sh
cargo build --release
```

This will produce dynamic libraries in `target/release/`.

## Quick Start

```lua
local resvg = require("resvg")

-- Initialize logging (optional)
resvg.init_log()

-- Create options with custom settings
local options = resvg.Options.new()
    :set_dpi(96)
    :load_system_fonts()

-- Load and render SVG
local tree = resvg.parse_file("example.svg", options)
if tree then
    local size = tree:get_size()
    local pixmap = tree:render(size.width, size.height)
    
    -- Get raw RGBA data
    local rgba_data = pixmap:get_data()
    
    -- Or convert to other formats
    local rgb_data = pixmap:to_rgb()
    local bgra_data = pixmap:to_bgra()
end
```

## API Overview

### Options

Configure SVG parsing and rendering behavior:

```lua
local options = resvg.Options.new()
    :set_resources_dir("/path/to/resources")
    :set_dpi(96)
    :set_font_family("Arial")
    :set_font_size(12)
    :load_system_fonts()
```

### Tree

Parse and manipulate SVG documents:

```lua
-- Parse from file
local tree = resvg.Tree.from_file("image.svg", options)

-- Parse from string
local svg_data = '<svg>...</svg>'
local tree = resvg.Tree.from_data(svg_data, options)

-- Query tree properties
local size = tree:get_size()           -- Get viewbox size
local bbox = tree:get_bbox()           -- Get bounding box
local is_empty = tree:is_empty()       -- Check if tree has nodes

-- Work with nodes
if tree:node_exists("node-id") then
    local transform = tree:get_node_transform("node-id")
    local bbox = tree:get_node_bbox("node-id")
end
```

### Rendering

Render SVG to pixel buffer:

```lua
-- Basic rendering
local pixmap = tree:render(800, 600)

-- Render with transform
local transform = resvg.Transform.scale(2, 2)
local pixmap = tree:render(800, 600, transform)

-- Render specific node
local pixmap = tree:render_node("node-id", 400, 300)
```

### Transform

Create and compose 2D transformations:

```lua
-- Create transforms
local t1 = resvg.Transform.identity()
local t2 = resvg.Transform.translate(100, 50)
local t3 = resvg.Transform.scale(2, 2)
local t4 = resvg.Transform.rotate(45, 0, 0)  -- angle, cx, cy

-- Compose transforms
local combined = t2:multiply(t3)

-- Create from matrix values
local custom = resvg.Transform.new(1, 0, 0, 1, 10, 20)
```

### Pixmap

Manage rendered pixel data:

```lua
-- Create pixmap
local pixmap = resvg.Pixmap.new(800, 600)

-- Get dimensions
local width = pixmap.width
local height = pixmap.height

-- Export pixel data
local rgba = pixmap:get_data()  -- RGBA format
local rgb = pixmap:to_rgb()     -- RGB format (no alpha)
local bgra = pixmap:to_bgra()   -- BGRA format
```

## Examples

Check the `examples/` directory for complete examples:
- `examples/lua/basic.lua` - Basic SVG rendering
- `examples/lua/transform.lua` - Using transformations
- `examples/lua/node.lua` - Rendering specific nodes

## Platform Support

| Platform | Architecture | Library File |
|----------|-------------|--------------|
| macOS | x86_64 | `libresvg.dylib` |
| macOS | aarch64 (M1/M2) | `libresvg.dylib` |
| Linux | x86_64 | `libresvg.so` |
| Linux | aarch64 | `libresvg.so` |
| Android | armv7 | `libresvg.so` |
| Android | aarch64 | `libresvg.so` |
| Android | x86_64 | `libresvg.so` |

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.

## Contribution

Contributions are welcome by pull request.
The [Rust code of conduct] applies.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.

[Rust Code of Conduct]: https://www.rust-lang.org/policies/code-of-conduct
