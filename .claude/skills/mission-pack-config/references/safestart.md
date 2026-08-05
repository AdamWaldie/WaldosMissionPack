# Safestart

Freezes all players at mission start — the reversible mirror of ENDEX.
While active: weapons safe, every shot/grenade/launcher/vehicle-weapon round
is deleted, players take/deal no damage, players are confined to a safe
zone, and an on-screen banner shows (with a live countdown if a timer is
running). JIP and respawning players are re-frozen automatically.

## Config (`MissionConfig\missionSystemsConfig.sqf`) — starts inactive by default

**Default flipped:** `Waldo_SafeStart_AutoStart` now defaults to `false`
(mission goes live immediately) — it used to default `true`. Also note
`Waldo_SafeStart_Radius` default is now `150`, not `75`.

```sqf
["Waldo_SafeStart_Confine", false, true],  // server: safe-zone confinement on/off
["Waldo_SafeStart_Radius", 150, false],    // server: per-player fallback radius (metres) when ZoneMarker is blank
["Waldo_SafeStart_ZoneMarker", "", false], // server: marker name for one shared zone (else per-player anchor)
["Waldo_SafeStart_AutoStart", false, true] // server: true = begin under protection; false (default) = start live
```

These are `server` entries (loaded by `initServer.sqf`, JIP-published where
marked `true`) — do not paste `setVariable` calls into `initServer.sqf`
yourself, edit the config file and let the loader publish them.

If a shared zone marker is used, it must exist in the mission (an Eden
Editor placement — instruction mode). If left `""`, each player gets a
per-player radius anchor instead — no marker needed.

## Scripting API (server-authoritative, safe from a client)

```sqf
[true]  call Waldo_fnc_SafeStart;        // activate
[false] call Waldo_fnc_SafeStart;        // go live (admin overrule; also cancels any countdown)
[300]   call Waldo_fnc_SafeStartTimer;   // go live automatically in 300s (banner shows the clock)
```

Manual and timed go-live notices explain which protections were removed and
stay visible for `Waldo_SafeStart_GoLiveHintDuration` seconds (default 12).

## Relationship to ENDEX

Separate authoritative state — see `endex-aar.md`.

## Zeus ("Waldos Mission Modules")

**Safestart - Activate**, **Safestart - Go Live (Lift)**, and **Safestart -
Start Go-Live Countdown** (seconds, displayed as `MM:SS`; the Lift module
can overrule the countdown at any time). Since Safestart now starts inactive
by default, a mission that wants a protected start either sets
`Waldo_SafeStart_AutoStart` to `true` in the config, or a curator uses the
Activate module after mission start.
