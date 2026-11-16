-- tests/backdrop_test.lua: the backdrop's light (glow, embers, petals, matrix, fireflies) goes out with the Backdrop Tint.
-- From the project folder:  lua tests/backdrop_test.lua   (Lua 5.3 or newer). Plain Lua, no Roblox needed.
-- It takes the backdrop step out of Source.luau and runs it with stand-ins for the frames and for the weather.

local file = io.open("Source.luau", "r") or io.open("../Source.luau", "r")
assert(file, "Source.luau was not found: run this from the project folder")
local source = file:read("a")
file:close()

local first = source:find("function Window:_stepBackdrop(deltaTime)", 1, true)
assert(first, "the backdrop step was not found in Source.luau")
local last = source:find("\nend\n", first, true)
assert(last, "the end of the backdrop step was not found")
local body = source:sub(first, last + 4)

-- Luau's compound assignments (+=, -=, *= and /=), written as plain Lua for the loader.
local lines = {}
for line in (body .. "\n"):gmatch("(.-)\n") do
    local indent, target, op, value = line:match("^(%s*)([%w_%.]+)%s*([%+%-%*/])=%s*(.-)%s*$")
    if indent then
        line = indent .. target .. " = " .. target .. " " .. op .. " (" .. value .. ")"
    end
    lines[#lines + 1] = line
end

-- The weather kinds the step reads: the glow of the light kinds, and the snow, which is not light.
WEATHER = {
    Ember = { Image = "x", Count = 55 },
    Sakura = { Petal = true, Count = 46, Glow = 1, GlowAmount = 0.1 },
    Fireflies = { Image = "y", Count = 34, Glow = 2, GlowAmount = 0.16 },
    Matrix = { Text = true, Count = 38, Glow = 3, GlowAmount = 0.07 },
    Snow = { Image = "z", Count = 60 },
}
function seedParticle() end
Window = {}
local chunk, err = load(table.concat(lines, "\n"), "=backdrop step")
assert(chunk, err)
chunk()

local failed = false
local function check(ok, message)
    print((ok and "ok   " or "FAIL ") .. message)
    if not ok then
        failed = true
    end
end
local function backdrop(kind, tint)
    local frame = {
        Weather = kind, _backdropTint = tint, _backdropShown = true, _backdropFade = 1,
        _backdropDim = true, _dimLevel = 1,
        _backdrop = { Visible = true }, _weatherField = { Visible = true },
        _backdropTintFrame = { BackgroundTransparency = 1 },
        _backdropHeat = { BackgroundTransparency = 1 },
        _weatherParticles = {}, _weatherKick = 0, _weatherSpeed = 1,
    }
    frame._weatherSize = function() return { X = 400, Y = 300 } end
    return frame
end

for _, kind in ipairs({ "Fireflies", "Sakura", "Matrix", "Ember" }) do
    local zero = backdrop(kind, 0)
    Window._stepBackdrop(zero, 0.016)
    check(zero._weatherField.Visible == false, kind .. " at zero tint: its light field is hidden")
    check(zero._backdropHeat.BackgroundTransparency == 1, kind .. " at zero tint: no glow")
    local normal = backdrop(kind, 0.45)
    Window._stepBackdrop(normal, 0.016)
    check(normal._weatherField.Visible == true, kind .. " at the default tint: its light shows")
    check(normal._backdropHeat.BackgroundTransparency < 1, kind .. " at the default tint: the glow shows")
end

local snow = backdrop("Snow", 0)
Window._stepBackdrop(snow, 0.016)
check(snow._weatherField.Visible == true, "snow is not light, so it stays at zero tint")

print(failed and "RESULT fails" or "RESULT all passed")
if failed then
    os.exit(1)
end
