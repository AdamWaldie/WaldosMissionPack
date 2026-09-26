# Bomb Defusal

> **Use this page when:** a field-equipment procedure should disarm an explosive, publish a result, or detonate it on failure.

Bomb Defusal is a consequence wrapper around WMP's shared interaction-procedure system. It does not use a separate reduced interface. Mission makers may pair the explosive consequence with any built-in procedure, while `wirecut` remains the backward-compatible default.

| Procedure card | Active EOD controller |
|---|---|
| ![Bomb-defusal operating card](images/interaction-procedures/interaction-wirecut-briefing.png) | ![Active EOD controller](images/interaction-procedures/interaction-wirecut-active.png) |

## Quick start

Place the explosive object in Eden and call this from its **Initialization** field:

```sqf
[this] call Waldo_fnc_BombDefuseSetup;
```

The object receives linked ACE and vanilla interactions. The server exclusively owns each attempt and applies the result. By default, success disarms the object and failure, timeout, confirmed abort, or abandonment detonates it.

`Waldo_fnc_BombDefuseSetup` takes the object as argument 0 (`Object`, required) and named options as argument 1 (`Array` of `[key, value]` pairs or `HashMap`, default `[]`). The Eden init field runs on every machine so each client can install its local action. The server publishes the shared state. Repeat setup is handled by the underlying interaction system.

The setup call returns `true` for a recognised procedure and `false` for an unknown procedure. A null object exits without a Boolean result, so check that the Eden `this` reference points to the device. The return value reports setup on the calling machine; it is not the player's eventual defusal result.

## Choose the procedure

Set `challengeId` when bomb security is better represented by something other than wire isolation.

| `challengeId` | Suitable fiction |
|---|---|
| `wirecut` | Identify, probe, and sever an isolation loom |
| `minesweeper` | Diagnose an explosive trigger matrix |
| `keypad` | Recover and enter an authorization code |
| `lockpick` | Defeat a mechanical arming lock |
| `circuit` | Reroute a detonation bus or breaker cabinet |
| `repair` | Service a damaged safety or release mechanism |
| `radiotune` | Acquire and hold a remote disarm carrier |
| `pressure` | Stabilize a pressure-triggered device |
| `sequence` | Repeat a guarded authorization sequence |
| `commandinput` | Enter directional command packets |

Example: use a breaker cabinet to isolate a generator-fed charge.

```sqf
[this, createHashMapFromArray [
    ["challengeId", "circuit"],
    ["difficulty", "hard"],
    ["actionTitle", "Bypass Detonation Bus"],
    ["successVariable", "chargeDisarmed"],
    ["preset", "generatorBreaker"]
]] call Waldo_fnc_BombDefuseSetup;
```

## Common options

The wrapper passes the options below to the shared interaction system. Use the exact key spelling shown here.

| Option | Type | Default | Purpose |
|---|---|---|---|
| `challengeId` | String | `wirecut` | Built-in procedure used to disarm the device |
| `procedure` | String | `wirecut` | Legacy alias used if `challengeId` is absent |
| `difficulty` | String | `standard` | `easy`, `standard`, `hard`, or `expert` |
| `config` | Array | Procedure default | Complete procedure-specific configuration override |
| `actionTitle` | String | `Defuse Bomb` | ACE and vanilla interaction wording |
| `title` | String | `Defuse Bomb` | Legacy action title; `actionTitle` takes priority when both are present |
| `equipmentTitle` | String | Procedure faceplate | Optional equipment faceplate title |
| `successVariable` | String | `Waldo_MG_BombDefused` | Preferred shared object variable set on success |
| `defusedVariable` | String | Compatibility fallback | Legacy name used only when `successVariable` is absent |
| `detonateOnFailure` | Boolean | `true` | Whether a terminal failure detonates the object |
| `explosive` | String | `IEDLandBig_Remote_Ammo` | Ammo class created for the server-side detonation |
| `oneShot` | Boolean | `true` | Consume the interaction after its first terminal result |
| `retryOnFailure` | Boolean | Opposite of `oneShot` | Allow another attempt after failure when not consumed |
| `repeatable` | Boolean | `false` | Allow another attempt after success |
| `distance` | Number | `4` | Maximum interaction distance in metres |
| `lockTimeout` | Number | `600` | Seconds before an abandoned exclusive attempt is released |
| `condition` | Code | `{true}` | Additional server-rechecked availability condition |
| `onSuccess` | Code | `{}` | Server callback after authoritative state is published |
| `onFailure` | Code | `{}` | Server callback before the optional detonation is applied |
| `icon` | String (texture path) | `\a3\ui_f\data\igui\cfg\actions\take_ca.paa` | ACE action icon |

