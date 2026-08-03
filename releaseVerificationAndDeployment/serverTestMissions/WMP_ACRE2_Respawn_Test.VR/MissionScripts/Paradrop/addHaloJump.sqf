/*
 * Author: WaldoTheWarfighter
 * Installs or reconciles a local HALO jump hold action on an aircraft. It equips the configured
 * steerable parachute backpack through Waldo_fnc_HaloJumpFunc and may optionally require a known
 * open ramp/door. Repeated calls replace stale settings instead of duplicating actions.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 * 1: minimum altitude AGL metres <NUMBER> (default 1000)
 * 2: parachute backpack class <STRING> (default "B_Parachute")
 * 3: require a recognised open ramp/door <BOOL> (default true)
 * 4: enable action <BOOL> (default true; false removes a prior local action)
 *
 * Return Value:
 * Number - local hold-action ID, or -1 when disabled/invalid.
 *
 * Called by:
 * Waldo_fnc_VehicleJumpSetup, Waldo_fnc_AddVehicleFunctions and
 * Waldo_fnc_ParadropConfigureAircraftLocal.
 *
 * Example:
 * [plane, 1000, "B_Parachute", false] call Waldo_fnc_AddHaloJump;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_minAltitude", 1000, [0]],
    ["_chuteBackpackClass", "B_Parachute", [""]],
    ["_requireOpenDoor", true, [false]],
    ["_enabled", true, [false]]
];

if (!hasInterface || {isNull _vehicle} || {_vehicle isKindOf "CAManBase"}) exitWith {-1};
private _oldId = _vehicle getVariable ["Waldo_Halo_Jump_ActionId", -1];
private _oldSignature = _vehicle getVariable ["Waldo_Halo_Jump_LocalSignature", []];
private _signature = [_minAltitude, _chuteBackpackClass, _requireOpenDoor, _enabled];
if (_oldSignature isEqualTo _signature && {_oldId >= 0}) exitWith {_oldId};
if (_oldId >= 0) then {[_vehicle, _oldId] call BIS_fnc_holdActionRemove};
_vehicle setVariable ["Waldo_Halo_Jump_ActionId", -1];
_vehicle setVariable ["Waldo_Halo_Jump_LocalSignature", _signature];
_vehicle setVariable ["Waldo_Halo_Jump", []];
if (!_enabled) exitWith {-1};
if !(isClass (configFile >> "CfgVehicles" >> _chuteBackpackClass)) exitWith {-1};

_minAltitude = _minAltitude max 0;
_vehicle setVariable ["Waldo_Halo_Jump_MinAltitude", _minAltitude];
_vehicle setVariable ["Waldo_Halo_Jump_RequireDoor", _requireOpenDoor];
private _condition = "(_target getCargoIndex _this) != -1"
    + " && {((getPosATL _target) select 2) >= (_target getVariable ['Waldo_Halo_Jump_MinAltitude',1000])}"
    + " && {!(_target getVariable ['Waldo_Halo_Jump_RequireDoor',true]) || {"
    + "(_target animationPhase 'ramp_bottom' > 0.64) || {(_target animationPhase 'door_2_1' == 1)} || {(_target animationPhase 'door_2_2' == 1)} || {(_target animationPhase 'jumpdoor_1' == 1)} || {(_target animationPhase 'jumpdoor_2' == 1)} || {(_target animationPhase 'back_ramp_switch' == 1)} || {(_target animationPhase 'back_ramp_half_switch' == 1)} || {(_target doorPhase 'RearDoors' > 0.5)} || {(_target doorPhase 'Door_1_source' > 0.5)} || {(_target animationSourcePhase 'ramp_anim' > 0.5)}}}";

private _actionId = [
    _vehicle,
    "<t color='#407ada'>HALO Jump</t>",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    _condition,
    "true",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        [_caller, _target, _arguments select 0] spawn Waldo_fnc_HaloJumpFunc;
    },
    {},
    [_chuteBackpackClass],
    0,
    25,
    false
] call BIS_fnc_holdActionAdd;

_vehicle setVariable ["Waldo_Halo_Jump_ActionId", _actionId];
_vehicle setVariable ["Waldo_Halo_Jump", [_vehicle, _minAltitude, _chuteBackpackClass, _requireOpenDoor]];
_actionId
