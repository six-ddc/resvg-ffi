#!/usr/bin/env lua
-- Node operations example - demonstrating how to work with specific SVG nodes

-- Add lua directory to package path
package.path = package.path .. ";../../lua/?.lua"

local resvg = require("resvg")

-- Initialize
resvg.init_log()

-- Create options
local opts = resvg.Options.new()
opts:load_system_fonts()

-- Load SVG
local tree, err = resvg.Tree.from_file("test.svg", opts)
if not tree then
    print("Error loading SVG: " .. err)
    os.exit(1)
end

print("SVG loaded successfully")
print("=====================================")

-- Get overall info
local size = tree:get_size()
print(string.format("Image size: %.0fx%.0f", size.width, size.height))

local bbox = tree:get_bbox()
if bbox then
    print(string.format("Image bbox: x=%.2f, y=%.2f, w=%.2f, h=%.2f",
        bbox.x, bbox.y, bbox.width, bbox.height))
end

print("\nNode Operations:")
print("=====================================")

-- Test node ID list
local node_ids = {"circle1", "rect1", "triangle1", "not_exists"}

for _, id in ipairs(node_ids) do
    print(string.format("\nChecking node '%s':", id))
    
    if tree:node_exists(id) then
        print("  ✓ Node exists")
        
    -- Get node transform
        local transform = tree:get_node_transform(id)
        if transform then
            print(string.format("  Transform: [%.2f, %.2f, %.2f, %.2f, %.2f, %.2f]",
                transform.a, transform.b, transform.c, 
                transform.d, transform.e, transform.f))
        end
        
    -- Get node bounding box
        local node_bbox = tree:get_node_bbox(id)
        if node_bbox then
            print(string.format("  Bbox: x=%.2f, y=%.2f, w=%.2f, h=%.2f",
                node_bbox.x, node_bbox.y, node_bbox.width, node_bbox.height))
        end
        
    -- Get stroke-inclusive bounding box
        local stroke_bbox = tree:get_node_stroke_bbox(id)
        if stroke_bbox then
            print(string.format("  Stroke bbox: x=%.2f, y=%.2f, w=%.2f, h=%.2f",
                stroke_bbox.x, stroke_bbox.y, stroke_bbox.width, stroke_bbox.height))
        end
        
    -- Render single node
        if node_bbox and node_bbox.width > 0 and node_bbox.height > 0 then
            local pixmap = tree:render_node(id, 
                math.ceil(node_bbox.width), 
                math.ceil(node_bbox.height))
            
            if pixmap then
                local output_file = string.format("node_%s.raw", id)
                local file = io.open(output_file, "wb")
                if file then
                    file:write(pixmap:get_data())
                    file:close()
                    print(string.format("  Rendered to: %s", output_file))
                end
            else
                print("  Failed to render node")
            end
        end
    else
        print("  ✗ Node does not exist")
    end
end

print("\nTransform Operations:")
print("=====================================")

-- Create various transforms
local transforms = {
    { name = "Identity", transform = resvg.Transform.identity() },
    { name = "Translate(10, 20)", transform = resvg.Transform.translate(10, 20) },
    { name = "Scale(2)", transform = resvg.Transform.scale(2) },
    { name = "Scale(2, 3)", transform = resvg.Transform.scale(2, 3) },
    { name = "Rotate(45°)", transform = resvg.Transform.rotate(45) },
    { name = "Rotate(30°, 100, 100)", transform = resvg.Transform.rotate(30, 100, 100) },
}

for _, t in ipairs(transforms) do
    local matrix = t.transform:to_table()
    print(string.format("%s:", t.name))
    print(string.format("  Matrix: [%.2f, %.2f, %.2f, %.2f, %.2f, %.2f]",
        matrix.a, matrix.b, matrix.c, matrix.d, matrix.e, matrix.f))
end

-- Combine transforms
print("\nCombined Transform:")
local t1 = resvg.Transform.translate(50, 50)
local t2 = resvg.Transform.rotate(45)
local t3 = resvg.Transform.scale(1.5)

local combined = t1:multiply(t2):multiply(t3)
local matrix = combined:to_table()
print(string.format("  Translate(50,50) * Rotate(45°) * Scale(1.5)"))
print(string.format("  Result: [%.2f, %.2f, %.2f, %.2f, %.2f, %.2f]",
    matrix.a, matrix.b, matrix.c, matrix.d, matrix.e, matrix.f))

print("\nDone!")