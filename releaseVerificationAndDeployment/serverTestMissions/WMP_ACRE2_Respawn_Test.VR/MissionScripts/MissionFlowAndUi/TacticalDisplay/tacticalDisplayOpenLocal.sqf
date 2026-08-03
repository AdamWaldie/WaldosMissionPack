/*
 * Author: WaldoTheWarfighter
 * Opens the client-only live map belonging to one registered Tactical Display object.
 *
 * The map centres on the world object, draws living friendly units within its configured radius and
 * draws hostile units only when enabled and already known to the player's group above the configured
 * `knowsAbout` threshold. It provides no omniscient enemy feed and does not render onto the board's
 * texture. The display closes when the board is destroyed, the player leaves the configured maximum
 * distance, the parent UI disappears or the user selects Close.
 *
 * Arguments:
 * 0: display object <OBJECT> - registered access point being used.
 *
 * Return Value:
 * Display - created local tactical-map display, or displayNull when opening is unavailable.
 *
 * Example:
 * [mapBoard] call Waldo_fnc_TacticalDisplayOpenLocal;
 *
 * Current caller: the local action installed by TacticalDisplaySetupLocal.
 */

params [["_object", objNull, [objNull]]];
if !(hasInterface && {!isNull _object} && {_object getVariable ["Waldo_TacticalDisplay_Registered", false]}) exitWith {displayNull};
private _parent = findDisplay 46;
if (isNull _parent) exitWith {
    ["TACTICAL DISPLAY", "The gameplay display is not ready.", "WARNING", "TACTICAL_DISPLAY"] call Waldo_fnc_FeatureNotifyLocal;
    displayNull
};
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith {
    ["TACTICAL DISPLAY", "The tactical map could not be opened.", "ERROR", "TACTICAL_DISPLAY"] call Waldo_fnc_FeatureNotifyLocal;
    displayNull
};
_display setVariable ["Waldo_UI_ThemedDisplay", true];
private _theme = [] call Waldo_fnc_UiTheme;
private _background = _display ctrlCreate ["RscText", -1];
_background ctrlSetPosition [safeZoneX + 0.08 * safeZoneW, safeZoneY + 0.08 * safeZoneH, 0.84 * safeZoneW, 0.84 * safeZoneH];
_background ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.015, 0.025, 0.02, 0.96]]);
_background ctrlCommit 0;
private _map = _display ctrlCreate ["RscMapControl", -1];
_map ctrlSetPosition [safeZoneX + 0.10 * safeZoneW, safeZoneY + 0.13 * safeZoneH, 0.80 * safeZoneW, 0.73 * safeZoneH];
_map ctrlCommit 0;
private _title = _display ctrlCreate ["RscText", -1];
_title ctrlSetPosition [safeZoneX + 0.10 * safeZoneW, safeZoneY + 0.085 * safeZoneH, 0.62 * safeZoneW, 0.04 * safeZoneH];
_title ctrlSetText "LIVE TACTICAL DISPLAY";
_title ctrlSetTextColor (_theme getOrDefault ["accent", [0.65, 0.95, 0.75, 1]]);
_title ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
_title ctrlCommit 0;
private _close = _display ctrlCreate ["RscButtonMenu", -1];
_close ctrlSetPosition [safeZoneX + 0.76 * safeZoneW, safeZoneY + 0.085 * safeZoneH, 0.14 * safeZoneW, 0.04 * safeZoneH];
_close ctrlSetText "CLOSE";
_close ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
_close ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.025, 0.20, 0.36, 0.99]]);
_close ctrlSetActiveColor (_theme getOrDefault ["accentActive", [0.10, 0.48, 0.76, 1]]);
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
    private _liveTheme = uiNamespace getVariable ["Waldo_UI_ResolvedTheme", createHashMap];
    if (count (keys _liveTheme) == 0) then {_liveTheme = [] call Waldo_fnc_UiTheme;};
    private _friendlyColour = _liveTheme getOrDefault ["success", [0.25, 0.85, 1, 1]];
    private _enemyColour = +(_liveTheme getOrDefault ["danger", [1, 0.25, 0.2, 0.9]]);
    _enemyColour set [3, 0.9];
    private _mapFont = _liveTheme getOrDefault ["font", "RobotoCondensed"];
    {
        private _unit = _x;
        if (alive _unit && {_unit distance2D _centre <= _radius}) then {
            private _relationship = _displaySide getFriend (side group _unit);
            if (_relationship >= 0.6) then {
                _map drawIcon ["\a3\ui_f\data\map\vehicleicons\iconMan_ca.paa", _friendlyColour, getPosWorld _unit, 20, 20, getDir _unit, name _unit, 1, 0.035, _mapFont, "right"];
            } else {
                if (_console getVariable ["Waldo_TacticalDisplay_ShowKnownEnemies", true] && {((group player) knowsAbout _unit) >= (missionNamespace getVariable ["Waldo_TacticalDisplay_MinimumKnowledge", 1.5])}) then {
                    _map drawIcon ["\a3\ui_f\data\map\vehicleicons\iconMan_ca.paa", _enemyColour, getPosWorld _unit, 18, 18, getDir _unit, "KNOWN CONTACT", 1, 0.032, _mapFont, "right"];
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
