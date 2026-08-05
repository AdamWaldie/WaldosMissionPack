# ACE Corpse Traps

Players conceal one carried throwable on a dead body; the next player to
open that body's inventory releases the stored projectile at the corpse.
Disabled by default.

## Config (`MissionConfig\missionSystemsConfig.sqf`)

```sqf
["Waldo_CorpseTraps_Enable", false]   // shared: enables corpse-trap handling where configured
```

Enabling this in the config is enough — WMP's existing `init.sqf` lifecycle
already calls `Waldo_fnc_CorpseTrapInit` when the flag is true; do not
duplicate that call yourself.

## Using a trap (player flow)

1. Carry at least one throwable.
2. ACE-interact with any dead AI or player body.
3. Open **Rig Corpse**, select the throwable to conceal.
4. Stay within 3 metres while the 3-second planting action completes.

One magazine is removed on completion. There's no visible marker,
inspection or disarm action — even the planter can trigger their own trap
by later opening the corpse's inventory.

## Supported throwables

Whatever's compatible with Arma's `Throw` weapon and specifies a valid
`CfgAmmo` projectile — vanilla and modded frag grenades, smoke, flashbangs,
incendiaries, chemlights, other utility throwables. The stored projectile
keeps its own configured behaviour (an M67 fuses normally; smoke/utility
throwables may be harmless or stay active much longer).

## Multiplayer behaviour

- Server validates the actor, body, distance, magazine and projectile
  config.
- A corpse holds only one trap — near-simultaneous planting attempts: the
  server accepts the first and refunds the other player's throwable.
- Trap state flips to fired before the projectile is created, preventing
  duplicate spawns from simultaneous inventory opens.
- JIP and respawning players get the inventory listener automatically.

## Gotchas

- Fast-grab actions that transfer an item without opening the corpse
  inventory do **not** trigger the trap.
- Deleted/cleaned-up corpses delete their traps with them.
- No faction/AI-vs-player restriction — any corpse, any player, by design.
