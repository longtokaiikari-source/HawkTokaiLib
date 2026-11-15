# Changelog

Every notable change to HawkTokaiLib is listed here, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Upgrade notes

- The Loader and the Example have changed. Paste the new `Loader.luau` into your executor, and the new `Example.luau` into Junkie's Original Code.
- `EasterEgg` is set in the Loader's `RunProtected` options, or in `Home.EasterEgg`. It is no longer in the key gate.
- The window starts with the normal text (`None`). Players pick a font in Configs > Font.

### Added

- **Executor check** before the key gate. It runs the UNC tests and stops the load below 70 (`UNC = { Fail = 70, Warn = 80 }`), shows a banner from 70 to 79, and loads normally from 80. `UNC = false` skips it. `Library:GetExecutorScore()` returns the score.
- **Status cards** while the executor check runs and while the protected script loads. The window's own loader takes over when the window opens.
- **Close button** on the key gate. It closes the gate and stops the load.
- **Fonts**: a Font picker in Configs with 17 fonts. Fifteen come with Roblox and need no download. Two are downloaded presets: `Tahoma8` (pixel Tahoma 8px) and `ValleySans`. The choice is saved with the configs. API: `Library:SetFont`, `Library.FontPresets`, `Library.BuiltinFonts`, `Library.FontOrder`, `Library.DefaultFont`.
- **Background music**: `Window:SetMusic`, `SetMusicPlaying`, `IsMusicPlaying`, `SetMusicVolume`, `GetMusicVolume`. A Music group appears in Configs once a track is set.
- **3D preview toolbar**: reset the view, pause or play the spin, zoom in, zoom out, and cycle the lighting presets. The mouse wheel zooms while the pointer is over the preview. Lighting presets live in `Library.ViewportLights`. New options: `Lighting`, `Glow`, `Shadow`, `Toolbar`. New methods: `SetPitch`, `Zoom`, `ResetView`, `SetLighting`, `SetGlow`, `SetShadow`, `GetInfo`.
- **Dependency boxes**: `Tab:DependencyBox({ Depends = toggle, Value = true })` shows its controls only while the other control holds that value.
- **Log element**: `Tab:Log` with timestamps, colours, a Clear button, and the methods `Log`, `Clear` and `GetLines`.
- **One-time welcome**: `Window:Welcome({ Key, Title, Text, Button })` and `Window:ResetWelcome(key)`.
- **`Window:OnUnload(callback)`** runs when the window is destroyed. Use it to stop your own loops and connections.
- **Hidden egg on Home**: a Code input that stays hidden until you tap the Home avatar five times within four seconds. Typing the secret phrase shows a Play button. Play shows a picture full screen with a sound, then kicks the player. Both files download into the workspace folder.
- **Motion**: buttons squeeze when pressed and spring back, and the ripple starts at the press point. A band of light sweeps across a button on hover. Dialog buttons get the same press feel. A keybind waiting for a key shows three bouncing dots.
- **Button wave**: the press ripple is a wave of light from the press point that spreads toward the corners and fades as it goes.
- **Keybind ring**: while a keybind waits for a key, a soft ring breathes around the box.
- **Input underline**: an accent line grows out from the middle while the field has focus.
- **3D preview**: zoom and reset ease in; a flick keeps the model turning; drag up or down to tilt; two quick presses reset the view; the glow brightens on hover.
- **Popped-out preview**: a 3D preview inside a popped-out group box has a grip in its bottom-right corner; drag it to resize the preview.
- **UNC cache**: a passing executor check is kept for six hours (`UNC = { Cache = false }` turns that off). A failing card lists the missing features.
- **Check progress**: the executor check shows a progress bar with the number of tests done.
- **Floating group boxes**: a popped-out box has a grip in its bottom-right corner that changes its width, kept for the next pop-out. Pressing a floating box brings it to the front of the others.
- **Preview pop-out**: the 3D preview has a pop-out button in its header, like a group box's. It floats the preview in its own panel, which the header drags; the button or the slot docks it back with the same flight as a group box. A floating preview's grip changes its width and height.
- **ESP port**: `Library.ESP` now has the original's objects and settings: `Add`, `Clear`, `Destroy`, per-object settings, the Highlight, SelectionBox and adornment types, the Tracer `Top` origin, the Arrow, the filled 2D box, the 3D box, the skeleton, the four callbacks and the global names. A health bar is added. The port follows mstudio45/msesp v2.1.4 (MIT).
- **ESP preview**: `Library.ESP:AttachPreview(handle)` draws the ESP over a 3D preview with the same settings and components as the game, without the highlight.
- **Viewport handles**: a viewport handle now exposes `Window`, `Media`, `Camera` and `World`, so an overlay can draw on it.
- **ESP tests**: `tests/esp_test.lua` is plain Lua, with no Python. It runs the ESP against a mock of the Roblox API and checks geometry, rules, components, callbacks and cleanup. It does not render.
- **Brand mark**: a round badge with an accent ring on the window header, the loader and the key gate.
- **Discord invite** `https://discord.gg/deVVQEVybd` is used by the Home example, the key gate and the executor card.
- **Player list**: `Tab:PlayerList({ Name, Height, Actions })`, a live list of the players in the server. Each row has the avatar, the name, the team colour and the distance, and a small button for each action you give it. Rows follow players joining and leaving.
- **ESP corner box**: `Box2D.Style = "Corner"` draws eight short corner lines. `"Full"` (the default) keeps the box with a black outline under the coloured line.
- **ESP text like the original**: the name sits above the box and the distance below it. Distances read in metres by default (`ESP.GlobalConfig.Meters = false` for studs), and the text scales with the box (`ESP.GlobalConfig.DynamicText`).
- **ESP health bar sides**: `Health.Side` is Left, Right or Bottom. `Health.Gradient` colours the bar from red to green.
- **ESP tracer target**: `Tracer.To` is Feet (the default), Center or Head.
- **R6 and R15 tests**: the test checks both rigs side by side, with the skeleton bones, the box, the health bar and the text.
- **ESP highlight depth**: `HighlightDepth` is `"Through walls"` (the default, always on top) or `"Behind walls"` (occluded by walls). Adornments and selection boxes follow it too. The fill and outline transparency have sliders.
- **ESP visible check**: `GlobalConfig.VisibleCheck` colours a player you can see and one behind a wall in two colours (`VisibleColor` and `HiddenColor`). `GlobalConfig.VisibleOnly` hides the players behind a wall. A ray from the camera to the head decides, and the local character and the player are not in the way.
- **ESP health number**: `GlobalConfig.HealthText` writes the health beside the health bar.
- **ESP head dot**: `GlobalConfig.HeadDots` draws a small dot on each head in view.
- **ESP held item**: `GlobalConfig.ShowTool` adds the tool a character holds after its name.
- **ESP distance fade**: `GlobalConfig.Fade` fades the name and the 2D box with the distance, from `FadeStart` of the max distance (default 0.6).
- **FOV circle and crosshair**: `GlobalConfig.FOV` with `FOVRadius` draws a ring around the centre of the game view, and `GlobalConfig.Crosshair` draws a crosshair there.

