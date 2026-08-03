# Loadout Saving and Respawn

> **Use this page when:** you need starting, manual or persistent player equipment across respawn, including ACRE2 radios.

Basic respawn loadout saving is automatic. `Waldo_fnc_SaveLoadout` stores the player's current equipment and the local respawn handler restores it. `respawnOnStart = -1` remains required.

## ACRE2-safe storage

When ACRE2 is loaded, every saved respawn and persistence loadout passes through `acre_api_fnc_filterUnitLoadout`. Unique classes such as `ACRE_PRC152_ID_7` are converted to base classes before storage. Without ACRE2, the original loadout is returned unchanged.

After restoration WMP waits with a deadline for ACRE to create fresh unique IDs, then applies the player's current side/group mission plan. This is the normal respawn behaviour; it does not preserve arbitrary captured-radio tuning. Newly picked-up radios are not retuned merely because the player changes group.

Persistence can optionally store radio state separately by base class plus deterministic same-type occurrence. It preserves channel or WMP-known manual frequency, ear, volume, audio source and the selected radio. Alternate PTT and speaker mode are never changed. A manually tuned frequency that was not applied by WMP cannot be read through ACRE's public API, so it cannot be reconstructed; configured WMP frequency assignments can.

Restore order is:

1. filtered base-class unit loadout;
2. bounded wait for fresh unique radio IDs;
3. persisted radio state when enabled, otherwise the current mission plan.

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
