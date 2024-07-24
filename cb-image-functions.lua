-- useful functions
if not cb then cb = {} end
if not cb.lib then cb.lib = {} end

local flib_data_util = require("__flib__.data-util")
local gfolder = '__cb-library__/graphics/'

function cb.lib.hslToRgb(h, s, l)
    h = h / 360
    s = s / 100
    l = l / 100

    local r, g, b;

    if s == 0 then
        r, g, b = l, l, l; -- achromatic
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 / 2 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p;
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s;
        local p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    end

    if not a then a = 1 end
    return r * 255, g * 255, b * 255, a * 255
end

function cb.lib.decompose_box(box)
    local b = {}
    b.left = box[1][1]
    b.top = box[1][2]
    b.right = box[2][1]
    b.bottom = box[2][2]
    b.width = b.right - b.left
    b.height = b.bottom - b.top
    b.centerx = b.left + b.width / 2
    b.centery = b.bottom + b.height / 2
    return b
end

cb.lib.tints = {

    A = { cb.lib.hslToRgb(270, 70, 45) }, -- 260 bit too blue??
    B = { cb.lib.hslToRgb(125, 40, 35) }, -- 125 35 40 too light
    P = { cb.lib.hslToRgb(0, 85, 35) },   -- 0 80 30 too dark   0 85 40 tiny bit bright
    R = { cb.lib.hslToRgb(205, 85, 35) }, -- 205 85 40 too bright
    S = { cb.lib.hslToRgb(45, 70, 40) },  -- 45,65,35 bit too grey

    black = { cb.lib.hslToRgb(0, 0, 0) },
    ltgrey = { cb.lib.hslToRgb(0, 0, 65) },
    midgrey = { cb.lib.hslToRgb(0, 0, 40) },
    dkgrey = { cb.lib.hslToRgb(0, 0, 20) },

}

cb.lib.letterlist = {
    ['active-provider'] = 'A',
    ['passive-provider'] = 'P',
    ['requester'] = 'R',
    ['storage'] = 'S',
    ['buffer'] = 'B'
}


--- takes a prototype and a list of layers.
--- returns a set of iconS, animation.layers, and picture.layers
--- it's up to the caller to decide which, if any, of the layers to use
--- @param pt table
--- @param new_layers table of tables
function cb.lib.make_layers(pt, new_layers)
    local R = {}
    R.icons = {}
    R.animation_layers = {}
    R.picture_layers = {}
    R.spriteNway_layers = {}

    for i, v in ipairs(new_layers) do
        local L = cb.lib.make_layer(pt, v)
        table.insert(R.icons, L.icon_layer)
        table.insert(R.animation_layers, L.animation_layer)
        table.insert(R.picture_layers, L.picture_layer)
        table.insert(R.spriteNway_layers, L.spriteNway)
    end
    return R
end

--- make a single layer, in all 3 formats (iconData, animation, picture)
--- @param pt table to get selection_box and repeat count -- the entity if it exists
--- layerinfo:
--- @param file string name of png, 64x64, in graphics folder in this mod
--- @param tint table r,g,b,a, all as 0-255
--- @param shift = compared to other layers of the set
--- @param iconshift table defaults to {0,0}, relative to center of entity or icon;
----    "Shift values are based on final size (icon_size * scale) of the first icon layer.
----    "Scale ... Defaults to 32/icon_size for items and recipes, and 256/icon_size for technologies"
--- @param entityshift string
----    picture, animation : in tiles

--- @param scale float defaults to 1; applied to just this layer, eg inner box vs outer
--- @param entityscale float defaults to larger for large entities