### Changed

- The example's ESP tab shows the automatic players, ESP for one model with `Library.ESP:Add`, and the show, remove and clear buttons.
- The ESP API is replaced by the port's: `Add`, `Clear`, `Destroy`, `AttachPreview`, `Players`, `Settings` and `GlobalConfig`. The old `Start`, `Stop`, `Attach`, `Detach`, `Shutdown` and `Config` are gone. The tab is still `Library.ESP:Build(sub, Window)`.
- The executor check waits at most four seconds for a character, and stops waiting for slow tests after twelve seconds.
- Key gate redesign: wider panel, brand badge, a "Secured with Junkie" chip, a focus ring on the key input, and hover and press feel on its buttons.
- Keybind waiting state shows dots instead of `...`.
- Button ripple starts on press instead of on release.
- 3D preview: a drag does not start on the toolbar.
- The Loader and the Example no longer force a font.
- README and llms.txt document all of the above.
- **Press feel on every small button**: a press squeezes the button to 97%, and the release eases back without overshooting. The light sweeps across the visible shape only. Settings button rows, home quick actions and the dropdown's Select all and Clear all use the same feel.
- **FPS and ping history**: each bar keeps the colour it was read with. The newest bar is strongest, older bars fade, and empty slots are dim.
- **Execs**: the count on the home card is read again on every stats tick, so a run from another session shows up.
- **ESP measures every object in front of the camera**, so the text, the health bar and the tracer all have the box to work from.
- **ESP arrow** is drawn with lines, in the box's style: a black outline under the coloured line, with the name and distance behind the tail. It reads the target's place in the camera's own frame, so it points the right way behind the camera too. `Arrow.Size` (default 12) sets its size, with a slider in the drawing tab. It used to be an image from the web.

