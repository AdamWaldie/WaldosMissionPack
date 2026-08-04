# Safestart

Freezes all players at mission start — the reversible mirror of ENDEX.
While active: weapons safe, every shot/grenade/launcher/vehicle-weapon round
is deleted, players take/deal no damage, players are confined to a safe
zone, and an on-screen banner shows (with a live countdown if a timer is
running). JIP and respawning players are re-frozen automatically.

## Config (`initServer.sqf`) — auto-starts by default

```sqf
missionNamespace setVariable ["Waldo_SafeStart_Confine", true, true];   // safe-zone confinement on/off
missionNamespace setVariable ["Waldo_SafeStart_Radius", 75, true];      // per-player radius (metres)
missionNamespace setVariable ["Waldo_SafeStart_ZoneMarker", "", true];  // marker name for one shared zone (else per-player anchor)
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", true, true]; // false = no safestart at start
```

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
can overrule the countdown at any time).
