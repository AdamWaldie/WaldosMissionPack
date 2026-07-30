/*
 * Author: WaldoTheWarfighter
 * Presents user-friendly ZEN dialogs for creating or removing dynamic paradrop operations.
 *
 * Airframe is selected from a validated friendly-name dropdown independently of operational side.
 * The create dialog exposes flight, jump, marker and cleanup parameters; the remove dialog uses
 * public server summaries and never asks curators for object IDs or config-class text.
 *
 * Arguments:
 * 0: mode <STRING> - CREATE or REMOVE
 * 1: module position <ARRAY>
 *
 * Return Value: Boolean - true when a dialog was opened.
 *
 * Example: ["CREATE", _modulePos] call Waldo_fnc_ParadropDropZoneZen;
 * Current callers: ZEN module registrations in Zen_initModules.sqf.
 */
params [["_mode", "CREATE", [""]], ["_modulePos", [], [[]]]];
if !(hasInterface && {isClass (configFile >> "CfgPatches" >> "zen_main")}) exitWith {false};
_mode = toUpperANSI _mode;
if (_mode == "REMOVE") exitWith {
    private _systems = missionNamespace getVariable ["Waldo_Paradrop_PublicDropZones", []];
    if (count _systems == 0) exitWith {systemChat "[WMP] No dynamic paradrop operations are registered."; false};
    private _ids = _systems apply {_x select 0};
    private _labels = _systems apply {format ["%1 - %2", _x select 1, getText (configFile >> "CfgVehicles" >> (_x select 5) >> "displayName")]};
    [
        "Remove Dynamic Paradrop",
        [
            ["COMBO", ["Drop zone", "Select the named operation to remove."], [_ids, _labels, 0]],
            ["CHECKBOX", ["Delete aircraft", "Also delete the operation aircraft and its AI crew."], true]
        ],
        {params ["_values"]; [_values select 0, _values select 1, player] remoteExecCall ["Waldo_fnc_ParadropRemoveDropZone", 2]}
    ] call zen_dialog_fnc_create;
    true
};

private _classes = +(missionNamespace getVariable ["Waldo_Paradrop_AircraftClasses", []]);
_classes = _classes select {
    isClass (configFile >> "CfgVehicles" >> _x)
    && {_x isKindOf "Air"}
    && {getNumber (configFile >> "CfgVehicles" >> _x >> "scope") >= 2}
    && {getNumber (configFile >> "CfgVehicles" >> _x >> "transportSoldier") > 0}
};
_classes = _classes call BIS_fnc_sortAlphabetically;
if (count _classes == 0) exitWith {systemChat "[WMP] No configured transport airframes are available."; false};
private _labels = _classes apply {
    private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
    format ["%1 (%2 seats)", if (_name == "") then {_x} else {_name}, getNumber (configFile >> "CfgVehicles" >> _x >> "transportSoldier")]
};
private _chutes = +(missionNamespace getVariable ["Waldo_Paradrop_ChuteClasses", ["NonSteerable_Parachute_F"]]);
_chutes = _chutes select {isClass (configFile >> "CfgVehicles" >> _x)};
private _chuteLabels = _chutes apply {private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName"); if (_name == "") then {_x} else {_name}};
private _defaultName = format ["DZ %1", round (serverTime mod 10000)];
[
    "Create Dynamic Paradrop",
    [
        ["EDIT", ["Drop-zone name", "Used on the point marker and removal list."], [_defaultName]],
        ["COMBO", ["Operational side", "Controls crew and generated jumper allegiance; it does not filter the airframe."], [[west, east, independent], ["BLUFOR", "OPFOR", "Independent"], 0]],
        ["COMBO", ["Airframe", "Choose any configured transport aircraft, regardless of its original faction."], [_classes, _labels, 0]],
        ["SLIDER", ["Run direction", "Aircraft heading through standby, green and red lines."], [0, 359, 0, 0]],
        ["SLIDER", ["Drop altitude", "Forced terrain-relative flight height in metres."], [100, 1200, 250, 0]],
        ["SLIDER", ["Maximum speed", "AI speed cap in km/h. Keep low enough for safe static-line deployment."], [80, 400, 220, 0]],
        ["SLIDER", ["Approach distance", "Distance before the standby line where the aircraft spawns."], [800, 8000, 2500, 0]],
        ["SLIDER", ["Drop-zone length", "Distance between green and red lines. The default accommodates 20 two-second exits at the default speed."], [300, 6000, 2500, 0]],
        ["SLIDER", ["Exit distance", "Route length after the red line."], [800, 8000, 2500, 0]],
        ["SLIDER", ["Generated jumpers", "AI cargo generated on the operational side, capped by available seats."], [0, 60, 20, 0]],
        ["SLIDER", ["Jump interval", "Seconds between each jumper; default two seconds."], [0.5, 10, 2, 1]],
        ["COMBO", ["Static-line chute", "Parachute vehicle used for each automatic jump."], [_chutes, _chuteLabels, 0]],
        ["CHECKBOX", ["Automatically drop player cargo", "If enabled, player cargo is sequenced with generated AI at the green line."], false],
        ["CHECKBOX", ["Create map markers", "Creates DZ rectangle, standby/green/red line rectangles and a named point."], true],
        ["CHECKBOX", ["Delete after run", "Deletes the aircraft and operation markers after it clears the red line."], false]
    ],
    {
        params ["_values", "_modulePos"];
        _values params ["_name", "_side", "_class", "_direction", "_altitude", "_speed", "_approach", "_length", "_exit", "_count", "_interval", "_chute", "_dropPlayers", "_markers", "_delete"];
        private _idBase = [_name, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
        if (_idBase == "") then {_idBase = "DZ"};
        private _id = format ["%1_%2_%3", _idBase, clientOwner, round (serverTime * 10)];
        private _config = createHashMapFromArray [
            ["id", _id], ["name", _name], ["centre", _modulePos], ["side", _side], ["aircraftClass", _class],
            ["direction", _direction], ["altitude", _altitude], ["maximumSpeed", _speed], ["approachDistance", _approach],
            ["runLength", _length], ["exitDistance", _exit], ["jumperCount", round _count], ["jumpInterval", _interval],
            ["chuteClass", _chute], ["createJumpers", _count > 0], ["autoDropPlayers", _dropPlayers],
            ["createMarkers", _markers], ["deleteAfterRun", _delete]
        ];
        [_config, player] remoteExecCall ["Waldo_fnc_ParadropCreateDropZone", 2];
    }, {}, _modulePos
] call zen_dialog_fnc_create;
true
