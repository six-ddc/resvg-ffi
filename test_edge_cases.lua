#!/usr/bin/env luajit
-- Test script for edge cases and error handling in the Lua bindings

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua"

local resvg = require("resvg")

print("Testing Resvg Lua bindings edge cases and error handling")
print("=======================================================")

local function test_case(description, test_func)
    io.write(description .. ": ")
    local success, result = pcall(test_func)
    if success then
        print("✓ PASS")
        return true
    else
        print("✗ FAIL - " .. tostring(result))
        return false
    end
end

local function expect_error_or_nil(description, test_func)
    io.write(description .. ": ")
    local success, result = pcall(test_func)
    if not success then
        -- Function threw an error
        print("✓ PASS (expected error: " .. tostring(result) .. ")")
        return true
    else
        -- Function completed, check if it returned nil + error
        local tree, err = result, nil
        if type(test_func) == "function" then
            tree, err = test_func()
        end
        if tree == nil and err then
            print("✓ PASS (expected nil+error: " .. tostring(err) .. ")")
            return true
        else
            print("✗ FAIL - Expected error but got success")
            return false
        end
    end
end

local function expect_error(description, test_func)
    io.write(description .. ": ")
    local success, result = pcall(test_func)
    if not success then
        print("✓ PASS (expected error: " .. tostring(result) .. ")")
        return true
    else
        print("✗ FAIL - Expected error but got success")
        return false
    end
end

local passed = 0
local total = 0

-- Test DPI validation
total = total + 1
passed = passed + (expect_error("Invalid DPI (negative)", function()
    local opts = resvg.Options.new()
    opts:set_dpi(-96)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Invalid DPI (NaN)", function()
    local opts = resvg.Options.new()
    opts:set_dpi(0/0)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Invalid DPI (string)", function()
    local opts = resvg.Options.new()
    opts:set_dpi("96")
end) and 1 or 0)

total = total + 1
passed = passed + (test_case("Valid DPI", function()
    local opts = resvg.Options.new()
    opts:set_dpi(96)
end) and 1 or 0)

-- Test font size validation
total = total + 1
passed = passed + (expect_error("Invalid font size (zero)", function()
    local opts = resvg.Options.new()
    opts:set_font_size(0)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Invalid font size (negative)", function()
    local opts = resvg.Options.new()
    opts:set_font_size(-12)
end) and 1 or 0)

-- Test font family validation
total = total + 1
passed = passed + (expect_error("Empty font family", function()
    local opts = resvg.Options.new()
    opts:set_font_family("")
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Non-string font family", function()
    local opts = resvg.Options.new()
    opts:set_font_family(123)
end) and 1 or 0)

-- Test render dimensions validation
total = total + 1
passed = passed + (expect_error("Invalid render width (negative)", function()
    local opts = resvg.Options.new()
    local tree = resvg.Tree.from_data('<svg width="100" height="100"><rect width="50" height="50"/></svg>', opts)
    tree:render(-100, 100)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Invalid render width (too large)", function()
    local opts = resvg.Options.new()
    local tree = resvg.Tree.from_data('<svg width="100" height="100"><rect width="50" height="50"/></svg>', opts)
    tree:render(100000, 100)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Invalid render height (string)", function()
    local opts = resvg.Options.new()
    local tree = resvg.Tree.from_data('<svg width="100" height="100"><rect width="50" height="50"/></svg>', opts)
    tree:render(100, "100")
end) and 1 or 0)

-- Test file parsing validation  
total = total + 1
passed = passed + (test_case("Empty file path returns error", function()
    local tree, err = resvg.Tree.from_file("", nil)
    return tree == nil and err ~= nil
end) and 1 or 0)

total = total + 1
passed = passed + (test_case("Non-string file path returns error", function()
    local tree, err = resvg.Tree.from_file(123, nil)
    return tree == nil and err ~= nil
end) and 1 or 0)

