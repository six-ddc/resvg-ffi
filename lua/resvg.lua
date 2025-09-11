--- Resvg Lua FFI bindings
--- Provides Lua interface for SVG rendering functionality
--- @module 'resvg'

local ffi = require("ffi")
local ffi_defs = require("ffi_defs")
local utils = require("utils")

--- Load the dynamic library
local C = utils.load_library()

--- Main module table
--- @table M
local M = {
    _VERSION = "0.1.0",
    _DESCRIPTION = "Lua bindings for resvg",
}

--- Initializes the library log
--- Use it if you want to see any warnings
--- Must be called only once
--- All warnings will be printed to stderr
--- @function init_log
function M.init_log()
    C.resvg_init_log()
end

--- Returns version information
--- Version is hardcoded to match the library build
--- @return table Version information with major, minor, patch and string fields
--- @function version
function M.version()
    return {
        major = 0,
        minor = 45,
        patch = 1,
        string = "0.45.1"
    }
end

--- Options class for SVG to render tree conversion
--- @class Options
local Options = {}
Options.__index = Options

--- Creates a new Options object
--- @return Options A new Options instance with default settings
--- @function Options.new
function Options.new()
    local self = setmetatable({}, Options)
    self.ptr = ffi.gc(C.resvg_options_create(), C.resvg_options_destroy)
    return self
end

--- Sets a directory that will be used during relative paths resolving
--- Expected to be the same as the directory that contains the SVG file
--- @param path string|nil UTF-8 path to the resources directory, can be nil
--- @return Options Self for method chaining
--- @function Options:set_resources_dir
function Options:set_resources_dir(path)
    C.resvg_options_set_resources_dir(self.ptr, path)
    return self
end

--- Sets the target DPI
--- Impacts units conversion
--- @param dpi number Target DPI value (default: 96)
--- @return Options Self for method chaining
--- @function Options:set_dpi
function Options:set_dpi(dpi)
    if type(dpi) ~= "number" or dpi <= 0 or dpi ~= dpi then -- Check for NaN
        error("DPI must be a positive number", 2)
    end
    C.resvg_options_set_dpi(self.ptr, dpi)
    return self
end

--- Provides the content of a stylesheet that will be used when resolving CSS attributes
--- @param content string|nil UTF-8 CSS content, can be nil
--- @return Options Self for method chaining
--- @function Options:set_stylesheet
function Options:set_stylesheet(content)
    C.resvg_options_set_stylesheet(self.ptr, content)
    return self
end

--- Sets the default font family
--- Will be used when no font-family attribute is set in the SVG
--- @param family string UTF-8 font family name (default: Times New Roman)
--- @return Options Self for method chaining
--- @function Options:set_font_family
function Options:set_font_family(family)
    if type(family) ~= "string" then
        error("Font family must be a string", 2)
    end
    if family == "" then
        error("Font family cannot be empty", 2)
    end
    C.resvg_options_set_font_family(self.ptr, family)
    return self
end

--- Sets the default font size
--- Will be used when no font-size attribute is set in the SVG
--- @param size number Font size in pixels (default: 12)
--- @return Options Self for method chaining
--- @function Options:set_font_size
function Options:set_font_size(size)
    if type(size) ~= "number" or size <= 0 or size ~= size then -- Check for NaN
        error("Font size must be a positive number", 2)
    end
    C.resvg_options_set_font_size(self.ptr, size)
    return self
end

--- Sets the serif font family
--- Has no effect when the text feature is not enabled
--- @param family string UTF-8 font family name (default: Times New Roman)
--- @return Options Self for method chaining
--- @function Options:set_serif_family
function Options:set_serif_family(family)
    C.resvg_options_set_serif_family(self.ptr, family)
    return self
end

--- Sets the sans-serif font family
--- Has no effect when the text feature is not enabled
--- @param family string UTF-8 font family name (default: Arial)
--- @return Options Self for method chaining
--- @function Options:set_sans_serif_family
function Options:set_sans_serif_family(family)
    C.resvg_options_set_sans_serif_family(self.ptr, family)
    return self
end

--- Sets the cursive font family
--- Has no effect when the text feature is not enabled
--- @param family string UTF-8 font family name (default: Comic Sans MS)
--- @return Options Self for method chaining
--- @function Options:set_cursive_family
function Options:set_cursive_family(family)
    C.resvg_options_set_cursive_family(self.ptr, family)
    return self
