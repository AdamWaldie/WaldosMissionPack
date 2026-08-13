/*
 * Author: WaldoTheWarfighter
 * Installs one repeat-safe ACE self-interaction inside a jump-capable aircraft. The summary reads
 * the aircraft's current static-line/HALO variables and live flight state at click time, so live
 * reconfiguration, JIP replay, a closed ramp or AI altitude/speed wander cannot leave the player
 * guessing why a visible jump action is temporarily unavailable. Feedback uses WMP notifications.
 *
 * Locality and authority: Run locally on every interface client after ACE is ready. The action
 * reads public aircraft state but does not change the server-owned paradrop operation.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 *
 * Return Value:
 * Boolean - true when the settings action is available or already installed.
 * Result: No server state changes; the local player gains one repeat-safe information action.
 *
 * Current callers:
 * Waldo_fnc_VehicleJumpSetup, Waldo_fnc_AddVehicleFunctions and
 * Waldo_fnc_ParadropConfigureAircraftLocal.
 *
 * Example:
 * [aircraft] call Waldo_fnc_JumpSettingsCheck;
 */

params [["_vehicle", objNull, [objNull]]];
if (!hasInterface || {isNull _vehicle}) exitWith {false};
if !(isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {false};
if (_vehicle getVariable ["Waldo_Paradrop_SettingsActionAdded", false]) exitWith {true};

private _category = [
    "Waldo_PARA_Category",
    "Para Interactions",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa",
    {true},
    {true}
] call ace_interact_menu_fnc_createAction;
private _categoryPath = [_vehicle, 1, ["ACE_SelfActions"], _category]
    call ace_interact_menu_fnc_addActionToObject;

private _statement = {
    params ["_target"];
    private _static = _target getVariable ["Waldo_Static_Jump", []];
    private _halo = _target getVariable ["Waldo_Halo_Jump", []];
    private _altitude = (getPosATL _target) select 2;
    private _speed = abs speed _target;
    private _doorOpen =
        (_target animationPhase "ramp_bottom" > 0.64)
        || {(_target animationPhase "door_2_1" == 1)}
        || {(_target animationPhase "door_2_2" == 1)}
        || {(_target animationPhase "jumpdoor_1" == 1)}
        || {(_target animationPhase "jumpdoor_2" == 1)}
        || {(_target animationPhase "back_ramp_switch" == 1)}
        || {(_target animationPhase "back_ramp_half_switch" == 1)}
        || {(_target doorPhase "RearDoors" > 0.5)}
        || {(_target doorPhase "Door_1_source" > 0.5)}
        || {(_target animationSourcePhase "ramp_anim" > 0.5)};
    private _messages = [];
    private _anyReady = false;
    if (count _static > 0) then {
        private _doorRequired = _static param [5, true];
        private _ready = _altitude >= (_static select 1)
            && {_altitude <= (_static select 2)}
            && {_speed <= (_static select 3)}
            && {!_doorRequired || {_doorOpen}};
        _anyReady = _anyReady || _ready;
        _messages pushBack format [
            "Static line: %1. Live %2m AGL / %3km/h; requires %4-%5m / <=%6km/h%7.",
            if (_ready) then {"READY"} else {"NOT READY"}, round _altitude, round _speed,
            round (_static select 1), round (_static select 2), round (_static select 3),
            if (_doorRequired) then {format ["; ramp/door %1", if (_doorOpen) then {"OPEN"} else {"CLOSED"}]} else {""}
        ];
    };
    if (count _halo > 0) then {
        private _doorRequired = _halo param [3, true];
        private _ready = _altitude >= (_halo select 1) && {!_doorRequired || {_doorOpen}};
        _anyReady = _anyReady || _ready;
        _messages pushBack format [
            "HALO: %1. Live %2m AGL; requires >=%3m%4.",
            if (_ready) then {"READY"} else {"NOT READY"}, round _altitude, round (_halo select 1),
            if (_doorRequired) then {format ["; ramp/door %1", if (_doorOpen) then {"OPEN"} else {"CLOSED"}]} else {""}
        ];
    };
    ["PARADROP STATUS", _messages joinString " ", if (_anyReady) then {"SUCCESS"} else {"WARNING"}, "PARADROP_STATUS", 7]
        call Waldo_fnc_FeatureNotifyLocal;
};
private _action = [
    "Waldo_Jump_Settings",
    "Check Jump Settings",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa",
    _statement,
    {
        params ["_target"];
        count (_target getVariable ["Waldo_Static_Jump", []]) > 0
        || {count (_target getVariable ["Waldo_Halo_Jump", []]) > 0}
    }
] call ace_interact_menu_fnc_createAction;
private _actionPath = [_vehicle, 1, ["ACE_SelfActions", "Waldo_PARA_Category"], _action]
    call ace_interact_menu_fnc_addActionToObject;
_vehicle setVariable ["Waldo_Paradrop_SettingsActionAdded", true];
_vehicle setVariable ["Waldo_Paradrop_SettingsCategoryPath", _categoryPath];
_vehicle setVariable ["Waldo_Paradrop_SettingsActionPath", _actionPath];
true