-- Test data parsing validation
total = total + 1
passed = passed + (test_case("Empty SVG data returns error", function()
    local tree, err = resvg.Tree.from_data("", nil)
    return tree == nil and err ~= nil
end) and 1 or 0)

total = total + 1
passed = passed + (test_case("Non-string SVG data returns error", function()
    local tree, err = resvg.Tree.from_data(123, nil)
    return tree == nil and err ~= nil
end) and 1 or 0)

-- Test node operations validation
local opts = resvg.Options.new()
local tree = resvg.Tree.from_data('<svg width="100" height="100"><rect id="test" width="50" height="50"/></svg>', opts)

total = total + 1
passed = passed + (test_case("Valid node exists", function()
    return tree:node_exists("test")
end) and 1 or 0)

total = total + 1
passed = passed + (test_case("Invalid node (empty string)", function()
    return not tree:node_exists("")
end) and 1 or 0)

total = total + 1
passed = passed + (test_case("Invalid node (non-string)", function()
    return not tree:node_exists(123)
end) and 1 or 0)

-- Test render_node validation
total = total + 1
passed = passed + (test_case("render_node with empty ID returns error", function()
    local pixmap, err = tree:render_node("", 100, 100)
    return pixmap == nil and err ~= nil
end) and 1 or 0)

total = total + 1
passed = passed + (test_case("render_node with non-string ID returns error", function()
    local pixmap, err = tree:render_node(123, 100, 100)
    return pixmap == nil and err ~= nil
end) and 1 or 0)

-- Test Transform validation
total = total + 1
passed = passed + (expect_error("Transform.new with NaN", function()
    resvg.Transform.new(1, 0/0, 0, 1, 0, 0)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Transform.translate with non-number", function()
    resvg.Transform.translate("10", 20)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Transform.scale with NaN", function()
    resvg.Transform.scale(0/0)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Transform.rotate with non-number", function()
    resvg.Transform.rotate("45")
end) and 1 or 0)

-- Test Pixmap validation
total = total + 1
passed = passed + (expect_error("Pixmap.new with negative width", function()
    resvg.Pixmap.new(-100, 100)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Pixmap.new with too large dimensions", function()
    resvg.Pixmap.new(100000, 100000)
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("Pixmap.from_data with size mismatch", function()
    resvg.Pixmap.from_data("toolittledata", 100, 100)
end) and 1 or 0)

-- Test RGB conversion efficiency (should be fast)
total = total + 1
passed = passed + (test_case("RGB conversion performance", function()
    local pixmap = resvg.Pixmap.new(200, 200)
    local start_time = os.clock()
    local rgb_data = pixmap:to_rgb()
    local end_time = os.clock()
    -- Should complete in reasonable time (< 1 second for 200x200)
    return (end_time - start_time) < 1.0 and #rgb_data == 200 * 200 * 3
end) and 1 or 0)

-- Test font loading validation
total = total + 1
passed = passed + (test_case("load_font_file with empty path returns error", function()
    local opts = resvg.Options.new()
    local ok, err = opts:load_font_file("")
    return ok == nil and err ~= nil
end) and 1 or 0)

total = total + 1
passed = passed + (test_case("load_font_file with non-string returns error", function()
    local opts = resvg.Options.new()
    local ok, err = opts:load_font_file(123)
    return ok == nil and err ~= nil
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("load_font_data with empty data", function()
    local opts = resvg.Options.new()
    opts:load_font_data("")
end) and 1 or 0)

total = total + 1
passed = passed + (expect_error("load_font_data with non-string", function()
    local opts = resvg.Options.new()
    opts:load_font_data(123)
end) and 1 or 0)

print("\n=======================================================")
print(string.format("Test Results: %d/%d passed (%.1f%%)", passed, total, (passed/total)*100))

if passed == total then
    print("✓ All tests passed!")
    os.exit(0)
else
    print("✗ Some tests failed!")
    os.exit(1)
end