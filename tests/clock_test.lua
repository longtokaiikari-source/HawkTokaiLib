-- tests/clock_test.lua: the GMT clock parts in Source.luau (Library._gmtParts), checked against known moments and
-- against os.date with "!" (UTC) on random moments. Run from the project folder: texlua tests/clock_test.lua
local file = io.open("Source.luau", "r") or io.open("../Source.luau", "r")
assert(file, "Source.luau was not found: run this from the project folder")
local source = file:read("*a")
file:close()
local start = source:find("Library._gmtParts = function(epoch, hours)", 1, true)
assert(start, "Library._gmtParts is not in Source.luau")
local stop = source:find("\nend\n", start, true)
assert(stop, "the end of Library._gmtParts was not found")
Library = {}
assert(load(source:sub(start, stop + 4)))()

local failures = 0
local function check(ok, label)
    if not ok then
        failures = failures + 1
        print("FAIL " .. label)
    end
end
local function parts(epoch, hours)
    return Library._gmtParts(epoch, hours)
end
local function is(p, h, m, s, y, mo, d, weekday)
    return p.Hour == h and p.Minute == m and p.Second == s and p.Year == y and p.Month == mo and p.Day == d and p.Weekday == weekday
end

check(is(parts(0, 0), 0, 0, 0, 1970, 1, 1, "Thursday"), "the epoch is Thursday 1 January 1970 00:00:00")
check(is(parts(1700000000, 0), 22, 13, 20, 2023, 11, 14, "Tuesday"), "1700000000 is Tuesday 14 November 2023 22:13:20 UTC")
check(is(parts(1700000000, 7), 5, 13, 20, 2023, 11, 15, "Wednesday"), "GMT+7 adds seven hours and moves the day")
check(is(parts(1700000000, -5), 17, 13, 20, 2023, 11, 14, "Tuesday"), "GMT-5 takes five hours off")
check(is(parts(1709208000, 0), 12, 0, 0, 2024, 2, 29, "Thursday"), "29 February 2024 is a Thursday")
check(is(parts(1704067199, 0), 23, 59, 59, 2023, 12, 31, "Sunday"), "the last second of 2023")
check(is(parts(1704067200, 0), 0, 0, 0, 2024, 1, 1, "Monday"), "the first second of 2024")

math.randomseed(12345)
local names = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local zones = { 0, 5.5, -3.5, 7, 12.75, -11, 14 }
for i = 1, 3000 do
    local epoch = math.random(100000, 4102444800)
    local hours = zones[math.random(1, #zones)]
    local shifted = epoch + math.floor(hours * 3600 + 0.5)
    local p = parts(epoch, hours)
    local d = os.date("!*t", shifted)
    local ok = p.Year == d.year and p.Month == d.month and p.Day == d.day and p.Hour == d.hour and p.Minute == d.min
        and p.Second == d.sec and p.Weekday == names[d.wday]
    check(ok, "random moment " .. tostring(shifted) .. " at " .. tostring(hours))
    if not ok then
        break
    end
end

print(failures == 0 and "CLOCK PASS" or ("CLOCK FAILED " .. failures))
os.exit(failures == 0 and 0 or 1)
