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
- **Brand mark**: a round badge with an accent ring on the window header, the loader and the key gate.
- **Discord invite** `https://discord.gg/deVVQEVybd` is used by the Home example, the key gate and the executor card.

### Changed

- The executor check waits at most four seconds for a character, and stops waiting for slow tests after twelve seconds.
- Key gate redesign: wider panel, brand badge, a "Secured with Junkie" chip, a focus ring on the key input, and hover and press feel on its buttons.
- Keybind waiting state shows dots instead of `...`.
- Button ripple starts on press instead of on release.
- 3D preview: a drag does not start on the toolbar.
- The Loader and the Example no longer force a font.
- README and llms.txt document all of the above.

### Fixed

- 3D preview drag on touch screens follows the finger, so dragging right turns the model right.
- Button wave now starts where the mouse or finger really pressed. Before, a touch screen could show it in a fixed spot.
- Button wave: presses on the right side of a button no longer show the wave toward the middle when the window is scaled down. The wave is now placed in the button's own units.
- Sliders jumped to the pointer when pressed in the empty space above or below the bar. The press catcher now hugs the bar, so only the bar and the knob start a drag.
- Bold text fell back to BuilderSans when the chosen font family had no bold face. It now falls back to that family's regular face.
- The egg no longer needs a Roblox video upload.

### Removed

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
