/*
 * Author: WaldoTheWarfighter
 * Consumes an armed corpse trap and creates its configured projectile when inventory is opened.
 * Locality and authority: Server-only; verifies the opener's network owner, distance, target
 * state and ammo class before changing state or creating the projectile.
 * Repeat/JIP: Sets FIRED before projectile creation so competing requests cannot trigger twice.
 * Joining clients see the public FIRED state; trigger requests are never JIP replayed.
 * Arguments:
 * 0: trapped corpse <OBJECT> (default objNull)
 * 1: player opening inventory <OBJECT> (default objNull)
 * Return Value: <BOOL> - true when a projectile was created; false on a rejected request.
 * Current caller: Waldo_fnc_CorpseTrapInstallInventoryHandler on inventory opening.
 * Example: [_corpse, player] remoteExecCall ["Waldo_fnc_CorpseTrapTriggerServer", 2];
 * Result: The trap fires once and cannot be triggered again.
 */
params [
    ["_corpse", objNull, [objNull]],
    ["_opener", objNull, [objNull]]
];

if (!isServer) exitWith {false};
if (isNull _corpse || {isNull _opener}) exitWith {false};
private _requestOwner = remoteExecutedOwner;
if (_requestOwner != owner _opener) exitWith {false};
if (!alive _opener || {alive _corpse} || {_opener distance _corpse > 5}) exitWith {false};
if (_corpse getVariable ["Waldo_CorpseTrap_State", ""] != "ARMED") exitWith {false};

private _ammo = _corpse getVariable ["Waldo_CorpseTrap_Ammo", ""];
if (_ammo == "" || {!(isClass (configFile >> "CfgAmmo" >> _ammo))}) exitWith {
    _corpse setVariable ["Waldo_CorpseTrap_State", "FIRED", true];
    false
};

// Change state before creating the projectile so simultaneous open requests lose the race.
_corpse setVariable ["Waldo_CorpseTrap_State", "FIRED", true];

private _position = _corpse modelToWorld [0, 0, 0.15];
private _projectile = createVehicle [_ammo, _position, [], 0, "CAN_COLLIDE"];
_projectile setPosATL _position;
_projectile setVelocity [0, 0, 0];

"Waldo_CorpseTrap_Spoon" remoteExecCall ["playSound", _requestOwner];
true
