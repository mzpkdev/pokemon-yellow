# Full-color overworld scope

The saved `OVERWORLD` option controls only map rendering:

- `ORIGINAL` keeps Pokémon Yellow's existing whole-screen and tinted palettes.
- `FULL` enables static, per-tile daytime CGB colors on supported overworld
  tilesets after the next map load or transition.

`ORIGINAL` is the default for a new save. The setting is stored in `wOptions2`
and therefore follows the existing new-save option persistence path. Save
migration is deliberately unsupported.

The MVP does not add night, time of day, seasons, snow, or other Celebrations
systems. Battles, menus, Pokémon pictures, and other non-overworld screens keep
their current palette behavior. DMG remains monochrome. Unsupported tilesets
and special redraws safely retain the original palette behavior.
