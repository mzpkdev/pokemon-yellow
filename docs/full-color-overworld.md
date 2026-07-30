# Full-color overworld

The saved `OVERWORLD` option controls only map rendering:

- `CLASSIC` keeps Pokemon Yellow's existing whole-screen and tinted palettes.
- `COLOR` enables static, per-tile daytime CGB colors on supported overworld
  tilesets after the next map load or transition.

`CLASSIC` is the default for a new save. The setting is stored in an unused
bit of `wOptions2`, so it follows the existing save path without adding SRAM or
a migration layer. Existing saves are not supported.

## MVP coverage

- `OVERWORLD` and `FOREST` use daytime tile assignments adapted from
  Celebrations.
- `MART` and `POKECENTER` share the Celebrations Pokemon Center assignment.
- `CAVERN` uses a conservative cave assignment.
- Other indoor tilesets use a generic, low-contrast indoor assignment.
- `PLATEAU` uses the outdoor assignment.
- `BEACH_HOUSE` uses the generic indoor fallback. It does not use
  Celebrations' slot 24 Safari data because the target tileset is different.
- Tile IDs outside the supported `$00`-`$5f` range use the text/default
  palette. Town-specific roofs, night, snow, seasons, and unique sprite colors
  are intentionally deferred.

The MVP does not add night, time of day, seasons, snow, or other Celebrations
systems. Battles, menus, Pokemon pictures, and other non-overworld screens keep
their current palette behavior. DMG remains monochrome.

Initial map attributes and scheduled scrolling rows or columns wait for a
VRAM-accessible LCD mode. No full-color work is added to the VBlank handler.
The existing five-palette tint refresh is suppressed only while `COLOR` is active
with the overworld palette command; battle and non-overworld commands continue
through the original palette path.

The debug ROM's hidden title-screen `SELECT` menu starts `DEBUG` games outside
the Viridian Pokemon Center with `COLOR` enabled. PyBoy coverage captures the
initial outdoor view, horizontal and vertical scrolling, menu and dialogue
restoration, bicycle transitions, and representative interiors: the Pokemon
Center, Mart, Viridian School, Red's house, Oak's Lab, and Mt. Moon.

The debug-only atlas additionally loads all 184 non-outdoor map headers through
the normal `EnterMap` path and captures every building and cave floor. A second
matrix captures all 13 Fly destinations beside their Pokemon Center or
equivalent landmark. These hooks and four request bytes do not exist in release
builds.
