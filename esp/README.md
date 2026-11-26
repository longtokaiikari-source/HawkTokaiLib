# ESP

The ESP for HawkTokaiLib, in this folder. `Source.luau` never loads it: a script loads `ESP.luau` at the root of the repo only when it wants the ESP, and it needs `Source.luau` loaded first.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/Source.luau"))()
Library.ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/ESP.luau"))()(Library)
```

`Example_ESP.luau` is the ESP on its own, with a window and the ESP tab.

## ESP
`Library.ESP` has its own objects, settings, callbacks and components. The drawing uses Frames, so one code path draws over the game and over a 3D preview.

```lua
local object = Library.ESP:Add({ Model = character, ESPType = "Highlight", Box2D = { Enabled = true } })
object:Hide()                              -- or :Show(), :ToggleVisibility(), :SetEveryColor(color, true)
object:Destroy()
Library.ESP:Clear()                        -- removes every object
Library.ESP:Destroy()                      -- removes everything, the preview too

Library.ESP.GlobalConfig.Rainbow = true    -- also Billboards, Distance, Highlighters, Tracers, Arrows, Boxes2D, Boxes3D, Skeleton, Health, Font, IgnoreCharacter
Library.ESP.Players.Enabled = true         -- one ESP per player, with HideTeammates and AllyColor
Library.ESP.Settings.Box2D.Enabled = true  -- the template for the players and the preview
Library.ESP:ApplyTemplate()                -- pushes the template to the objects that exist
Library.ESP:AttachPreview(viewportHandle)  -- the ESP over a Tab:Viewport
Library.ESP:Build(tab, Window)             -- the ESP tab: one page for each feature, colours and a preview
```

Settings per object are: `Name`, `Model`, `TextModel`, `Visible`, `Color`, `MaxDistance` (default 5000), `StudsOffset`, `TextSize`, `ESPType` (`Highlight`, `SelectionBox`, `SphereAdornment`, `CylinderAdornment`, `Adornment`, `Text`), `Thickness`, `Transparency`, `SurfaceColor`, `BorderColor`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`. The components are `Tracer` (`From`: `Top`, `Bottom`, `Center`, `Mouse`), `Arrow` (`CenterOffset`), `Box2D` (`Filled`), `Box3D` and `Skeleton`, plus `Health`. The callbacks are `OnDestroy`, `OnDestroyFunc`, `BeforeUpdate` and `AfterUpdate`.

`Highlight`, `SelectionBox` and the handle adornments need the world, so they are drawn in the game only. The preview draws the boxes, the skeleton, the tracer, the arrow, the names and the health bar. The name is a Frame label, so `Font` takes a Font object, not an `Enum.Font`.

### Looks: box, text, health and tracer

`Box2D.Style` is `"Full"` (a box with rounded corners, 4 px, and a black outline) or `"Corner"` (eight corner lines). `Health.Side` is `"Left"`, `"Right"` or `"Bottom"`, and `Health.Gradient` runs a green, yellow and red gradient along the bar (green at full, yellow at half, red when empty); the part that is missing is covered with the dark track. The bar has a black outline and rounded corners, and the health number sits right against the bar. Damage numbers (the toggle on the Health page, `GlobalConfig.DamageText`) write a red `-N` or a green `+N` over a player when its health changes; each one rises and fades in about a second, and the feature is off by default. `Tracer.To` is `"Feet"` (the default, the bottom middle of the box), `"Center"` or `"Head"`. The name sits above the box and the distance below it. `ESP.GlobalConfig.Meters` (on by default) reads distances in metres, and `ESP.GlobalConfig.DynamicText` scales the text with the box. R6 and R15 both get the box from the character's bounding box and their own skeleton.

The arrow for a target off the screen or behind you is drawn with lines, like the box. `Arrow.Shape` is `"Arrow"` (the default: a round shaft with a diamond head), `"Chevron"` (two round wings) or `"Dot"` (a round marker). `Arrow.Placement` is `"Edge"` (the default: the arrow sits on the screen's edge, pulled in by `Arrow.Margin`, default 60 px) or `"Ring"` (on a circle around the centre, at `Arrow.CenterOffset` px at 1080p, default 300). `Arrow.Size` sets its size (default 12). `Arrow.Outline` draws the black line under the coloured one (default on). `Arrow.ScaleByDistance` makes closer targets bigger, `Arrow.FadeByDistance` dims far ones, `Arrow.MaxDistance` hides targets beyond that many studs (0 means no limit), and `Arrow.Pulse` breathes while a target is within 60 studs. The name and the distance sit just behind the arrow and are kept inside the screen.

The highlight can see through walls (`HighlightDepth = "Through walls"`, the default) or not (`"Behind walls"`). The visible check (`GlobalConfig.VisibleCheck`) colours players you can see and players behind a wall in two colours, and `GlobalConfig.VisibleOnly` hides the second kind. `GlobalConfig.HealthText`, `HeadDots`, `ShowTool`, `Fade`, `FOV`, `FOVRadius` and `Crosshair` turn on the health number, the head dot, the held item, the distance fade, the FOV ring and the crosshair. The Drawing tab has a control for each.

The ESP tab has seven pages, two features side by side on most of them: Players (Players and Visibility), Boxes (Boxes and Names), Highlight (Highlight and Overlay), Lines (Tracers and Arrows), Health (Health and Skeleton), Colours (Colours and Presets) and Preview. Each feature turns itself on. Nothing is on until its page says so, there is no master switch, and the players are always watched.

Names has the display name and the team name. The Speed toggle adds the horizontal speed beside the distance, in metres per second, or studs per second when Distance in metres is off. Falling does not count, and it is off by default. Colours has the team colours and the friend colour, and a friend's colour wins over the team's. Overlay has the radar, with its range and size. The radar marks your own character in the middle: a white dot with a black outline and a pointer that always points up, because the radar turns with the view. Visibility has how many frames pass between two looks at a player for the visible check.

The wall check (Visibility group on the Players page) draws a player green when any part of it can be seen, which covers a hand or a foot showing from behind a wall, and red when none can. It looks at the head, the body, the hands and the feet, or the six parts of an R6. Parts that cannot collide and see-through parts do not block it, and other players do not block it either. A player behind the camera is red.

The Players page has a Show dead option (dead players in grey) and a Nearest players limit. The Presets group on the Colours page copies the settings as text and applies a preset back. `Tab:Segmented` is a row of pills for choosing one of a few modes.

The ESP lives in its own file, `ESP.luau`. The library does not load it by itself: load it once, the way the top of this readme shows, before you use `Library.ESP` (`Example_ESP.luau` does). The URL in that snippet points at `ESP.luau` at the root of the HawkTokaiLib repository, so push `ESP.luau` there next to `Source.luau`, or change the URL if you host it elsewhere.

### Testing without Roblox

`tests/backdrop_test.lua` checks that the backdrop's light goes out with the Backdrop Tint. Run it the same way: `lua tests/backdrop_test.lua` from the project folder.

`tests/esp_test.lua` is plain Lua. It loads `ESP.luau`, runs it against a mock of the Roblox API, then runs a scenario. From the project folder, run it with Lua 5.3 or newer:

```
lua tests/esp_test.lua
```

It checks the geometry, the rules, the components, the callbacks and the cleanup. It does not render, so run it in a real executor before you trust a build.

## Credits

- **Developer:** longtokai
- **Testers:** dokkimane, longtokai

