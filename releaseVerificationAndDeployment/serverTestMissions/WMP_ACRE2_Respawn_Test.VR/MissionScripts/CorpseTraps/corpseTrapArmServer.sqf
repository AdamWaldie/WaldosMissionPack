/*
 * Server-authoritative arming endpoint. Rejected requests refund the magazine
 * that the client consumed after its progress action.
 */
params [
    ["_corpse", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_magazine", "", [""]],
    ["_ammo", "", [""]]
];

if (!isServer) exitWith {false};

private _requestOwner = remoteExecutedOwner;

private _reject = {
    params ["_reason"];
    [_actor, _magazine, _reason] remoteExecCall ["Waldo_fnc_CorpseTrapRefund", _requestOwner];
    false
};

if (isNull _actor || {_requestOwner != owner _actor}) exitWith {false};
if (isNull _corpse) exitWith {["the corpse no longer exists"] call _reject};
if (!alive _actor || {alive _corpse}) exitWith {["the actor or target is no longer eligible"] call _reject};
if (_actor distance _corpse > 4) exitWith {["the actor moved too far away"] call _reject};
if (_corpse getVariable ["Waldo_CorpseTrap_State", ""] != "") exitWith {["the corpse was already rigged"] call _reject};

private _magazineConfig = configFile >> "CfgMagazines" >> _magazine;
if !(isClass _magazineConfig) exitWith {["the selected magazine is invalid"] call _reject};
if (getText (_magazineConfig >> "ammo") != _ammo) exitWith {["the projectile does not match the magazine"] call _reject};
if (_ammo == "" || {!(isClass (configFile >> "CfgAmmo" >> _ammo))}) exitWith {["the projectile is invalid"] call _reject};

private _throwConfig = configFile >> "CfgWeapons" >> "Throw";
private _compatible = compatibleMagazines "Throw";
{
    _compatible append (compatibleMagazines ["Throw", _x]);
    _compatible append getArray (_throwConfig >> _x >> "magazines");
} forEach getArray (_throwConfig >> "muzzles");
_compatible = _compatible apply {toLowerANSI _x};
if !(toLowerANSI _magazine in _compatible) exitWith {["the selected magazine is not throwable"] call _reject};

_corpse setVariable ["Waldo_CorpseTrap_Ammo", _ammo];
_corpse setVariable ["Waldo_CorpseTrap_Magazine", _magazine];
_corpse setVariable ["Waldo_CorpseTrap_State", "ARMED", true];

["Corpse trap armed."] remoteExecCall ["systemChat", _requestOwner];
true
