# OG_core

Shared library for the `OG_*` / `skilltrees` addon family: theme (`OG.UI`), a
source-keyed stat modifier registry (`OG.Stats`), a generic per-SteamID data store
(`OG.DataStore`), permission checks (`OG.HasPermission`), access-rule matching
(`OG.MatchesAccess`), net helpers (`OG.Net`) and notifications (`OG.Notify`).

**Install this addon so its folder name sorts before the addons that use it**
(e.g. `OG_core` before `OG_stims`, `skilltrees`) — GMod's Lua autorun files across all
mounted addons execute in one alphabetical pass, and every consumer addon assumes
`OG.*` already exists by the time its own autorun file runs. `OG_core` is optional for
`skilltrees` (it nil-guards every OG.* call) but required for `OG_stims`.

See `sh_stats.lua` for the stat registry every buff-granting addon should use instead of
monkey-patching another addon's functions (which is how the old `og_medal` -> `skilltrees`
integration went stale).
