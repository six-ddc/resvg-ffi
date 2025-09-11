#!/usr/bin/env lua
-- Basic resvg Lua binding example

-- Add lua directory to package path
package.path = package.path .. ";../../lua/?.lua"

local resvg = require("resvg")

-- Initialize logging system
resvg.init_log()

-- Print version information
local version = resvg.version()
print(string.format("Resvg version: %s", version.string))

-- Create render options
local opts = resvg.Options.new()
opts:set_dpi(96)
opts:set_font_family("Arial")
opts:set_font_size(12)
opts:load_system_fonts()

-- Parse SVG file
local svg_file = arg[1] or "test.svg"
local output_file = arg[2] or "output.raw"

print("Loading SVG file: " .. svg_file)
local tree, err = resvg.Tree.from_file(svg_file, opts)

if not tree then
    print("Error loading SVG: " .. err)
    os.exit(1)
end

-- Check if tree is empty
if tree:is_empty() then
    print("Warning: SVG is empty")
end

-- Get image size
local size = tree:get_size()
print(string.format("Image size: %dx%d", size.width, size.height))

-- Get bounding box
local bbox = tree:get_bbox()
if bbox then
    print(string.format("Bounding box: x=%.2f, y=%.2f, w=%.2f, h=%.2f",
        bbox.x, bbox.y, bbox.width, bbox.height))
end

-- Create identity transform
local transform = resvg.Transform.identity()

-- Render to pixmap
print("Rendering...")
local pixmap = tree:render(size.width, size.height, transform)

if pixmap then
    -- Get raw RGBA data
    local data = pixmap:get_data()
    print(string.format("Rendered %d bytes of pixel data", #data))
    
    -- Save to file (raw RGBA format)
    local file = io.open(output_file, "wb")
    if file then
        file:write(data)
        file:close()
        print("Saved raw pixel data to: " .. output_file)
        print("Note: This is raw RGBA data. Use an image viewer that supports raw format or convert to PNG.")
    end
else
    print("Failed to render")
end

print("Done!")