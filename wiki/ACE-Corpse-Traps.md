# ACE Corpse Traps

> **Use this page when:** you want players to conceal throwable traps on bodies and need setup, multiplayer, or limitation guidance.

Corpse traps let players conceal one of their carried throwables on a dead body. The next player
to open that body's inventory releases the stored projectile at the corpse.

## Enable corpse traps

The feature is off by default. Set `Waldo_CorpseTraps_Enable` to `true` in `MissionConfig/missionSystemsConfig.sqf`:

```sqf
["Waldo_CorpseTraps_Enable", true],
```

Edit the existing row in that file; do not add a second row. WMP starts the client listener from its shipped init files. ACE Interact is required for placing a trap. Joiners and respawning players receive the listener when the setting is on.

| Setting | Type | Default | What it controls |
|---|---|---|---|
| `Waldo_CorpseTraps_Enable` | Boolean | `false` | Installs the corpse-trap actions and inventory listener. |

There is no object-init call or per-corpse registration. Set the flag once in the existing config
row and test with a dead body and a supported throwable. The server validates placement and
activation. Client actions and inventory listeners install for current and joining players.

## Using a Trap

1. Carry at least one throwable.
2. ACE-interact with any dead AI or player body.
3. Open **Rig Corpse** and select the throwable to conceal.
4. Remain within three metres while the three-second planting action completes.

One magazine is removed when planting completes. The action disappears after the server accepts
the trap. There is no visible marker, inspection action or disarm action, and even the planter can
trigger the trap by later opening the corpse's inventory.

## Supported Throwables

The submenu is built from the magazines compatible with Arma's `Throw` weapon. It supports
vanilla and modded fragmentation grenades, smoke, flashbangs, incendiaries, chemlights and other
utility throwables when their magazine specifies a valid `CfgAmmo` projectile.

The stored projectile keeps its own configured behaviour. An M67 uses its normal fuse, while smoke
or utility throwables may be harmless or remain active for much longer. Unsupported inventory
items are not shown.

## Multiplayer Behaviour

- The server accepts only requests belonging to the player who sent them and validates the body,
  distance, magazine and projectile configuration.
- A corpse can hold only one trap. If two players finish planting at nearly the same time, the
  server accepts the first and refunds the other player's throwable.
- A trap changes to its fired state before the projectile is created, preventing simultaneous
  inventory opens from spawning duplicates.
- Planting audio is spatial and audible nearby. The spoon-release sound is played only for the
  player whose inventory action activates the trap.
- JIP and respawning players receive the inventory listener when the feature is enabled.

## Limitations

- Fast-grab actions that transfer an item without opening the corpse inventory do not activate the
  trap.
- Deleted or cleaned-up corpses also delete their traps.
- The system intentionally does not restrict corpses by faction or distinguish AI from players.

## If the action is missing

Check that ACE Interact is loaded, the corpse is dead, you carry a supported throwable, and `Waldo_CorpseTraps_Enable` is on. Planting requires you to stay within three metres until the action completes.

## See also

- [Feature Configuration Files](Feature-Configuration-Files)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