end

--- Sets the fantasy font family
--- Has no effect when the text feature is not enabled
--- @param family string UTF-8 font family name (default: Papyrus on macOS, Impact on other OS)
--- @return Options Self for method chaining
--- @function Options:set_fantasy_family
function Options:set_fantasy_family(family)
    C.resvg_options_set_fantasy_family(self.ptr, family)
    return self
end

--- Sets the monospace font family
--- Has no effect when the text feature is not enabled
--- @param family string UTF-8 font family name (default: Courier New)
--- @return Options Self for method chaining
--- @function Options:set_monospace_family
function Options:set_monospace_family(family)
    C.resvg_options_set_monospace_family(self.ptr, family)
    return self
end

--- Sets a comma-separated list of languages
--- Will be used to resolve a systemLanguage conditional attribute
--- Example: en,en-US
--- @param languages string|nil UTF-8 language list, can be nil (default: en)
--- @return Options Self for method chaining
--- @function Options:set_languages
function Options:set_languages(languages)
    C.resvg_options_set_languages(self.ptr, languages)
    return self
end

--- Sets the default shape rendering method
--- Will be used when an SVG element's shape-rendering property is set to auto
--- @param mode string|number Rendering mode: "optimize_speed", "crisp_edges", or "geometric_precision" (default)
--- @return Options Self for method chaining
--- @function Options:set_shape_rendering
function Options:set_shape_rendering(mode)
    local mode_value = utils.get_shape_rendering_mode(mode)
    C.resvg_options_set_shape_rendering_mode(self.ptr, mode_value)
    return self
end

--- Sets the default text rendering method
--- Will be used when an SVG element's text-rendering property is set to auto
--- @param mode string|number Rendering mode: "optimize_speed", "optimize_legibility" (default), or "geometric_precision"
--- @return Options Self for method chaining
--- @function Options:set_text_rendering
function Options:set_text_rendering(mode)
    local mode_value = utils.get_text_rendering_mode(mode)
    C.resvg_options_set_text_rendering_mode(self.ptr, mode_value)
    return self
end

--- Sets the default image rendering method
--- Will be used when an SVG element's image-rendering property is set to auto
--- @param mode string|number Rendering mode: "optimize_quality" (default) or "optimize_speed"
--- @return Options Self for method chaining
--- @function Options:set_image_rendering
function Options:set_image_rendering(mode)
    local mode_value = utils.get_image_rendering_mode(mode)
    C.resvg_options_set_image_rendering_mode(self.ptr, mode_value)
    return self
end

--- Loads a font data into the internal fonts database
--- Prints a warning into the log when the data is not a valid TrueType font
--- Has no effect when the text feature is not enabled
--- @param data string Font data as binary string
--- @return Options Self for method chaining
--- @function Options:load_font_data
function Options:load_font_data(data)
    if type(data) ~= "string" then
        error("Font data must be a string", 2)
    end
    if #data == 0 then
        error("Font data cannot be empty", 2)
    end
    -- Use the actual byte length, not string length which might be wrong for binary data
    local data_len = #data
    C.resvg_options_load_font_data(self.ptr, data, data_len)
    return self
end

--- Loads a font file into the internal fonts database
--- Prints a warning into the log when the data is not a valid TrueType font
--- Has no effect when the text feature is not enabled
--- @param filepath string UTF-8 path to the font file
--- @return boolean|nil true on success, nil on error
--- @return string|nil Error message if failed
--- @function Options:load_font_file
function Options:load_font_file(filepath)
    if type(filepath) ~= "string" then
        return nil, "File path must be a string"
    end
    if filepath == "" then
        return nil, "File path cannot be empty"
    end
    local code = C.resvg_options_load_font_file(self.ptr, filepath)
    return utils.check_error(code)
end

--- Loads system fonts into the internal fonts database
--- This method is very IO intensive
--- This method should be executed only once per Options object
--- The system scanning is not perfect, so some fonts may be omitted
--- Prints warnings into the log
--- Has no effect when the text feature is not enabled
--- @return Options Self for method chaining
--- @function Options:load_system_fonts
function Options:load_system_fonts()
    C.resvg_options_load_system_fonts(self.ptr)
    return self
end

--- Tree class representing a parsed SVG render tree
--- @class Tree
local Tree = {}
Tree.__index = Tree

