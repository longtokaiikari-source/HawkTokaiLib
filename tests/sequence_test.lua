-- tests/sequence_test.lua: every NumberSequence and ColorSequence in Source.luau must start at time 0 and end at time 1,
-- or Roblox refuses to build it. A white sheen whose transparency fades must not sit on a panel: it would fade the
-- panel's own background. Run from the project folder.
local file = io.open("Source.luau", "r") or io.open("../Source.luau", "r")
assert(file, "run this from the project folder")
local source = file:read("*a")
file:close()
local failures, checked = 0, 0
local function scan(kind)
    local start = 1
    while true do
        local s, e = source:find(kind .. ".new({", start, true)
        if not s then
            break
        end
        local stop = source:find("})", e, true)
        assert(stop, "unclosed " .. kind)
        local segment = source:sub(e + 1, stop - 1)
        local times = {}
        for time in segment:gmatch("Keypoint%.new%(%s*([%d%.]+)") do
            times[#times + 1] = tonumber(time)
        end
        checked = checked + 1
        if #times < 2 or times[1] ~= 0 or times[#times] ~= 1 then
            failures = failures + 1
            local line = select(2, source:sub(1, s):gsub("\n", "")) + 1
            print(("line %d: %s keypoints %s"):format(line, kind, table.concat(times, ", ")))
        end
        start = stop + 2
    end
end
scan("NumberSequence")
scan("ColorSequence")

local lines = {}
for line in (source .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
end
for index, line in ipairs(lines) do
    if line:find("Color = ColorSequence.new(Color3.new(1, 1, 1))", 1, true) then
        for other = index, math.min(index + 6, #lines) do
            if lines[other]:find("Transparency = NumberSequence.new", 1, true) then
                failures = failures + 1
                print(("line %d: a white sheen with a fading transparency sits on a panel and fades its background"):format(index))
                break
            end
        end
    end
end

print(("checked %d sequences"):format(checked))
print(failures == 0 and "SEQUENCE PASS" or ("SEQUENCE FAILED " .. failures))
os.exit(failures == 0 and 0 or 1)
