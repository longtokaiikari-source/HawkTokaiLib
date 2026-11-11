-- Protected script. Paste this into the Original Code of your script on Junkie. Loader.luau checks the key, then runs it.
-- Push Source.luau to main first, or this loads an old copy (or a 404).
-- To test a local copy instead: loadstring(readfile("HawkTokaiLib/Source.luau"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/Source.luau"))()

-- Runtime variables exist only after Junkie authenticates this script. Outside
-- Junkie (for example in a local test) they are nil and the license card is hidden.
local keyInfo = nil
if JD_REASON then
    keyInfo = {
        ExpiresAt = JD_EXPIRES_AT,
        Tier = JD_TIER_NAME,
        Premium = JD_IS_PREMIUM,
        Keyless = JD_REASON == "KEYLESS",
    }
end

--[[
    Example script

    A reference build that shows every part of the library in a realistic
    layout. Each section is self-contained: copy the parts you need.

    Structure
      Window      the main frame, Home tab and global options
      Main        a typical feature tab: sub tabs, groupboxes and controls
      Status      live readouts: statuses, status lists and dependent controls
      Elements    one of every element as a full-width card
      Popups      notifications, confirms and dialogs
      Cloud       a shared config browser backed by an in-memory store
      Settings    interface options, config manager and theme manager
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Library:LoadFont({ Name = "ValleySans" }) -- downloaded once and used everywhere
-- Library:SetDefaultTheme("Nebula") -- any preset name or a colour table; a theme the player picks wins

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local Window = Library:CreateWindow({
    Name = "Example",
    LoadingSubtitle = "Loading",
    ToggleUIKeybind = "RightControl", -- a KeyCode name or Enum.KeyCode
    ConfigurationSaving = { Enabled = true },
    ToggleButton = { Platform = "Mobile", Icon = "layout-grid" }, -- "Both" also shows it on PC
    Backdrop = { Weather = "None", Tint = 0.45 }, -- "Snow", "Rain", "Hell Fire", "Sakura", "Fireflies", "Matrix" or "None"
    -- UIScale = 1,           -- 0.6 to 1.5, on top of the automatic fit
    -- Density = "Default",   -- "Compact", "Default" or "Comfortable"
    -- SidebarWidth = 188,    -- starting sidebar width; players can drag the divider
    -- Disclaimer = { Title = "Terms", Text = "By continuing you accept the terms.", Id = "terms-v1" },
    Home = {
        KeyInfo = keyInfo,
        Tier = "Free",
        Discord = "https://discord.gg/deVVQEVybd",
        Website = "example.com",
        Stats = { "Players", "Execs", "Session", "FPS", "Ping" },
        -- The hidden egg: a Code box at the bottom of Home. Typing the secret phrase shows Play.
        EasterEgg = {
            Hash = 62829308,                                   -- hash of the secret phrase, not the phrase
            Image = "https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/assets/egg.jpg",   -- the picture, downloaded into the workspace
            Sound = "https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/assets/egg.mp3",   -- the sound, downloaded into the workspace
            Volume = 10,
            Kick = "The taxman summoned the blue lobster of Longtokai, and it devoured you. . .",
        },
        -- Features = { List = { { Name = "Main", Items = { "Automation", { Name = "Targeting", Tag = "New" } } } } },
    },
})

Window:SetWatermark({ Text = "Example", FPS = true, Time = true })


--------------------------------------------------------------------------------
-- Main: tabs hold sub tabs, sub tabs hold groupboxes, groupboxes hold elements
--------------------------------------------------------------------------------

local Main = Window:CreateTab({ Name = "Main", Icon = "zap" })

local General = Main:CreateSubTab({ Name = "General" })

local Automation = General:AddLeftGroupbox({ Name = "Automation", Icon = "repeat" })

local AutomationEnabled = Automation:CreateToggle({
    Name = "Enabled",
    Desc = "Runs the selected tasks on a loop",
    CurrentValue = false,
    Flag = "AutomationEnabled",
    Callback = function(Value)
        print("[Example] automation", Value)
    end,
})

Window:BindToggle(AutomationEnabled, Enum.KeyCode.G, "Toggle")
Window:SetKeybindListVisible(true)

Automation:CreateDropdown({
    Name = "Tasks",
    Options = { "Collect", "Upgrade", "Sell", "Claim Rewards" },
    MultipleOptions = true,
    CurrentOption = { "Collect" },
    Flag = "AutomationTasks",
    Callback = function(Options)
        print("[Example] tasks", table.concat(Options, ", "))
    end,
})

Automation:CreateSlider({
    Name = "Interval",
    Range = { 1, 60 },
    Increment = 1,
    Suffix = "s",
    CurrentValue = 5,
    Flag = "AutomationInterval",
    Callback = function(Value)
        print("[Example] interval", Value)
    end,
})

local Targeting = General:AddRightGroupbox({ Name = "Targeting", Icon = "crosshair" })

Targeting:CreateDropdown({
    Name = "Mode",
    Options = { "Nearest", "Lowest Health", "Highest Value" },
    CurrentOption = "Nearest",
    Flag = "TargetMode",
    Callback = function(Option)
        print("[Example] target mode", Option)
    end,
})

Targeting:CreateSlider({
    Name = "Range",
    Range = { 0, 500 },
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 150,
    Flag = "TargetRange",
    Callback = function(Value)
        print("[Example] range", Value)
    end,
})

Targeting:CreateToggle({
    Name = "Ignore Friends",
    CurrentValue = true,
    Flag = "IgnoreFriends",
    Callback = function(Value)
        print("[Example] ignore friends", Value)
    end,
})

local Controls = General:AddRightGroupbox({ Name = "Controls", Icon = "sliders-horizontal", Collapsed = true })

Controls:CreateStepper({
    Name = "Speed",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = 5,
    Flag = "Speed",
    Callback = function(Value)
        print("[Example] speed", Value)
    end,
})

Controls:CreateKeybind({
    Name = "Stop",
    CurrentKeybind = "X",
    Flag = "StopKey",
    Callback = function()
        print("[Example] stop")
    end,
})

local Advanced = Main:CreateSubTab({ Name = "Advanced" })

local Profiles = Advanced:AddLeftGroupbox({ Name = "Profile", Icon = "user-cog" })

Profiles:CreateInput({
    Name = "Webhook URL",
    PlaceholderText = "https://",
    Flag = "WebhookUrl",
    Callback = function(Text)
        print("[Example] webhook", Text)
    end,
})

Profiles:CreateColorPicker({
    Name = "Highlight Color",
    Color = Color3.fromRGB(128, 160, 246),
    Flag = "HighlightColor",
    Callback = function(Color)
        print("[Example] color", Color)
    end,
})

Profiles:CreateButton({
    Name = "Apply",
    Style = "Primary",
    Callback = function()
        print("[Example] applied")
    end,
})

-- Order lists are always open: drag a row (by its grip on touch) or use the arrows.
local Priority = Advanced:AddRightGroupbox({ Name = "Priority", Icon = "list-ordered" })

Priority:CreateOrderList({
    Name = "Task Order",
    Desc = "The top task runs first",
    Items = { "Collect", "Upgrade", "Sell", "Claim Rewards" },
    Flag = "TaskOrder",
    Callback = function(Order)
        print("[Example] order", table.concat(Order, " > "))
    end,
})

local Steps = {}
for Index = 1, 12 do
    Steps[Index] = "Step " .. Index
end
Priority:CreateOrderList({
    Name = "Steps",
    Items = Steps,
    MaxRows = 5, -- more rows than MaxRows scroll inside the list
    Flag = "StepOrder",
})

Main:CreateSubTab({ Name = "Queue" }) -- an empty sub tab shows the empty state

--------------------------------------------------------------------------------
-- Status: live readouts. Pin = true also shows a value on the minimized island
--------------------------------------------------------------------------------

local Status = Window:CreateTab({ Name = "Status", Icon = "activity" })

local Session = Status:AddLeftGroupbox({ Name = "Session", Icon = "timer" })
local Cycles = 0
Session:CreateStatuses({
    { Name = "Cycles", Pin = true, Update = function()
        Cycles += 1
        return Cycles
    end },
    { Name = "Collected", Value = 0 },
    { Name = "Errors", Value = 0 },
    { Name = "Region", Value = "-" },
}, { Style = "Plain" })

local Progress = Status:AddRightGroupbox({ Name = "Progress", Icon = "trending-up" })
Progress:CreateStatus({ Name = "Level", Value = 42, Style = "Stat" })
Progress:CreateStatus({ Name = "Experience", Value = "6200/10000", Style = "Bar" })
Progress:CreateStatus({ Name = "Balance", Value = 125000, Style = "Row", Pin = true })

local Health = Status:AddLeftGroupbox({ Name = "Health", Icon = "heart-pulse" })
local States = { { "Running", "Success" }, { "Waiting", "Warning" }, { "Stopped", "Error" } }
Health:CreateStatus({ Name = "State", Style = "Dot", Update = function()
    local State = States[math.floor(os.clock() / 3) % #States + 1]
    return State[1], State[2] -- a second string return sets the tone
end })
Health:CreateStatus({ Name = "Service", Value = "Online", Style = "Badge", Tone = "Success" })
Health:CreateStatus({ Name = "Load", Style = "Bar", Tone = "Warning", UpdateRate = 0.5, Update = function()
    return (os.clock() * 100) % 100, 100 -- a number second return sets the max
end })
-- Coloured text: theme tags follow the theme, Colorize wraps any colour.
Health:CreateStatus({ Name = "Ping", Style = "Row", Pin = true, Update = function()
    local Ms = math.floor(LocalPlayer:GetNetworkPing() * 1000)
    local Tone = Ms < 90 and "Success" or Ms < 180 and "Warning" or "Error"
    return Library.Colorize(Ms .. " ms", Tone)
end })
Health:CreateStatus({ Name = "Summary", Style = "Row", Value = "<Accent>3</Accent> active · <Muted>9 idle</Muted>" })

-- Status lists grow with their rows up to MaxRows, then scroll inside.
local Jobs = Status:AddRightGroupbox({ Name = "Jobs", Icon = "list-checks" })
Jobs:CreateStatusList({
    Name = "Queue",
    MaxRows = 5,
    EmptyText = "Nothing queued",
    UpdateRate = 0.5,
    Update = function()
        local Rows = {}
        for Index = 1, 8 do
            local Remaining = math.floor((os.clock() + Index * 3) % 15)
            Rows[Index] = {
                Text = "Job " .. Index,
                Value = Remaining == 0 and "done" or (Remaining .. "s left"),
                Tone = Remaining == 0 and "Success" or nil,
            }
        end
        return Rows
    end,
})

-- Dependent controls: the slider only shows while the toggle is on.
local Limit -- declared first so the toggle's callback can reach it
Jobs:CreateToggle({
    Name = "Limit Jobs",
    CurrentValue = false,
    Flag = "LimitJobs",
    Callback = function(Value)
        Limit:SetVisible(Value)
    end,
})
Limit = Jobs:CreateSlider({
    Name = "Max Jobs",
    Range = { 1, 20 },
    Increment = 1,
    CurrentValue = 5,
    Visible = false, -- hidden at start, still saved with the config
    Flag = "MaxJobs",
})

--------------------------------------------------------------------------------
-- Elements: added straight to a tab, every element is a full-width card
--------------------------------------------------------------------------------

local Elements = Window:CreateTab({ Name = "Elements", Desc = "Every element, full width", Icon = "layout-grid" })

Elements:CreateSection("Controls")

Elements:CreateButton({
    Name = "Button",
    Desc = "With a description and a tooltip",
    Icon = "mouse-pointer-click",
    Tooltip = "Any element accepts a Tooltip", -- a string, or { Title, Text, Icon }
    Callback = function()
        print("[Example] button")
    end,
})

Elements:CreateToggle({
    Name = "Toggle",
    Desc = "Tooltips can carry a title and an icon",
    Tooltip = { Title = "Toggle", Text = "Saved with the config through its Flag.", Icon = "info" },
    CurrentValue = false,
    Flag = "ElementToggle",
})

Elements:CreateSlider({
    Name = "Slider",
    Range = { 0, 100 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "ElementSlider",
})

Elements:CreateProgress({ Name = "Progress", CurrentValue = 0.65 })

Elements:CreateParagraph({
    Title = "Paragraph",
    Content = "Longer text wraps across as many lines as it needs.",
})

Elements:CreateCode({
    Name = "Code",
    Code = [[local Players = game:GetService("Players")
print("Hello", Players.LocalPlayer.Name) -- copy me]],
    Language = "lua",
})

Elements:CreateSection("Media and tables")

Elements:CreateImage({
    Name = "Image",
    Image = "Deep Violet", -- an asset id, rbxassetid:// or rbxthumb:// link, a web link, a background preset or "Avatar"
    Height = 140,
    Caption = "Images fade in once loaded",
})

Elements:CreateViewport({
    Name = "Viewport",
    Desc = "Drag to rotate",
    Model = "Avatar", -- any Model or part (copied), a Player, or "Avatar"
    Height = 200,
    SpinSpeed = 25,
})

do
    local Board = Elements:CreateTable({
        Name = "Leaderboard",
        Rank = true, -- a # column with medals for the top three
        Columns = {
            "Player",
            { Name = "Score", Align = "Right", Width = 0.2 },
            { Name = "Balance", Align = "Right", Width = 0.25, Format = function(Value) return "$" .. Value end },
        },
        Rows = {
            { "Player One", 42, 12500 },
            { "Player Two", 57, 9800 },
            { LocalPlayer.DisplayName, 31, 15200, Highlight = true },
            { "Player Four", 12, 300 },
            { "Player Five", 5, 150 },
        },
        SortBy = "Score", -- click a header to sort, again to flip, a third time to reset
        MaxRows = 6,
        Callback = function(Row, Index)
            print("[Example] row", Row[1], Index)
        end,
    })
    task.spawn(function()
        while task.wait(3) do
            local Row = Board.Rows[3]
            if not Row or not Window.Gui.Parent then
                break
            end
            Board:UpdateRow(3, { Row[1], Row[2] + math.random(0, 2), Row[3] + math.random(0, 400), Highlight = true })
        end
    end)
end

--------------------------------------------------------------------------------
-- Popups
--------------------------------------------------------------------------------

local Popups = Window:CreateTab({ Name = "Popups", Desc = "Notifications and dialogs", Icon = "bell" })

local Notifications = Popups:AddLeftGroupbox({ Name = "Notifications", Icon = "bell" })

for _, Kind in ipairs({ "Success", "Warning", "Error" }) do
    Notifications:CreateButton({
        Name = Kind,
        Callback = function()
            Library:Notify({
                Title = Kind,
                Content = "This is a " .. Kind:lower() .. " notification.",
                Type = Kind,
                Duration = 3,
            })
        end,
    })
end

local Dialogs = Popups:AddRightGroupbox({ Name = "Dialogs", Icon = "message-square" })

Dialogs:CreateButton({
    Name = "Confirm",
    Callback = function()
        Library:Confirm({
            Title = "Reset progress?",
            Content = "This cannot be undone.",
            ConfirmText = "Reset",
            CancelText = "Cancel",
            Callback = function()
                print("[Example] confirmed")
            end,
        })
    end,
})

Dialogs:CreateButton({
    Name = "Dialog",
    Callback = function()
        Library:Dialog({
            Title = "Choose a mode",
            Content = "You can change this later in Settings.",
            Buttons = {
                { Title = "Basic", Callback = function() print("[Example] basic") end },
                { Title = "Balanced", Callback = function() print("[Example] balanced") end },
                { Title = "Full", Variant = "Primary", Callback = function() print("[Example] full") end },
            },
        })
    end,
})

--------------------------------------------------------------------------------
-- Cloud: the library draws the browser, your script is the backend. This
-- keeps the store in a table; a real one would call an API in each callback.
--------------------------------------------------------------------------------

do
    local Current = Window:ExportConfig() -- the current settings as a code
    local Hour, Day = 3600, 86400
    local Store = {
        { Id = "1", Name = "Balanced", Author = "Example", Description = "Sensible defaults for most players.", Tags = { "General" }, Installs = 12840, Likes = 3110, Updated = os.time() - 5 * Hour, Code = Current },
        { Id = "2", Name = "Performance", Author = "Example", Description = "Lower intervals for faster runs.", Tags = { "Speed" }, Installs = 5420, Likes = 1987, Updated = os.time() - 2 * Day, Code = Current },
        { Id = "3", Name = "Overnight", Author = "Example", Description = "Slow and steady for long sessions.", Tags = { "General", "Safe" }, Installs = 22100, Likes = 4203, Updated = os.time() - 9 * Day, Code = Current },
        { Id = "4", Name = "Minimal", Author = "Example", Description = "", Tags = { "Safe" }, Installs = 870, Likes = 402, Updated = os.time() - 30 * 60, Code = Current },
    }
    local function Find(Id)
        for Index, Config in ipairs(Store) do
            if Config.Id == Id then
                return Config, Index
            end
        end
    end

    Window:CreateCloudConfigs({
        Name = "Cloud",
        Tags = { "General", "Speed", "Safe" },
        PageSize = 10,
        OnFetch = function(Query) -- { Search, Sort, Filter, Tag, Page, PageSize, Folder, UserId }
            task.wait(0.4) -- simulated request
            local Result = {}
            for _, Config in ipairs(Store) do
                local Match = Query.Search == "" or Config.Name:lower():find(Query.Search:lower(), 1, true) ~= nil
                if Match and Query.Tag then
                    Match = table.find(Config.Tags, Query.Tag) ~= nil
                end
                if Match and Query.Filter == "Mine" then
                    Match = Config.OwnerId == Query.UserId
                end
                if Match then
                    table.insert(Result, Config)
                end
            end
            table.sort(Result, function(A, B)
                if Query.Sort == "New" then
                    return A.Updated > B.Updated
                elseif Query.Sort == "Installs" then
                    return A.Installs > B.Installs
                end
                return A.Likes > B.Likes
            end)
            local First = (Query.Page - 1) * Query.PageSize
            return { table.unpack(Result, First + 1, math.min(First + Query.PageSize, #Result)) }, First + Query.PageSize < #Result
            -- on failure: return nil, "reason"
        end,
        OnPublish = function(Config) -- { Name, Description, Tags, Code, Count, Folder, Author, AuthorId, OwnerId, Streamer }
            task.wait(0.3)
            Config.Id = tostring(os.clock())
            Config.Installs, Config.Likes, Config.Updated = 0, 0, os.time()
            table.insert(Store, 1, Config)
            return Config -- or false, "reason"
        end,
        OnUpdate = function(Record, Changes) -- Changes.Code is nil when the settings are kept
            local Config = Find(Record.Id)
            for Key, Value in pairs(Changes) do
                Config[Key] = Value
            end
            Config.Updated = os.time()
        end,
        OnDelete = function(Record)
            local _, Index = Find(Record.Id)
            table.remove(Store, Index)
        end,
        OnLike = function(Record, Liked)
            local Config = Find(Record.Id)
            Config.Likes += Liked and 1 or -1
        end,
        OnInstall = function(Record)
            Find(Record.Id).Installs += 1
        end,
        OnReport = function(Record, Reason)
            print("[Example] reported", Record.Name, Reason)
        end,
    })
end

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

local Settings = Window:CreateTab({ Name = "Settings", Icon = "settings" })

local Interface = Settings:AddLeftGroupbox({ Name = "Interface", Icon = "monitor" })

Interface:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    OnChanged = function(Key)
        Window:SetKeybind(Key)
    end,
})

Interface:CreateDropdown({
    Name = "Toggle Button",
    Options = { "Mobile only", "Mobile & PC" },
    CurrentOption = "Mobile only",
    AllowNone = false,
    Flag = "ToggleButtonPlatform",
    Callback = function(Option)
        Window:SetToggleButtonPlatform(Option == "Mobile & PC" and "Both" or "Mobile")
    end,
})

Interface:CreateToggle({
    Name = "Backdrop",
    CurrentValue = true,
    Flag = "Backdrop",
    Callback = function(Value)
        Window:SetBackdrop(Value)
    end,
})

Interface:CreateSlider({
    Name = "Backdrop Tint",
    Range = { 0, 90 },
    Increment = 5,
    Suffix = "%",
    CurrentValue = 45,
    Flag = "BackdropTint",
    Callback = function(Value)
        Window:SetBackdropTint(Value / 100)
    end,
})

Interface:CreateButton({
    Name = "Unload",
    Icon = "power",
    Callback = function()
        Library:Confirm({
            Title = "Unload Example?",
            ConfirmText = "Unload",
            Callback = function()
                Window:Destroy()
            end,
        })
    end,
})

Settings:CreateConfigManager({ Name = "Configs", Side = "Left" }) -- builds its own groupbox
Settings:CreateThemeManager({ Name = "Themes", Side = "Right" })

Window:LoadAutoload() -- loads the config marked as autoload, if any
