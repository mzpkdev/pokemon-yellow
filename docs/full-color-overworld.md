# Full-color overworld

The saved `OVERWORLD` option controls only map rendering:

- `ORIGINAL` keeps Pokemon Yellow's existing whole-screen and tinted palettes.
- `FULL` enables static, per-tile daytime CGB colors on supported overworld
  tilesets after the next map load or transition.

`ORIGINAL` is the default for a new save. The setting is stored in an unused
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
The existing five-palette tint refresh is suppressed only while FULL is active
with the overworld palette command; battle and non-overworld commands continue
through the original palette path.

The debug ROM's hidden title-screen `SELECT` menu starts `DEBUG` games outside
the Viridian Pokemon Center with FULL enabled. PyBoy coverage captures the
initial outdoor view, horizontal and vertical scrolling, menu and dialogue
restoration, bicycle transitions, and representative interiors: the Pokemon
Center, Mart, Viridian School, Red's house, Oak's Lab, and Mt. Moon.
