/*
 * Author: WaldoTheWarfighter
 * Installs one repeat-safe ACE self-interaction inside a jump-capable aircraft. The summary reads
 * the aircraft's current static-line/HALO variables at click time, so live reconfiguration and
 * JIP replay cannot leave stale limits in the menu.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 *
 * Return Value:
 * Boolean - true when the settings action is available or already installed.
 *
 * Called by:
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
    if (count _static > 0) then {
        [
            [],
            ["Static-Line Jump", 1.2, [0, 1, 0, 1]],
            [format ["Safe speed: up to %1 km/h", _static select 3]],
            [format ["Altitude: %1 to %2 metres AGL", _static select 1, _static select 2]],
            [if (_static param [5, true]) then {"A recognised ramp or door must be open."} else {"No door-state requirement."}]
        ] call CBA_fnc_notify;
    };
    if (count _halo > 0) then {
        [
            [],
            ["HALO Jump", 1.2, [0, 1, 0, 1]],
            [format ["Minimum altitude: %1 metres AGL", _halo select 1]],
            [if (_halo param [3, true]) then {"A recognised ramp or door must be open."} else {"No door-state requirement."}]
        ] call CBA_fnc_notify;
    };
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
