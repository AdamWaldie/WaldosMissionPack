/*
 * Author: WaldoTheWarfighter
 * Presents user-friendly ZEN dialogs for creating, boarding and removing dynamic paradrop
 * operations. Operational side, airframe, static-line chute and HALO backpack are independent
 * validated selectors. EMBARK is context-sensitive: a player underneath the module or in the
 * curator selection offers that player or their active player group, while no player target offers
 * a labelled boarding-object picker.
 * Creation defaults to an empty player transport with one AI pilot and a continuous circuit;
 * generated AI cargo is explicitly optional.
 *
 * Arguments:
 * 0: mode <STRING> - CREATE, EMBARK or REMOVE
 * 1: module position <ARRAY>
 * 2: module target <OBJECT> - object underneath the ZEN module, when supplied
 *
 * Return Value:
 * Boolean - true when a dialog was opened.
 *
 * Called by:
 * Paradrop ZEN registrations in Zen_initModules.sqf.
 *
 * Example:
 * ["EMBARK", _modulePos, _objectPos] call Waldo_fnc_ParadropDropZoneZen;
 */

params [["_mode", "CREATE", [""]], ["_modulePos", [], [[]]], ["_moduleTarget", objNull, [objNull]]];
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
    private _selectedPlayers = (+(curatorSelected select 0)) select {isPlayer _x};
    private _selectedPlayer = if (!isNull _moduleTarget && {isPlayer _moduleTarget}) then {_moduleTarget} else {_selectedPlayers param [0, objNull]};
    if (isNull _selectedPlayer) then {
        private _nearPlayers = (nearestObjects [_modulePos, ["CAManBase"], 8, true]) select {isPlayer _x};
        _selectedPlayer = _nearPlayers param [0, objNull];
    };
    if (!isNull _selectedPlayer) exitWith {
        [
            "Embark Paradrop Players",
            [
                ["COMBO", ["Paradrop operation", "Aircraft that receives cargo players."], [_systemIds, _systemLabels, 0]],
                ["COMBO", ["Who to embark", "Move only the selected player, or every active player in that player's group."], [["PLAYER", "GROUP"], [format ["Selected player: %1", name _selectedPlayer], format ["Selected group: %1", groupId group _selectedPlayer]], 0]]
            ],
            {
                params ["_values", "_selectedPlayer"];
                _values params ["_id", "_scope"];
                private _units = if (_scope == "GROUP") then {units group _selectedPlayer} else {[_selectedPlayer]};
                _units = (_units select {isPlayer _x}) arrayIntersect _units;
                [_id, "SELECTION", _units, [], "", "", player] remoteExecCall ["Waldo_fnc_ParadropEmbark", 2];
            },
            {},
            _selectedPlayer
        ] call zen_dialog_fnc_create;
        true
    };

    private _pointClasses = +(missionNamespace getVariable ["Waldo_Paradrop_BoardingPointClasses", ["FlagPole_F", "Land_InfoStand_V1_F", "Land_InfoStand_V2_F", "Land_MapBoard_F"]]);
    _pointClasses = _pointClasses select {isClass (configFile >> "CfgVehicles" >> _x)};
    if (count _pointClasses == 0) then {_pointClasses = ["FlagPole_F"]};
    private _pointLabels = _pointClasses apply {
        private _displayName = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
        if (_displayName == "") then {_x} else {_displayName}
    };
    [
        "Embark Paradrop Players",
        [
            ["COMBO", ["Paradrop operation", "Aircraft that receives cargo players."], [_systemIds, _systemLabels, 0]],
            ["COMBO", ["Boarding-point object", "Physical object used by the reusable boarding action."], [_pointClasses, _pointLabels, 0]],
            ["EDIT", ["Boarding action label", "Text shown on the blue addAction."], ["Board Paradrop Aircraft"]]
        ],
        {
            params ["_values", "_arguments"];
            _arguments params ["_modulePosition"];
            _values params ["_id", "_pointClass", "_label"];
            [_id, "POLE", [], _modulePosition, _pointClass, _label, player]
                remoteExecCall ["Waldo_fnc_ParadropEmbark", 2];
        },
        {},
        [_modulePos]
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
        ["SLIDER", ["Flight/drop altitude", "Forced terrain-relative route height. Enabled jump floors/ceilings are server-normalized around this altitude so actions remain usable."], [100, 2000, 250, 0]],
        ["SLIDER", ["Maximum speed", "Forced route speed in km/h. Static-line maximum jump speed is kept at least 40 km/h above this value."], [80, 500, 220, 0]],
        ["SLIDER", ["Approach distance", "Straight run-in before the standby line."], [800, 10000, 2500, 0]],
        ["SLIDER", ["Drop-zone length", "Distance between green and red lines."], [300, 6000, 2500, 0]],
        ["SLIDER", ["Exit distance", "Straight route after the red line before lifecycle handling."], [800, 10000, 2500, 0]],
        ["COMBO", ["After the pass", "Loop flies a wide circuit and realigns for another pass; retain makes one pass; despawn cleans the operation."], [["LOOP", "RETAIN", "DESPAWN"], ["Loop and repeat", "Single pass - retain aircraft", "Single pass - despawn"], 0]],
        ["COMBO", ["Circuit direction", "Side used for the wide return circuit."], [["LEFT", "RIGHT"], ["Left-hand circuit", "Right-hand circuit"], 0]],
        ["CHECKBOX", ["Enable static-line jump", "Adds the configured static-line player jump action to cargo."], true],
        ["SLIDER", ["Static minimum altitude", "Preferred AGL floor. If it exceeds route altitude, the server lowers it to keep static-line actions usable."], [50, 1500, 180, 0]],
        ["SLIDER", ["Static maximum altitude", "Preferred AGL ceiling. The server raises it above route altitude with turbulence margin when needed."], [50, 2500, 350, 0]],
        ["SLIDER", ["Static maximum speed", "Preferred jump-speed ceiling. It is raised above route speed when needed so the aircraft cannot suppress its own action."], [80, 700, 310, 0]],
        ["COMBO", ["Static-line parachute", "Parachute vehicle created immediately after exit."], [_staticChutes, _staticLabels, 0]],
        ["CHECKBOX", ["Enable HALO jump", "Adds a HALO player jump action using a steerable parachute backpack."], false],
        ["SLIDER", ["HALO minimum altitude", "Preferred AGL floor. If it exceeds route altitude, the server lowers it to the route altitude so HALO remains available."], [100, 5000, 1000, 0]],
        ["COMBO", ["HALO parachute backpack", "Steerable backpack equipped after HALO exit."], [_haloChutes, _haloLabels, 0]],
        ["CHECKBOX", ["Require open ramp/door", "Requires one of WMP's recognized ramp/door animation sources. Automatically disabled when the selected airframe exposes none."], true],
        ["CHECKBOX", ["Automatically sequence player cargo", "Forces embarked players out at the green line; normally leave off for jumpmaster-controlled player actions."], false],
        ["COMBO", ["Automatic jump type", "Method used only for automatic sequencing. If that method is disabled, the server uses the enabled alternative or disables automatic player exits."], [["STATIC", "HALO"], ["Static line", "HALO"], 0]],
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
        private _id = [_idBase] call Waldo_fnc_CreateRuntimeId;
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
