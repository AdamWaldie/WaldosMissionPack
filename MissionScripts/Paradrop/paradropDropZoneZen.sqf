/*
 * Author: WaldoTheWarfighter
 * Presents user-friendly ZEN dialogs for creating, boarding and removing dynamic paradrop
 * operations. Operational side, airframe, static-line chute and HALO backpack are independent
 * validated selectors. Creation defaults to an empty player transport with one AI pilot and a
 * continuous circuit; generated AI cargo is explicitly optional.
 *
 * Arguments:
 * 0: mode <STRING> - CREATE, EMBARK or REMOVE
 * 1: module position <ARRAY>
 *
 * Return Value:
 * Boolean - true when a dialog was opened.
 *
 * Called by:
 * Paradrop ZEN registrations in Zen_initModules.sqf.
 *
 * Example:
 * ["CREATE", _modulePos] call Waldo_fnc_ParadropDropZoneZen;
 */

params [["_mode", "CREATE", [""]], ["_modulePos", [], [[]]]];
if !(hasInterface && {isClass (configFile >> "CfgPatches" >> "zen_main")}) exitWith {false};
_mode = toUpperANSI _mode;

private _systems = missionNamespace getVariable ["Waldo_Paradrop_PublicDropZones", []];
if (_mode in ["REMOVE", "EMBARK"] && {count _systems == 0}) exitWith {
    ["PARADROP", "No dynamic paradrop operations are registered.", "WARNING", "PARADROP_ZEN", 6]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _systemIds = _systems apply {_x select 0};
private _systemLabels = _systems apply {
    private _airframeName = getText (configFile >> "CfgVehicles" >> (_x select 5) >> "displayName");
    format ["%1 - %2", _x select 1, if (_airframeName == "") then {_x select 5} else {_airframeName}]
};

if (_mode == "REMOVE") exitWith {
    [
        "Remove Dynamic Paradrop",
        [
            ["COMBO", ["Drop zone", "Select the named live operation."], [_systemIds, _systemLabels, 0]],
            ["CHECKBOX", ["Delete aircraft", "Delete the aircraft and its AI pilot when no players remain aboard."], true]
        ],
        {params ["_values"]; [_values select 0, _values select 1, player] remoteExecCall ["Waldo_fnc_ParadropRemoveDropZone", 2]}
    ] call zen_dialog_fnc_create;
    true
};

if (_mode == "EMBARK") exitWith {
    private _selectedUnits = +(curatorSelected select 0);
    { _selectedUnits append (units _x) } forEach (curatorSelected select 1);
    _selectedUnits = (_selectedUnits select {isPlayer _x}) arrayIntersect _selectedUnits;
    private _pointClasses = +(missionNamespace getVariable ["Waldo_Paradrop_BoardingPointClasses", ["Land_InfoStand_V1_F"]]);
    _pointClasses = _pointClasses select {isClass (configFile >> "CfgVehicles" >> _x)};
    if (count _pointClasses == 0) then {_pointClasses = ["Land_InfoStand_V1_F"]};
    private _pointLabels = _pointClasses apply {
        private _displayName = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
        if (_displayName == "") then {_x} else {_displayName}
    };
    [
        "Embark Paradrop Players",
        [
            ["COMBO", ["Paradrop operation", "Aircraft that receives cargo players."], [_systemIds, _systemLabels, 0]],
            ["COMBO", ["Boarding method", "Direct moves selected player/group units; boarding point creates a reusable blue action at this module."], [["SELECTION", "POLE", "BOTH"], ["Selected players/groups", "Spawn boarding point", "Both"], 0]],
            ["COMBO", ["Boarding-point object", "Physical object used by the reusable boarding action."], [_pointClasses, _pointLabels, 0]],
            ["EDIT", ["Boarding action label", "Text shown on the blue addAction."], ["Board Paradrop Aircraft"]]
        ],
        {
            params ["_values", "_arguments"];
            _arguments params ["_modulePosition", "_selectedUnits"];
            _values params ["_id", "_method", "_pointClass", "_label"];
            [_id, _method, _selectedUnits, _modulePosition, _pointClass, _label, player]
                remoteExecCall ["Waldo_fnc_ParadropEmbark", 2];
        },
        {},
        [_modulePos, _selectedUnits]
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
if (count _classes == 0) exitWith {
    ["PARADROP", "No configured transport airframes are available.", "ERROR", "PARADROP_ZEN", 7]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _labels = _classes apply {
    private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
    format ["%1 (%2 cargo seats)", if (_name == "") then {_x} else {_name}, getNumber (configFile >> "CfgVehicles" >> _x >> "transportSoldier")]
};

private _staticChutes = +(missionNamespace getVariable ["Waldo_Paradrop_StaticChuteClasses", missionNamespace getVariable ["Waldo_Paradrop_ChuteClasses", ["NonSteerable_Parachute_F"]]]);
_staticChutes = _staticChutes select {isClass (configFile >> "CfgVehicles" >> _x)};
if (count _staticChutes == 0) then {_staticChutes = ["NonSteerable_Parachute_F"]};
private _staticLabels = _staticChutes apply {
    private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
    if (_name == "") then {_x} else {_name}
};
private _haloChutes = +(missionNamespace getVariable ["Waldo_Paradrop_HaloBackpackClasses", ["B_Parachute"]]);
_haloChutes = _haloChutes select {isClass (configFile >> "CfgVehicles" >> _x)};
if (count _haloChutes == 0) then {_haloChutes = ["B_Parachute"]};
private _haloLabels = _haloChutes apply {
    private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
    if (_name == "") then {_x} else {_name}
};
private _defaultName = format ["DZ %1", round (serverTime mod 10000)];

[
    "Create Dynamic Paradrop",
    [
        ["EDIT", ["Drop-zone name", "Used by map markers, boarding and removal selectors."], [_defaultName]],
        ["COMBO", ["Operational side", "Controls the AI pilot and optional AI jumpers; it does not filter the airframe."], [[west, east, independent], ["BLUFOR", "OPFOR", "Independent"], 0]],
        ["COMBO", ["Airframe", "Choose any configured cargo aircraft independently of operational side."], [_classes, _labels, 0]],
        ["SLIDER", ["Run direction", "Aircraft heading through standby, green and red lines."], [0, 359, 0, 0]],
        ["SLIDER", ["Flight/drop altitude", "Forced terrain-relative flight height in metres."], [100, 2000, 250, 0]],
        ["SLIDER", ["Maximum speed", "Forced route speed in km/h."], [80, 500, 220, 0]],
        ["SLIDER", ["Approach distance", "Straight run-in before the standby line."], [800, 10000, 2500, 0]],
        ["SLIDER", ["Drop-zone length", "Distance between green and red lines."], [300, 6000, 2500, 0]],
        ["SLIDER", ["Exit distance", "Straight route after the red line before lifecycle handling."], [800, 10000, 2500, 0]],
        ["COMBO", ["After the pass", "Loop flies a wide circuit and realigns for another pass; retain makes one pass; despawn cleans the operation."], [["LOOP", "RETAIN", "DESPAWN"], ["Loop and repeat", "Single pass - retain aircraft", "Single pass - despawn"], 0]],
        ["COMBO", ["Circuit direction", "Side used for the wide return circuit."], [["LEFT", "RIGHT"], ["Left-hand circuit", "Right-hand circuit"], 0]],
        ["CHECKBOX", ["Enable static-line jump", "Adds the configured static-line player jump action to cargo."], true],
        ["SLIDER", ["Static minimum altitude", "Minimum AGL height for static-line jumping."], [50, 1500, 180, 0]],
        ["SLIDER", ["Static maximum altitude", "Maximum AGL height for static-line jumping."], [50, 2000, 350, 0]],
        ["SLIDER", ["Static maximum speed", "Maximum km/h for static-line jumping."], [80, 500, 310, 0]],
        ["COMBO", ["Static-line parachute", "Parachute vehicle created immediately after exit."], [_staticChutes, _staticLabels, 0]],
        ["CHECKBOX", ["Enable HALO jump", "Adds a HALO player jump action using a steerable parachute backpack."], false],
        ["SLIDER", ["HALO minimum altitude", "Minimum AGL height for HALO jumping."], [100, 5000, 1000, 0]],
        ["COMBO", ["HALO parachute backpack", "Steerable backpack equipped after HALO exit."], [_haloChutes, _haloLabels, 0]],
        ["CHECKBOX", ["Require open ramp/door", "When disabled, jump actions work on aircraft without supported door animation names."], false],
        ["CHECKBOX", ["Automatically sequence player cargo", "Forces embarked players out at the green line; normally leave off for jumpmaster-controlled player actions."], false],
        ["COMBO", ["Automatic jump type", "Method used only when automatic player/AI sequencing is enabled."], [["STATIC", "HALO"], ["Static line", "HALO"], 0]],
        ["SLIDER", ["Optional generated AI jumpers", "AI cargo created for this operation. Default zero keeps the aircraft for players."], [0, 60, 0, 0]],
        ["SLIDER", ["Automatic jump interval", "Seconds between forced player or optional AI exits."], [0.5, 10, 2, 1]],
        ["CHECKBOX", ["Create map markers", "Creates DZ, standby, green, red and named point markers."], true]
    ],
    {
        params ["_values", "_modulePosition"];
        _values params [
            "_name", "_side", "_class", "_direction", "_altitude", "_speed", "_approach", "_length", "_exit",
            "_lifecycle", "_circuitDirection", "_staticEnabled", "_staticMin", "_staticMax", "_staticSpeed", "_staticChute",
            "_haloEnabled", "_haloMin", "_haloChute", "_requireDoor", "_dropPlayers", "_automaticMode", "_count", "_interval", "_markers"
        ];
        private _idBase = [_name, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
        if (_idBase == "") then {_idBase = "DZ"};
        private _id = format ["%1_%2_%3", _idBase, clientOwner, round (serverTime * 10)];
        private _config = createHashMapFromArray [
            ["id", _id], ["name", _name], ["centre", _modulePosition], ["side", _side], ["aircraftClass", _class],
            ["direction", _direction], ["altitude", _altitude], ["maximumSpeed", _speed], ["approachDistance", _approach],
            ["runLength", _length], ["exitDistance", _exit], ["lifecycle", _lifecycle], ["circuitDirection", _circuitDirection],
            ["staticJumpEnabled", _staticEnabled], ["staticMinimumAltitude", _staticMin], ["staticMaximumAltitude", _staticMax],
            ["staticMaximumSpeed", _staticSpeed], ["staticChuteClass", _staticChute], ["haloJumpEnabled", _haloEnabled],
            ["haloMinimumAltitude", _haloMin], ["haloBackpackClass", _haloChute], ["requireOpenDoor", _requireDoor],
            ["autoDropPlayers", _dropPlayers], ["automaticJumpMode", _automaticMode], ["jumperCount", round _count],
            ["createJumpers", _count > 0], ["jumpInterval", _interval], ["createMarkers", _markers]
        ];
        [_config, player] remoteExecCall ["Waldo_fnc_ParadropCreateDropZone", 2];
    },
    {},
    _modulePos
] call zen_dialog_fnc_create;
true
