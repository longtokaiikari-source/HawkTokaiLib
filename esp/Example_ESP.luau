-- Example_ESP.luau: the ESP on its own. It loads HawkTokaiLib (Source.luau) from its repo, then the ESP (ESP.luau).

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

-- The ESP is a separate package: load it after the library, from its own file.
Library.ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/ESP.luau"))()(Library)


-- Build makes one page for each feature: Players, Names, Boxes, Highlight, Tracers, Health, Skeleton, Arrows,
-- Visibility, Overlay, Colours and Preview. Each page turns its own feature on; nothing is on until its page says so.
-- Everything a page sets is also in Library.ESP, so a script can change the same settings without the tab.
local Esp = Window:CreateTab({ Name = "ESP", Desc = "One page for each feature", Icon = "users" })
Library.ESP:Build(Esp, Window)

-- Objects: ESP for one model you pick. Add takes any Model or Part. A setting you leave out keeps its default.
-- The object draws until you Destroy it, the model leaves the game, or the window unloads (the Unload button).
local EspObjects = Esp:CreateSubTab({ Name = "Objects" })
-- A row of pills for one mode out of a few (the segmented control).
local EspModes = EspObjects:AddRightGroupbox({ Name = "Modes", Icon = "layout-grid" })
EspModes:CreateSegmented({ Name = "Mode", Desc = "One of a few modes", Options = { "Off", "Low", "High" }, Default = "Low", Callback = function(value)
    Library:Notify({ Title = "Mode", Content = tostring(value), Duration = 2 })
end })
local EspSingle = EspObjects:AddLeftGroupbox({ Name = "One model", Icon = "crosshair" })
local EspTarget = nil -- the object Library.ESP:Add returned, or nil when there is none

-- BeforeUpdate runs before the components draw the frame, so a color set here is the color that is drawn.
local function colorByDistance(object)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local near = root ~= nil and (object.CurrentSettings.Model:GetPivot().Position - root.Position).Magnitude < 50
    object.CurrentSettings.Color = near and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(255, 200, 0)
end

EspSingle:CreateButton({
    Name = "ESP the model named Target",
    Style = "Primary",
    Callback = function()
        if EspTarget and not EspTarget.Deleted then
            Library:Notify({ Title = "ESP", Content = "Target already has ESP.", Duration = 2 })
            return
        end
        local model = workspace:FindFirstChild("Target")
        if not model then
            Library:Notify({ Title = "ESP", Content = "There is no model named Target in the workspace.", Duration = 3 })
            return
        end
        EspTarget = Library.ESP:Add({
            Model = model,
            Name = "Target",
            ESPType = "Highlight", -- Highlight, SelectionBox, SphereAdornment, CylinderAdornment, Adornment or Text
            MaxDistance = 2000,
            Box2D = { Enabled = true, Color = Color3.fromRGB(255, 200, 0), Filled = false },
            Tracer = { Enabled = true, From = "Bottom", Color = Color3.fromRGB(255, 200, 0) }, -- Top, Bottom, Center or Mouse
            Health = { Enabled = true }, -- a health bar, added to the defaults
            BeforeUpdate = colorByDistance,
            OnDestroyFunc = function()
                EspTarget = nil
            end,
        })
        Library:Notify({ Title = "ESP", Content = "Target has ESP now.", Duration = 2 })
    end,
})

EspSingle:CreateButton({
    Name = "Show or hide it",
    Callback = function()
        if EspTarget and not EspTarget.Deleted then
            EspTarget:ToggleVisibility()
        end
    end,
})

EspSingle:CreateButton({
    Name = "Remove it",
    Callback = function()
        if EspTarget then
            EspTarget:Destroy() -- OnDestroyFunc clears EspTarget
        end
    end,
})

EspSingle:CreateButton({
    Name = "Clear every ESP object",
    Callback = function()
        -- Removes the objects you added. The Players tab and the preview make their own again on the next frame.
        Library.ESP:Clear()
    end,
})