--- Creates render tree from SVG file
--- Supports .svg and .svgz files
--- @param filepath string UTF-8 path to the SVG file
--- @param options Options|nil Rendering options (uses defaults if nil)
--- @return Tree|nil Parsed render tree on success, nil on error
--- @return string|nil Error message if failed
--- @function Tree.from_file
function Tree.from_file(filepath, options)
    if type(filepath) ~= "string" then
        return nil, "File path must be a string"
    end
    if filepath == "" then
        return nil, "File path cannot be empty"
    end
    
    local opt_ptr = options and options.ptr or Options.new().ptr
    local tree_ptr = ffi.new("resvg_render_tree*[1]")
    local code = C.resvg_parse_tree_from_file(filepath, opt_ptr, tree_ptr)

    if code ~= 0 then
        return nil, utils.get_error_message(code)
    end

    local self = setmetatable({}, Tree)
    self.ptr = ffi.gc(tree_ptr[0], C.resvg_tree_destroy)
    return self
end

--- Creates render tree from SVG data
--- Can contain SVG string or gzip compressed data
--- @param data string SVG data
--- @param options Options|nil Rendering options (uses defaults if nil)
--- @return Tree|nil Parsed render tree on success, nil on error
--- @return string|nil Error message if failed
--- @function Tree.from_data
function Tree.from_data(data, options)
    if type(data) ~= "string" then
        return nil, "SVG data must be a string"
    end
    if #data == 0 then
        return nil, "SVG data cannot be empty"
    end
    
    local opt_ptr = options and options.ptr or Options.new().ptr
    local tree_ptr = ffi.new("resvg_render_tree*[1]")
    local code = C.resvg_parse_tree_from_data(data, #data, opt_ptr, tree_ptr)

    if code ~= 0 then
        return nil, utils.get_error_message(code)
    end

    local self = setmetatable({}, Tree)
    self.ptr = ffi.gc(tree_ptr[0], C.resvg_tree_destroy)
    return self
end

--- Checks that tree has any nodes
--- @return boolean Returns true if tree has no nodes
--- @function Tree:is_empty
function Tree:is_empty()
    return C.resvg_is_image_empty(self.ptr)
end

--- Returns an image size
--- The size of an image that is required to render this SVG
--- Note that elements outside the viewbox will be clipped
--- If you want to render the whole SVG content, use get_bbox instead
--- @return table Size table with width and height fields
--- @function Tree:get_size
function Tree:get_size()
    local size = C.resvg_get_image_size(self.ptr)
    return utils.size_to_table(size)
end

--- Returns an object bounding box
--- This bounding box does not include objects stroke and filter regions
--- This is what SVG calls "absolute object bounding box"
--- If you're looking for a "complete" bounding box see get_bbox
--- @return table|nil Bounding box table with x, y, width, height fields, or nil if image has no elements
--- @function Tree:get_object_bbox
function Tree:get_object_bbox()
    local bbox = ffi.new("resvg_rect")
    local success = C.resvg_get_object_bbox(self.ptr, bbox)
    if success then
        return utils.rect_to_table(bbox)
    end
    return nil
end

--- Returns an image bounding box
--- This bounding box contains the maximum SVG dimensions
--- Its size can be bigger or smaller than get_size
--- Use it when you want to avoid clipping of elements that are outside the SVG viewbox
--- @return table|nil Bounding box table with x, y, width, height fields, or nil if image has no elements
--- @function Tree:get_bbox
function Tree:get_bbox()
    local bbox = ffi.new("resvg_rect")
    local success = C.resvg_get_image_bbox(self.ptr, bbox)
    if success then
        return utils.rect_to_table(bbox)
    end
    return nil
end

--- Returns true if a renderable node with such an ID exists
--- @param id string Node's ID (UTF-8 string)
--- @return boolean true if node exists and is renderable, false otherwise
--- @function Tree:node_exists
function Tree:node_exists(id)
    if type(id) ~= "string" then
        return false
    end
    if id == "" then
        return false
    end
    return C.resvg_node_exists(self.ptr, id)
end

--- Returns node's transform by ID
--- @param id string Node's ID (UTF-8 string)
--- @return table|nil Transform table with a,b,c,d,e,f fields, or nil if node doesn't exist or isn't renderable
--- @function Tree:get_node_transform
function Tree:get_node_transform(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    local transform = ffi.new("resvg_transform")
    local success = C.resvg_get_node_transform(self.ptr, id, transform)
    if success then
        return utils.transform_to_table(transform)
    end
    return nil
end

--- Returns node's bounding box in canvas coordinates by ID
--- @param id string Node's ID (UTF-8 string)
--- @return table|nil Bounding box table with x, y, width, height fields, or nil if node doesn't exist
--- @function Tree:get_node_bbox
function Tree:get_node_bbox(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    local bbox = ffi.new("resvg_rect")
    local success = C.resvg_get_node_bbox(self.ptr, id, bbox)
    if success then
        return utils.rect_to_table(bbox)
    end
    return nil
end

--- Returns node's bounding box, including stroke, in canvas coordinates by ID
--- @param id string Node's ID (UTF-8 string)
--- @return table|nil Bounding box table with x, y, width, height fields, or nil if node doesn't exist
--- @function Tree:get_node_stroke_bbox
function Tree:get_node_stroke_bbox(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    local bbox = ffi.new("resvg_rect")
    local success = C.resvg_get_node_stroke_bbox(self.ptr, id, bbox)
    if success then
        return utils.rect_to_table(bbox)
    end
    return nil
end

--- Renders the render tree onto the pixmap
--- @param width number Pixmap width in pixels
--- @param height number Pixmap height in pixels
--- @param transform table|Transform|nil Root SVG transform, can be used to position SVG inside the pixmap
--- @return Pixmap Rendered pixmap with premultiplied RGBA8888 pixels
--- @function Tree:render
function Tree:render(width, height, transform)
    -- Validate input dimensions
    if type(width) ~= "number" or type(height) ~= "number" then
        error("Width and height must be numbers", 2)
    end
    if width <= 0 or height <= 0 then
        error("Width and height must be positive", 2)
    end
    if width > 65535 or height > 65535 then
        error("Width and height must be less than 65536", 2)
    end
    
    width = math.floor(width)
    height = math.floor(height)

    --- Create pixel buffer
    local pixel_count = width * height * 4
    local pixmap = ffi.new("char[?]", pixel_count)

    --- Process transform
    local t
    if transform then
        if type(transform) == "table" then
            -- Accept either a plain matrix table {a,b,c,d,e,f} or a Transform instance with `.data`
            if transform.data then
                t = transform.data
            else
                t = utils.table_to_transform(transform)
            end
        else
            t = transform
        end
    else
        t = C.resvg_transform_identity()
    end

    --- Render the tree
    C.resvg_render(self.ptr, t, width, height, pixmap)

    --- Return Pixmap object
    return M.Pixmap.from_raw(pixmap, width, height)
end

--- Renders a node by ID onto the image
--- @param id string Node's ID (UTF-8 string)
--- @param width number Pixmap width in pixels
--- @param height number Pixmap height in pixels
--- @param transform table|Transform|nil Root SVG transform, can be used to position SVG inside the pixmap
--- @return Pixmap|nil Rendered pixmap with premultiplied RGBA8888 pixels, or nil on error
--- @return string|nil Error message if failed
--- @function Tree:render_node
function Tree:render_node(id, width, height, transform)
    -- Validate input parameters
    if type(id) ~= "string" then
        return nil, "Node ID must be a string"
    end
    if id == "" then
        return nil, "Node ID cannot be empty"
    end
    if type(width) ~= "number" or type(height) ~= "number" then
        return nil, "Width and height must be numbers"
    end
    if width <= 0 or height <= 0 then
        return nil, "Width and height must be positive"
    end
    if width > 65535 or height > 65535 then
        return nil, "Width and height must be less than 65536"
    end
    
    width = math.floor(width)
    height = math.floor(height)

    --- Create pixel buffer
    local pixel_count = width * height * 4
    local pixmap = ffi.new("char[?]", pixel_count)

    --- Process transform
    local t
    if transform then
        if type(transform) == "table" then
            -- Accept either a plain matrix table {a,b,c,d,e,f} or a Transform instance with `.data`
            if transform.data then
                t = transform.data
            else
                t = utils.table_to_transform(transform)
            end
        else
            t = transform
        end
    else
        t = C.resvg_transform_identity()
    end

    --- Render the node
    local success = C.resvg_render_node(self.ptr, id, t, width, height, pixmap)

    if not success then
        return nil, "Failed to render node: node may not exist or be renderable"
    end

    --- Return Pixmap object
    return M.Pixmap.from_raw(pixmap, width, height)
end

--- Transform class for 2D affine transformations
--- @class Transform
local Transform = {}
Transform.__index = Transform

--- Creates an identity transform
--- @return Transform Identity transform (no transformation)
--- @function Transform.identity
function Transform.identity()
    local self = setmetatable({}, Transform)
    self.data = C.resvg_transform_identity()
    return self
end

--- Creates a new transform from matrix values
--- @param a number Horizontal scaling / cosine of rotation
--- @param b number Vertical skewing / sine of rotation
--- @param c number Horizontal skewing / negative sine of rotation
--- @param d number Vertical scaling / cosine of rotation
--- @param e number Horizontal translation
--- @param f number Vertical translation
--- @return Transform New transform
--- @function Transform.new
function Transform.new(a, b, c, d, e, f)
    -- Validate all parameters are numbers
    local params = {a, b, c, d, e, f}
    for i, param in ipairs(params) do
        if type(param) ~= "number" or param ~= param then -- Check for NaN
            error(string.format("Transform parameter %d must be a valid number", i), 2)
        end
    end
    
    local self = setmetatable({}, Transform)
    self.data = utils.table_to_transform({ a, b, c, d, e, f })
    return self
end

--- Creates a translation transform
--- @param x number Horizontal translation
--- @param y number Vertical translation
--- @return Transform Translation transform
--- @function Transform.translate
function Transform.translate(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then
        error("Translation parameters must be numbers", 2)
    end
    if x ~= x or y ~= y then -- Check for NaN
        error("Translation parameters cannot be NaN", 2)
    end
    
    local self = setmetatable({}, Transform)
    self.data = utils.create_translate_transform(x, y)
    return self
end

--- Creates a scale transform
--- @param sx number Horizontal scaling factor
--- @param sy number|nil Vertical scaling factor (defaults to sx if not provided)
--- @return Transform Scale transform
--- @function Transform.scale
function Transform.scale(sx, sy)
    if type(sx) ~= "number" then
        error("Horizontal scaling factor must be a number", 2)
    end
    if sx ~= sx then -- Check for NaN
        error("Horizontal scaling factor cannot be NaN", 2)
    end
    if sy and (type(sy) ~= "number" or sy ~= sy) then
        error("Vertical scaling factor must be a valid number", 2)
    end
    
    local self = setmetatable({}, Transform)
    self.data = utils.create_scale_transform(sx, sy)
    return self
end

--- Creates a rotation transform
--- @param angle number Rotation angle in degrees
--- @param cx number|nil Center X coordinate (default: 0)
--- @param cy number|nil Center Y coordinate (default: 0)
--- @return Transform Rotation transform
--- @function Transform.rotate
function Transform.rotate(angle, cx, cy)
    if type(angle) ~= "number" or angle ~= angle then
        error("Rotation angle must be a valid number", 2)
    end
    if cx and (type(cx) ~= "number" or cx ~= cx) then
        error("Center X coordinate must be a valid number", 2)
    end
    if cy and (type(cy) ~= "number" or cy ~= cy) then
        error("Center Y coordinate must be a valid number", 2)
    end
    
    local self = setmetatable({}, Transform)
    self.data = utils.create_rotate_transform(angle, cx, cy)
    return self
end

--- Multiplies two transforms
--- @param other Transform Transform to multiply with
--- @return Transform Result of matrix multiplication
--- @function Transform:multiply
function Transform:multiply(other)
    if not other or not other.data then
        error("Transform multiply requires another Transform object", 2)
    end
    local result = setmetatable({}, Transform)
    result.data = utils.multiply_transforms(self.data, other.data)
    return result
end

--- Converts transform to table representation
--- @return table Table with a,b,c,d,e,f fields
--- @function Transform:to_table
function Transform:to_table()
    return utils.transform_to_table(self.data)
end

--- Pixmap class for pixel buffer management
--- Contains premultiplied RGBA8888 pixels
--- @class Pixmap
--- @field width number Width in pixels
--- @field height number Height in pixels
--- @field data userdata Raw pixel data pointer
local Pixmap = {}
Pixmap.__index = Pixmap

--- Creates a new empty pixmap
--- @param width number Width in pixels
--- @param height number Height in pixels
--- @return Pixmap New pixmap with uninitialized data
--- @function Pixmap.new
function Pixmap.new(width, height)
    if type(width) ~= "number" or type(height) ~= "number" then
        error("Width and height must be numbers", 2)
    end
    if width <= 0 or height <= 0 then
        error("Width and height must be positive", 2)
    end
    if width > 65535 or height > 65535 then
        error("Width and height must be less than 65536", 2)
    end
    
    width = math.floor(width)
    height = math.floor(height)
    
    local self = setmetatable({}, Pixmap)
    self.width = width
    self.height = height
    self.data = ffi.new("char[?]", width * height * 4)
    return self
end

--- Creates a pixmap from raw data pointer
--- @param data userdata Raw pixel data pointer
--- @param width number Width in pixels
--- @param height number Height in pixels
--- @return Pixmap New pixmap referencing the provided data
--- @function Pixmap.from_raw
function Pixmap.from_raw(data, width, height)
    local self = setmetatable({}, Pixmap)
    self.width = width
    self.height = height
    self.data = data
    return self
end

--- Creates a pixmap from data string
--- @param data string Pixel data as string
--- @param width number Width in pixels
--- @param height number Height in pixels
--- @return Pixmap New pixmap with copied data
--- @function Pixmap.from_data
function Pixmap.from_data(data, width, height)
    if type(data) ~= "string" then
        error("Data must be a string", 2)
    end
    if type(width) ~= "number" or type(height) ~= "number" then
        error("Width and height must be numbers", 2)
    end
    if width <= 0 or height <= 0 then
        error("Width and height must be positive", 2)
    end
    if width > 65535 or height > 65535 then
        error("Width and height must be less than 65536", 2)
    end
    
    width = math.floor(width)
    height = math.floor(height)
    
    local expected_size = width * height * 4
    if #data ~= expected_size then
        error(string.format("Data size mismatch: expected %d bytes, got %d", expected_size, #data), 2)
    end
    
    local self = setmetatable({}, Pixmap)
    self.width = width
    self.height = height
    self.data = ffi.new("char[?]", expected_size)
    ffi.copy(self.data, data, expected_size)
    return self
end

--- Gets pixel data as string
--- @return string Pixel data as binary string (RGBA format)
--- @function Pixmap:get_data
function Pixmap:get_data()
    return ffi.string(self.data, self.width * self.height * 4)
end

--- Converts pixmap to RGB format (removes alpha channel)
--- @return string RGB pixel data as binary string
--- @function Pixmap:to_rgb
function Pixmap:to_rgb()
    local rgb_size = self.width * self.height * 3
    local rgb_data = ffi.new("char[?]", rgb_size)
    local src = self.data

    local rgb_idx = 0
    for i = 0, self.width * self.height - 1 do
        local rgba_offset = i * 4
        rgb_data[rgb_idx] = src[rgba_offset]     -- R component
        rgb_data[rgb_idx + 1] = src[rgba_offset + 1] -- G component
        rgb_data[rgb_idx + 2] = src[rgba_offset + 2] -- B component
        rgb_idx = rgb_idx + 3
    end

    return ffi.string(rgb_data, rgb_size)
end

--- Converts pixmap to BGRA format
--- @return string BGRA pixel data as binary string
--- @function Pixmap:to_bgra
function Pixmap:to_bgra()
    local bgra_data = ffi.new("char[?]", self.width * self.height * 4)
    local src = self.data

    for i = 0, self.width * self.height - 1 do
        local offset = i * 4
        bgra_data[offset] = src[offset + 2]     --- B component (from R)
        bgra_data[offset + 1] = src[offset + 1] --- G component
        bgra_data[offset + 2] = src[offset]     --- R component (from B)
        bgra_data[offset + 3] = src[offset + 3] --- A component
    end

    return ffi.string(bgra_data, self.width * self.height * 4)
end

--- Export classes
M.Options = Options
M.Tree = Tree
M.Transform = Transform
M.Pixmap = Pixmap

--- Convenience functions
--- Convenience function to parse SVG file
--- @param filepath string UTF-8 path to the SVG file
--- @param options Options|nil Rendering options (uses defaults if nil)
--- @return Tree|nil Parsed render tree on success, nil on error
--- @return string|nil Error message if failed
--- @function parse_file
M.parse_file = function(filepath, options)
    return Tree.from_file(filepath, options)
end

--- Convenience function to parse SVG data
--- @param data string SVG data
--- @param options Options|nil Rendering options (uses defaults if nil)
--- @return Tree|nil Parsed render tree on success, nil on error
--- @return string|nil Error message if failed
--- @function parse_data
M.parse_data = function(data, options)
    return Tree.from_data(data, options)
end

return M
