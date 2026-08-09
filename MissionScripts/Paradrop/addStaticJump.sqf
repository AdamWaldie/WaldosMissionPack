/*
 * Author: WaldoTheWarfighter
 * Installs or reconciles a local static-line jump hold action on an aircraft. The action is
 * usable only to cargo occupants inside the configured altitude/speed envelope and can optionally
 * require a recognised open ramp or door. The action is offered only while every live safety
 * condition is satisfied; once started, its short hold is not invalidated by a transient engine
 * read-back change. Repeated calls replace stale settings.
 *
 * Locality and authority: Run locally on each interface client. It creates only that client's
 * hold action; the networked aircraft settings are supplied by the server-owned paradrop setup.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 * 1: minimum altitude AGL metres <NUMBER> (default 180)
 * 2: maximum altitude AGL metres <NUMBER> (default 350)
 * 3: maximum speed km/h <NUMBER> (default 310)
 * 4: parachute vehicle class <STRING> (default "NonSteerable_Parachute_F")
 * 5: require a recognised open ramp/door <BOOL> (default true)
 * 6: enable action <BOOL> (default true; false removes a prior local action)
 *
 * Return Value:
 * Number - local hold-action ID, or -1 when disabled/invalid.
 * Result: The caller can store the returned ID when it needs to inspect the locally installed action.
 *
 * Current callers:
 * Waldo_fnc_VehicleJumpSetup, Waldo_fnc_AddVehicleFunctions and
 * Waldo_fnc_ParadropConfigureAircraftLocal.
 *
 * Example:
 * [plane, 180, 350, 300, "NonSteerable_Parachute_F", false] call Waldo_fnc_AddStaticJump;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_minAltitude", 180, [0]],
    ["_maxAltitude", 350, [0]],
    ["_maxSpeed", 310, [0]],
    ["_chuteVehicleClass", "NonSteerable_Parachute_F", [""]],
    ["_requireOpenDoor", true, [false]],
    ["_enabled", true, [false]]
];

if (!hasInterface || {isNull _vehicle} || {_vehicle isKindOf "CAManBase"}) exitWith {-1};
private _oldId = _vehicle getVariable ["Waldo_Static_Jump_ActionId", -1];
private _oldSignature = _vehicle getVariable ["Waldo_Static_Jump_LocalSignature", []];
private _signature = [_minAltitude, _maxAltitude, _maxSpeed, _chuteVehicleClass, _requireOpenDoor, _enabled];
if (_oldSignature isEqualTo _signature && {_oldId >= 0}) exitWith {_oldId};
if (_oldId >= 0) then {[_vehicle, _oldId] call BIS_fnc_holdActionRemove};
_vehicle setVariable ["Waldo_Static_Jump_ActionId", -1];
_vehicle setVariable ["Waldo_Static_Jump_LocalSignature", _signature];
_vehicle setVariable ["Waldo_Static_Jump", []];
if (!_enabled) exitWith {-1};
if !(isClass (configFile >> "CfgVehicles" >> _chuteVehicleClass)) exitWith {-1};

_minAltitude = _minAltitude max 0;
_maxAltitude = _maxAltitude max _minAltitude;
_maxSpeed = _maxSpeed max 1;
_vehicle setVariable ["Waldo_Static_Jump_MinAltitude", _minAltitude];
_vehicle setVariable ["Waldo_Static_Jump_MaxAltitude", _maxAltitude];
_vehicle setVariable ["Waldo_Static_Jump_MaxSpeed", _maxSpeed];
_vehicle setVariable ["Waldo_Static_Jump_RequireDoor", _requireOpenDoor];

private _condition = "(_target getCargoIndex _this) != -1"
    + " && {((getPosATL _target) select 2) >= (_target getVariable ['Waldo_Static_Jump_MinAltitude',180])}"
    + " && {((getPosATL _target) select 2) <= (_target getVariable ['Waldo_Static_Jump_MaxAltitude',350])}"
    + " && {abs speed _target <= (_target getVariable ['Waldo_Static_Jump_MaxSpeed',310])}"
    + " && {!(_target getVariable ['Waldo_Static_Jump_RequireDoor',true]) || {"
    + "(_target animationPhase 'ramp_bottom' > 0.64) || {(_target animationPhase 'door_2_1' == 1)} || {(_target animationPhase 'door_2_2' == 1)} || {(_target animationPhase 'jumpdoor_1' == 1)} || {(_target animationPhase 'jumpdoor_2' == 1)} || {(_target animationPhase 'back_ramp_switch' == 1)} || {(_target animationPhase 'back_ramp_half_switch' == 1)} || {(_target doorPhase 'RearDoors' > 0.5)} || {(_target doorPhase 'Door_1_source' > 0.5)} || {(_target animationSourcePhase 'ramp_anim' > 0.5)}}}";

private _actionId = [
    _vehicle,
    "<t color='#407ada'>Static-Line Jump</t>",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa",
    _condition,
    "true",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        [_caller, _target, _arguments select 0] spawn Waldo_fnc_StaticJumpFunc;
    },
    {},
    [_chuteVehicleClass],
    0,
    25,
    false
] call BIS_fnc_holdActionAdd;

_vehicle setVariable ["Waldo_Static_Jump_ActionId", _actionId];
_vehicle setVariable ["Waldo_Static_Jump", [_vehicle, _minAltitude, _maxAltitude, _maxSpeed, _chuteVehicleClass, _requireOpenDoor]];
_actionId
