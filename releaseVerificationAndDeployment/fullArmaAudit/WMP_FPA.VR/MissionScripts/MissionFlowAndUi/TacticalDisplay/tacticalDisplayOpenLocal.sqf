/*
 * Author: Waldo
 * Opens a proximity-bound live tactical map for one registered console.
 *
 * Arguments: 0: object <OBJECT>
 * Return Value: Display
 */

params [["_object", objNull, [objNull]]];
if !(hasInterface && {!isNull _object} && {_object getVariable ["Waldo_TacticalDisplay_Registered", false]}) exitWith {displayNull};
private _display = (findDisplay 46) createDisplay "RscDisplayEmpty";
private _background = _display ctrlCreate ["RscText", -1];
_background ctrlSetPosition [safeZoneX + 0.08 * safeZoneW, safeZoneY + 0.08 * safeZoneH, 0.84 * safeZoneW, 0.84 * safeZoneH];
_background ctrlSetBackgroundColor [0.015, 0.025, 0.02, 0.96];
_background ctrlCommit 0;
private _map = _display ctrlCreate ["RscMapControl", -1];
_map ctrlSetPosition [safeZoneX + 0.10 * safeZoneW, safeZoneY + 0.13 * safeZoneH, 0.80 * safeZoneW, 0.73 * safeZoneH];
_map ctrlCommit 0;
private _title = _display ctrlCreate ["RscText", -1];
_title ctrlSetPosition [safeZoneX + 0.10 * safeZoneW, safeZoneY + 0.085 * safeZoneH, 0.62 * safeZoneW, 0.04 * safeZoneH];
_title ctrlSetText "LIVE TACTICAL DISPLAY";
_title ctrlSetTextColor [0.65, 0.95, 0.75, 1];
_title ctrlCommit 0;
private _close = _display ctrlCreate ["RscButtonMenu", -1];
_close ctrlSetPosition [safeZoneX + 0.76 * safeZoneW, safeZoneY + 0.085 * safeZoneH, 0.14 * safeZoneW, 0.04 * safeZoneH];
_close ctrlSetText "CLOSE";
_close ctrlAddEventHandler ["ButtonClick", {params ["_control"]; (ctrlParent _control) closeDisplay 2}];
_close ctrlCommit 0;

_map setVariable ["Waldo_TacticalDisplay_Object", _object];
_map ctrlAddEventHandler ["Draw", {
    params ["_map"];
    private _console = _map getVariable ["Waldo_TacticalDisplay_Object", objNull];
    if (isNull _console) exitWith {};
    private _displaySide = _console getVariable ["Waldo_TacticalDisplay_Side", sideUnknown];
    if (_displaySide == sideUnknown) then {_displaySide = side (group player)};
    private _radius = _console getVariable ["Waldo_TacticalDisplay_Radius", 2000];
    private _centre = getPosWorld _console;
    {
        private _unit = _x;
        if (alive _unit && {_unit distance2D _centre <= _radius}) then {
            private _relationship = _displaySide getFriend (side group _unit);
            if (_relationship >= 0.6) then {
                _map drawIcon ["\a3\ui_f\data\map\vehicleicons\iconMan_ca.paa", [0.25, 0.85, 1, 1], getPosWorld _unit, 20, 20, getDir _unit, name _unit, 1, 0.035, "RobotoCondensed", "right"];
            } else {
                if (_console getVariable ["Waldo_TacticalDisplay_ShowKnownEnemies", true] && {((group player) knowsAbout _unit) >= (missionNamespace getVariable ["Waldo_TacticalDisplay_MinimumKnowledge", 1.5])}) then {
                    _map drawIcon ["\a3\ui_f\data\map\vehicleicons\iconMan_ca.paa", [1, 0.25, 0.2, 0.9], getPosWorld _unit, 18, 18, getDir _unit, "KNOWN CONTACT", 1, 0.032, "RobotoCondensed", "right"];
                };
            };
        };
    } forEach allUnits;
}];

_map ctrlMapAnimAdd [0, (((_object getVariable ["Waldo_TacticalDisplay_Radius", 2000]) / 10000) max 0.02) min 0.8, getPosWorld _object];
ctrlMapAnimCommit _map;
[_display, _object] spawn {
    params ["_display", "_console"];
    waitUntil {
        uiSleep 0.2;
        isNull _display || {isNull _console} || {!alive _console} || {player distance _console > (missionNamespace getVariable ["Waldo_TacticalDisplay_MaximumOpenDistance", 8])}
    };
    if (!isNull _display) then {_display closeDisplay 2};
};
_display