Presentation options such as `preset`, `manufacturer`, `model`, `objective`, `controls`, `skin`, and accessibility-safe texture settings pass through to the selected procedure.

## Wire-cut compatibility options

Existing EOD calls remain valid:

```sqf
[this, [
    ["wireCount", 6],
    ["timeLimit", 20],
    ["verificationLevel", 4]
]] call Waldo_fnc_BombDefuseSetup;
```

| Wire-cut option | Type | Default | Meaning |
|---|---|---|---|
| `wireCount` | Number | `5` | Number of wires for the legacy configuration |
| `timeLimit` | Number (seconds) | `20` | Time limit for the legacy configuration; `0` means no limit |
| `verificationLevel` | Number | `-1` | Let the procedure derive its check level; an explicit level is used as supplied |

These three keys apply to `wirecut`. Supplying any of them makes the wrapper use the legacy wire-cut configuration. For another procedure, use `difficulty` or its documented `config` array.

## Using the result

Every attempt uses the shared server-authoritative lifecycle:

```text
IDLE -> RUNNING -> SUCCESS
                -> FAILURE
```

The detailed outcome code distinguishes ordinary failure, timeout, abort, and abandonment. State is published before callbacks execute.

```sqf
private _state = [_bomb] call Waldo_fnc_MiniGameInteractionGetState;
private _result = [_bomb] call Waldo_fnc_MiniGameInteractionGetResult;

if ([_bomb, "SUCCESS"] call Waldo_fnc_MiniGameInteractionStateIs) then {
    // Unlock a door, complete a task, or enable another action.
};
```

`Waldo_MG_BombDefused` remains available for old missions. A custom `successVariable` is also published when supplied.

## ACE and vanilla behavior

Both interaction surfaces enter the same server acquisition handshake. Neither can bypass distance, custom condition, exclusive ownership, consumed state, or actor validation. The action is hidden while another player owns the attempt.

Use the result directly in an ACE condition:

```sqf
{
    params ["_target"];
    [_target, "SUCCESS"] call Waldo_fnc_MiniGameInteractionStateIs
}
```

## Resetting a training device

The reset helper is server-only. Call it from `initServer.sqf` or another server-owned script:

```sqf
[_bomb, true, false] call Waldo_fnc_MiniGameInteractionReset;
```

| # | Argument | Type | Default | Meaning |
|---|---|---|---|---|
| 0 | `object` | Object | `objNull` (invalid) | Existing device to reset |
| 1 | `reenableAction` | Boolean | `true` | Make its interaction available again |
| 2 | `forceRunningReset` | Boolean | `false` | Interrupt a running attempt |

`Waldo_fnc_MiniGameInteractionReset` returns `true` after a reset. It returns `false` off-server, for a null object, or when an attempt is running and `forceRunningReset` is `false`. A forced reset invalidates the current token before returning the object to `IDLE`.

For a detonating live device, the original object is deleted on failure. Create or rearm a replacement object instead of trying to reset the deleted reference.

## If defusal cannot begin

Check the object's procedure registration, ACE interaction availability and whether another player already owns the active attempt. A successful visual interaction is not enough by itself: the result callback must still point to the intended explosive consequence. Use the reset path only for a training device that should be repeatable.

## See also

- [Interaction Procedures](Waldos-Mini-Games-Interaction-Challenges)
- [EOD Controller](Interaction-Procedure-EOD-Controller)
- [Mission Diagnostics](Mission-Diagnostics)
- [Zeus and Script API Parity](Zeus-And-Script-API-Parity)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
