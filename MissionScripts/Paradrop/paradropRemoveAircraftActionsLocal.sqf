/*
 * Author: WaldoTheWarfighter
 * Removes WMP static-line, HALO and jump-settings interactions from one paradrop aircraft.
 *
 * Locality and repeat/JIP behaviour:
 * Runs on every interface client because hold actions and ACE interaction paths are local. Repeated
 * calls are safe. The server publishes this with the aircraft as its object-keyed JIP ID, replacing
 * the earlier setup call so a later joiner cannot reinstall an operation Zeus already removed.
 * It changes no aircraft movement, crew, inventory or map marker.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 *
 * Return Value:
 * <BOOL> - true after local actions were cleared; false without an interface or valid aircraft.
 *
 * Current caller:
 * Waldo_fnc_ParadropRemoveDropZone when an operation ends or retains its aircraft.
 *
 * Example:
 * [this] call Waldo_fnc_ParadropRemoveAircraftActionsLocal;
 */
params [["_aircraft", objNull, [objNull]]];
if (!hasInterface || {isNull _aircraft}) exitWith {false};

[_aircraft, 0, 0, 1, "NonSteerable_Parachute_F", false, false] call Waldo_fnc_AddStaticJump;
[_aircraft, 0, "B_Parachute", false, false] call Waldo_fnc_AddHaloJump;

if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
    private _actionPath = _aircraft getVariable ["Waldo_Paradrop_SettingsActionPath", []];
    if (_actionPath isEqualType [] && {count _actionPath > 0}) then {
        [_aircraft, 1, _actionPath] call ace_interact_menu_fnc_removeActionFromObject;
    };
    private _categoryPath = _aircraft getVariable ["Waldo_Paradrop_SettingsCategoryPath", []];
    if (_categoryPath isEqualType [] && {count _categoryPath > 0}) then {
        [_aircraft, 1, _categoryPath] call ace_interact_menu_fnc_removeActionFromObject;
    };
};

_aircraft setVariable ["Waldo_Paradrop_SettingsActionAdded", false];
_aircraft setVariable ["Waldo_Paradrop_SettingsActionPath", []];
_aircraft setVariable ["Waldo_Paradrop_SettingsCategoryPath", []];
_aircraft setVariable ["Waldo_Paradrop_LocalSetupComplete", false];
true