function cb.lib.make_layer(pt, layerinfo)
    local L = table.deepcopy(layerinfo)

    local R = {}
    R.icon_layer = {}
    R.animation_layer = {}
    R.picture_layer = {}
    R.spriteNway = {}


    if not L.tint then
        L.tint = { 1, 1, 1, 1 }
    end

    if pt and pt.animation and pt.animation.layers[1] then
        L.rpt_ct = (pt.animation.layers[1].frame_count or 1) * (pt.animation.layers[1].repeat_count or 1)
    else
        L.rpt_ct = 1
    end

    if not L.iconshift then
        L.iconshift = { 0, 0 }
    end

    if not L.scale then
        L.scale = 1
    end

    if pt.selection_box then
        L.entity_width = cb.lib.decompose_box(pt.selection_box).width
        L.entity_height = cb.lib.decompose_box(pt.selection_box).height
    else
        L.entity_width = 1
        L.entity_height = 1
    end

    if L.entity_width > 1 then
        L.x = L.entity_width / 2.5 - 0.5
    else
        L.x = 0.2
    end

    if L.entity_height > 1 then
        L.y = L.entity_height / 2.5 - 0.5
    else
        L.y = 0.2
    end





    if not L.entityscale then
        if L.entity_width <= 1 then
            L.entityscale = 0.3
        elseif L.entity_width <= 2 then
            L.entityscale = 0.4
        elseif L.entity_width <= 3 then
            L.entityscale = 0.4
        elseif L.entity_width <= 4 then
            L.entityscale = 0.5
        else
            L.entityscale = 0.6
        end
    end


    if not L.entityshift then
        L.entityshift = 'mid-mid'
    end

    if not L.entityshift_vector then
        if L.entityshift == 'left-top' then
            L.entityshift_vector = { -L.x, -L.y }
        elseif L.entityshift == 'mid-top' then
            L.entityshift_vector = { 0, -L.y, }
        elseif L.entityshift == 'right-top' then
            L.entityshift_vector = { L.x, -L.y }
        elseif L.entityshift == 'left-mid' then
            L.entityshift_vector = { -L.x, 0 }
        elseif L.entityshift == 'mid-mid' then
            L.entityshift_vector = { 0, 0 }
        elseif L.entityshift == 'right-mid' then
            L.entityshift_vector = { L.x, 0 }
        elseif L.entityshift == 'left-bot' then
            L.entityshift_vector = { -L.x, L.y }
        elseif L.entityshift == 'mid-bot' then
            L.entityshift_vector = { 0, L.y }
        elseif L.entityshift == 'right-bot' then
            L.entityshift_vector = { L.x, L.y }
        end
    end






    --  END OF INPUT CHECKING


    R.icon_layer =
    {
        icon = gfolder .. L.file,
        icon_size = 64,
        scale = L.scale * .25,
        shift = L.iconshift,
        tint = L.tint
    }
    R.animation_layer =
    {
        filename = gfolder .. L.file,
        size = 64,
        scale = L.scale * L.entityscale,
        shift = L.entityshift_vector,
        tint = L.tint,
        repeat_count = L.rpt_ct,
        frame_count = 1
    }
    R.picture_layer =
    {
        filename = gfolder .. L.file,
        size = 64,
        scale = L.scale * L.entityscale,
        shift = L.entityshift_vector,
        tint = L.tint
    }
    R.spriteNway =
    {
        filename = gfolder .. L.file,
        size = 64,
        scale = L.scale * L.entityscale,
        shift = L.entityshift_vector,
        tint = L.tint,
        frames = 1
    }
    return R
end

function cb.lib.add_icon_layers(pt, new_layers)
    pt.icons = flib_data_util.create_icons(pt, new_layers)
    pt.icon = nil
    pt.icon_size = nil
    pt.icon_mipmaps = nil
    -- no need to remove the old single-icon info; it's ignored; removed it anyways
    -- flib.create_icons copies single-icon info to existing iconS layers if needed
end

function cb.lib.add_picture_layers_to_container(pt, new_layers)
    if not pt.picture.layers then
        local l = table.deepcopy(pt.picture)
        pt.picture ={}
        pt.picture.layers={l}
        -- table.insert(pt.picture.layers, l)
    end
    for i, v in ipairs(new_layers) do
        table.insert(pt.picture.layers, v)
    end
end

function cb.lib.add_animation_layers_to_logcont(pt, new_layers) -- for logistic chests, not assemblers
    if not pt.animation.layers then
        local l = table.deepcopy(pt.animation)
        pt.animation = {}
        pt.animation.layers ={l}
        -- table.insert(pt.animation.layers, l)
    end
    for i, v in ipairs(new_layers) do
        table.insert(pt.animation.layers, v)
    end
end

function cb.lib.add_picture_layers_to_storage_tank(pt, new_layers)
    if pt.pictures.picture.sheet then
        pt.pictures.picture.sheets = {}
        table.insert(pt.pictures.picture.sheets, pt.pictures.picture.sheet)
        pt.pictures.picture.sheet = nil
    end
    for i, v in ipairs(new_layers) do
        if pt.pictures.picture.sheets then
            table.insert(pt.pictures.picture.sheets, v)
        end
        if pt.pictures.picture.north then
            table.insert(pt.pictures.picture.north, v)
        end
        if pt.pictures.picture.east then
            table.insert(pt.pictures.picture.east, v)
        end
        if pt.pictures.picture.south then
            table.insert(pt.pictures.picture.south, v)
        end
        if pt.pictures.picture.west then
            table.insert(pt.pictures.picture.west, v)
        end
    end
    local b = 1
    log('cb-ls-ms tanks '..pt.name)
end