### Fixed

- The SelectionBox border colour has a default now. The original reads a `BorderColor` it never sets, which errors for the `SelectionBox` type.
- 3D preview drag on touch screens follows the finger, so dragging right turns the model right.
- Button wave now starts where the mouse or finger really pressed. Before, a touch screen could show it in a fixed spot.
- Button wave: presses on the right side of a button no longer show the wave toward the middle when the window is scaled down. The wave is now placed in the button's own units.
- Sliders jumped to the pointer when pressed in the empty space above or below the bar. The press catcher now hugs the bar, so only the bar and the knob start a drag.
- Bold text fell back to BuilderSans when the chosen font family had no bold face. It now falls back to that family's regular face.
- The egg no longer needs a Roblox video upload.
- **Preview spins again after it is popped out.** The window called its listeners one after another without protection, so one listener that errored stopped the rest, the preview's spin among them. Each listener now runs under `pcall`, and a failing one is reported once.
- **Button wave no longer spills out.** Compact buttons drew the wave over the whole card, description included. The wave, the squeeze and the light now belong to the visible box.
- **One wave per click.** Compact buttons, home quick actions and the dropdown no longer draw a second wave on click.
- **Report popup**: the reasons sit in a grid inside the card. Before, four reasons ran past the card's left edge.
- **Buttons that size themselves to their text** no longer stretch on press. They show a press as a colour change, because a button that follows its own text cannot hold a child sized by scale.
- **A popped-out preview keeps spinning** while the main window is closed.

### Removed

- `tokaihub-esp.luau`, the standalone copy of mstudio45/msesp: `Library.ESP` replaces it. The copy had a second block after its final `return`, so it did not load, and its `SelectionBox` read a `BorderColor` it never set.
- `assets/egg.mp4` is no longer used, so it is left out of the package. The video showed a black screen with no sound on the tested executor.
- The hidden egg in the key gate, moved to Home.
- The forced `Tahoma8` font in the Loader and the Example.
- The music track and its ID from the Example.

## [0.1.0] - the fork

The first version of the library, forked from an earlier UI project and rebranded as HawkTokaiLib. Every reference to the old name is replaced.

### Added

- Watermark with a corner readout (`SetWatermark`, `SetWatermarkEnabled`).
- Keybind list overlay (`SetKeybindListVisible`).
- `BindToggle` with Toggle and Hold modes.
- Code block element with a copy button and Lua syntax highlighting.
- World clock on Home with 38 time zones (GMT-12 to GMT+14), shared with the watermark.
- Edge glow on the sub-tab row.
- 3D viewport with a gradient backdrop, an accent glow, a ground shadow and warmer default lighting.
- Key system: `RequireKey` with Keys, Validate and Junkie support, a saved key, and `RunProtected`.
- Junkie SDK integration for the key check and the key link.
- The HawkTokai logo, embedded in the library.

### Changed

- The license card is removed from Home. The key expiry moved to the profile chip.
