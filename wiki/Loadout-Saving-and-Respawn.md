# Loadout Saving and Respawn

> **Use this page when:** you need starting, manual or persistent player equipment across respawn, including ACRE2 radios.

Basic respawn loadout saving is automatic: the mission-start baseline is captured once, and the local respawn handler restores the last snapshot `Waldo_fnc_SaveLoadout` wrote - by default that means the manual **Loadout Save Point** ACE/vanilla action, since automatic capture on death (`Waldo_Respawn_SaveOnDeath` in `MissionConfig\logisticsConfig.sqf`) is off by default. Set it to `true` for players to instead respawn with whatever they were carrying at the moment of death. `respawnOnStart = -1` remains required. That first automatic capture waits a moment for a slower-loading client's gear to actually finish appearing before saving it as the baseline - a client that took a bit longer to load in still gets a correct starting kit, not an incomplete one.

## ACRE2-safe storage

When ACRE2 is loaded, every saved respawn and persistence loadout passes through `acre_api_fnc_filterUnitLoadout`. Unique classes such as `ACRE_PRC152_ID_7` are converted to base classes before storage. Without ACRE2, the original loadout is returned unchanged.

`Waldo_fnc_SaveLoadout` also captures supported player-level radio state separately. After respawn,
WMP waits with a deadline for ACRE to create fresh unique IDs, then restores the channel/frequency,
ear, volume, supported audio source and selected radio from the player's last loadout save. The
current side/group mission plan remains the initial setup and safe fallback when the saved snapshot
is missing or cannot match the new inventory. Newly picked-up radios are not retuned merely because
the player changes group.

Persistence can optionally store radio state separately by base class plus deterministic same-type occurrence. It preserves channel or WMP-known manual frequency, ear, volume, audio source and the selected radio. Alternate PTT and speaker mode are never changed. A manually tuned frequency that was not applied by WMP cannot be read through ACRE's public API, so it cannot be reconstructed; configured WMP frequency assignments can.

For a PRC-343, ACRE reports one absolute position across its 16 blocks. WMP converts that value
back to `[block, channel]` when the player saves, so changes to either knob survive respawn. Two
radios of the same type remain separate as occurrence 1 and occurrence 2, including independent
left/right/both ear settings.

This separation is necessary because the inventory is only the container for a radio item. ACRE's
live channel and spatial settings belong to that player's temporary unique radio instance. They are
therefore player-level state, not additional fields inside `getUnitLoadout`. `SaveLoadout` and
`Waldo_Persistence_SaveLoadout` and `Waldo_Persistence_SaveRadios` are independent cross-session
switches. Ordinary `Waldo_fnc_SaveLoadout` still preserves both inventory and supported radio state
for mission respawns regardless of whether INIDBI2 radio persistence is enabled.

Ordinary respawn snapshots stay on that player's client and are tagged with Steam UID and side only -
a scripted respawn always creates a fresh, unnamed unit object, so identity cannot key off a
playable-slot variable name. INIDBI player records are server-owned, UID-separated and
mission-scoped by default; set `Waldo_Persistence_Scope = "CAMPAIGN"` only for intentional
cross-mission saves.

Restore order is:

1. filtered base-class unit loadout;
2. bounded wait for fresh unique radio IDs;
3. the last local respawn radio snapshot, or persisted radio state when loading INIDBI2 data;
4. the current mission plan only when no usable snapshot exists.

Persisted state therefore wins over baseline retuning without ever storing `_ID_n` classnames. If state restoration fails or the expected occurrence is missing, WMP logs the problem and falls back to the current mission plan.

At join/JIP, WMP explicitly waits for the server to answer `FOUND`, `NONE` or `FAILED`. `FOUND`
restores the saved player state before automatic writes are permitted. `NONE` applies and captures
the current `acreConfig.sqf` baseline before the first write. `FAILED`, including a 30-second missing
response, releases ordinary ACRE and mission startup but keeps that client's persistence writes
disabled for the session. This fail-open gameplay/fail-closed saving split prevents persistence from
breaking the main radio system or overwriting an unread database record.

ACRE generates fresh unique IDs after a filtered loadout restore. WMP therefore guarantees occurrence identity—first PRC-152, second PRC-152—not the identity of a particular transient `_ID_n` item. Occurrence follows ACRE's canonical carried-radio order, which is also what ACRE's repeated-radio setup API uses. WMP deliberately does not sort unique IDs independently. Explicit mission assignments manage only their listed occurrences; additional same-type radios are preserved.

## Manual saving

Starter crates and loadout-save points call:

```sqf
[] call Waldo_fnc_SaveLoadout;
```

Pass `[false]` for automatic startup work that must not display a notification over the loading presentation. Explicit player saves use the WMP notification UI and replace their prior message instead of growing the queue.

ACE Respawn can conflict with this mission-owned restore path and should remain disabled in ACE addon settings.

## Side-switch respawn seeding

**What this is for:** if Zeus (or a script) moves a player to a different side mid-mission, WMP has
never seen them on that side before, so without this setting they'd just respawn with a bare
class-default kit there instead of anything real. This fixes that automatically, the first time it
happens for each player. On by default.

```sqf
// MissionConfig\logisticsConfig.sqf
["Waldo_Respawn_SeedOnSideSwitch", true], // false = go back to a bare class-default kit on first switch
["Waldo_Respawn_SideSwitchMode", "CARRY_OVER"], // CARRY_OVER (default) or SIDE_BASE_LOADOUT
```

Pick a mode:

- **`CARRY_OVER`** (default, simplest): the player keeps exactly what they had, gear and radios
  included. Their radio stays tuned to their *old* side's channels - which is usually what you want,
  since it means they can still talk to their old squad after the switch.
- **`SIDE_BASE_LOADOUT`**: the player instead gets a random matching kit assembled from whatever
  loadouts you've placed on the new side in Eden (a real weapon with ammunition that actually fits
  it, not a random grab-bag), with their radio properly retuned to the new side's own channels. If
  nothing usable is placed on that side yet, it automatically falls back to `CARRY_OVER` instead of
  leaving the player with nothing.

This only ever applies the *first* time a player lands on a side with nothing saved for them there.
Once WMP has a saved kit for a player on a given side, switching to and from that side always
restores their own saved kit from then on, exactly like ordinary respawn.

Check current state under **WMP Diagnostics**: `respawn/snapshot-origin` shows which mode the
player's current side came from, and `respawn/side-switch-seed` shows whether/when a seed ran and
whether `SIDE_BASE_LOADOUT` had to fall back, with a fix hint if so. See
[Mission Diagnostics](Mission-Diagnostics).

## ACE 3.21.1 name warning

ACE 3.21.1 changed `ace_common_fnc_setName` from one argument to two: the unit object and an optional
Boolean **force set name** flag. Its extended Respawn handler still forwards Arma's normal
`[new unit, old corpse]` event payload, which places the corpse object in that Boolean slot and logs
`Type Object, expected Bool` before WMP's loadout handler runs. CBA stores its compiled extended
Respawn callbacks on each local unit. WMP finds only the callback which calls ACE's name helper and
replaces it with the same unchanged ACE function receiving only the new unit. All other ACE/CBA
callbacks remain untouched, and WMP does not replace ACE code or assign a different player name.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
