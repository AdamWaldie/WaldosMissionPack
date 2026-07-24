# ACE Corpse Traps

Corpse traps let players conceal one of their carried throwables on a dead body. The next player
to open that body's inventory releases the stored projectile at the corpse.

The feature is disabled by default. Enable it in `init.sqf`:

```sqf
Waldo_CorpseTraps_Enable = true;
if (Waldo_CorpseTraps_Enable) then {
    [] call Waldo_fnc_CorpseTrapInit;
};
```

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
