# Loadout Saving and Respawn

> **Use this page when:** you need starting, manual or persistent player equipment across respawn, including ACRE2 radios.

Basic respawn loadout saving is automatic. `Waldo_fnc_SaveLoadout` stores the player's current equipment and the local respawn handler restores it. `respawnOnStart = -1` remains required.

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

Ordinary respawn snapshots stay on that player's client and are tagged with Steam UID, playable-slot
variable name and side. A hosted player changing to a different slot cannot inherit the previous
slot's snapshot. INIDBI player records are server-owned, UID-separated and mission-scoped by
default; set `Waldo_Persistence_Scope = "CAMPAIGN"` only for intentional cross-mission saves.

Restore order is:

1. filtered base-class unit loadout;
2. bounded wait for fresh unique radio IDs;
3. the last local respawn radio snapshot, or persisted radio state when loading INIDBI2 data;
4. the current mission plan only when no usable snapshot exists.

Persisted state therefore wins over baseline retuning without ever storing `_ID_n` classnames. If state restoration fails or the expected occurrence is missing, WMP logs the problem and falls back to the current mission plan.

ACRE generates fresh unique IDs after a filtered loadout restore. WMP therefore guarantees occurrence identity—first PRC-152, second PRC-152—not the identity of a particular transient `_ID_n` item. Occurrence follows ACRE's canonical carried-radio order, which is also what ACRE's repeated-radio setup API uses. WMP deliberately does not sort unique IDs independently. Explicit mission assignments manage only their listed occurrences; additional same-type radios are preserved.

## Manual saving

Starter crates and loadout-save points call:

```sqf
[] call Waldo_fnc_SaveLoadout;
```

Pass `[false]` for automatic startup work that must not display a notification over the loading presentation. Explicit player saves use the WMP notification UI and replace their prior message instead of growing the queue.

ACE Respawn can conflict with this mission-owned restore path and should remain disabled in ACE addon settings.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
