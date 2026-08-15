/*
 * Author: WaldoTheWarfighter
 * Presents user-friendly ZEN dialogs for creating, boarding and removing dynamic paradrop
 * operations. Operational side and airframe remain independent validated selectors. Zeus may
 * choose Static-Line, HALO or Both and request a route altitude/speed; the client provides context
 * and the server clamps incompatible values before building both the route and matching envelopes.
 * EMBARK is context-sensitive: a player underneath the module or in the
 * curator selection offers that player or their active player group, while no player target offers
 * a labelled boarding-object picker. EMBARK's operation list also includes any aircraft set up with
 * Waldo_fnc_ParadropQuickFlightSetup (a mission maker's own placed-and-crewed plane), not only
 * registry-backed Waldo_fnc_ParadropCreateDropZone operations. REMOVE includes both kinds and uses
 * the same delete-aircraft option and player-aboard safety rule for each.
 * Creation defaults to an empty player transport with one AI pilot and a continuous circuit;
 * generated AI cargo is explicitly optional.
 *
 * Locality and authority: Run only on the curator's interface client to collect friendly inputs.
 * Creation, boarding and removal are sent to their server-authoritative handlers for validation.
 *
 * Arguments:
 * 0: mode <STRING> - CREATE, EMBARK or REMOVE
 * 1: module position <ARRAY>
 * 2: module target <OBJECT> - object underneath the ZEN module, when supplied
 *
 * Return Value:
 * Boolean - true when a dialog was opened.
 * Result: The selected workflow is submitted only after the curator confirms the dialog.
 *
 * Current callers:
 * Paradrop ZEN registrations in Zen_initModules.sqf.
 *
 * Example:
 * ["EMBARK", _modulePos, _objectPos] call Waldo_fnc_ParadropDropZoneZen;
 */

params [["_mode", "CREATE", [""]], ["_modulePos", [], [[]]], ["_moduleTarget", objNull, [objNull]]];
if !(hasInterface && {isClass (configFile >> "CfgPatches" >> "zen_main")}) exitWith {false};
_mode = toUpperANSI _mode;

private _systems = missionNamespace getVariable ["Waldo_Paradrop_PublicDropZones", []];
private _systemIds = _systems apply {_x select 0};
private _systemLabels = _systems apply {
    private _airframeName = getText (configFile >> "CfgVehicles" >> (_x select 5) >> "displayName");
    format ["[DYNAMIC] %1 - %2", _x select 1, if (_airframeName == "") then {_x select 5} else {_airframeName}]
};

if (_mode in ["REMOVE", "EMBARK"]) then {
    // Embark also sees aircraft that were never registered as a managed drop zone operation - e.g. a
    // mission maker's own placed-and-crewed plane set up with Waldo_fnc_ParadropQuickFlightSetup -
    // via the same Waldo_Paradrop_PublicAircraft list that feeds their live map marker. Skip any id
    // already covered above so a registered operation is never listed twice.
    {
        _x params ["_id", "_name", "_aircraft"];
        if !(_id in _systemIds || {isNull _aircraft} || {!alive _aircraft}) then {
            _systemIds pushBack _id;
            _systemLabels pushBack format ["[EDEN] %1 - %2", _name, getText (configFile >> "CfgVehicles" >> (typeOf _aircraft) >> "displayName")];
        };
    } forEach (missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []]);
};
if (_mode in ["REMOVE", "EMBARK"] && {count _systemIds == 0}) exitWith {
    ["PARADROP", "No dynamic paradrop operations are registered.", "WARNING", "PARADROP_ZEN", 6]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};

if (_mode == "REMOVE") exitWith {
    [
        "Remove Paradrop Operation",
        [
            ["COMBO", ["Drop zone", "Select a dynamic operation or a pre-placed Eden/quick-flight operation."], [_systemIds, _systemLabels, 0]],
            ["CHECKBOX", ["Delete aircraft", "Deletes the selected operation's aircraft and AI crew when no players are aboard."], true]
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

// Waldo_Paradrop_AircraftClasses is the mission-maker-curated starting list (a handful of vanilla
// airframes by default). The dialog always extends it with every other jump-capable cargo aircraft
// actually present in the running modset - vanilla or third-party - discovered live via the same
// suitability test (public, Air, carries soldiers), via the same mod scan Dynamic AO uses for
// factions, instead of limiting the mission to whatever is hand-listed in config.
private _testAircraft = {
    isClass (configFile >> "CfgVehicles" >> _this)
    && {_this isKindOf "Air"}
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "scope") >= 2}
    && {getNumber (configFile >> "CfgVehicles" >> _this >> "transportSoldier") > 0}
};
private _configured = +(missionNamespace getVariable ["Waldo_Paradrop_AircraftClasses", []]);
private _classes = _configured select {_x call _testAircraft};
{_classes pushBackUnique _x} forEach ((["PARADROP_AIRCRAFT", _testAircraft] call Waldo_fnc_ResolveVehicleClassPool) apply {_x select 0});
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
private _defaultStaticAltitude = missionNamespace getVariable ["Waldo_Paradrop_DefaultStaticRouteAltitude", 300];
private _defaultStaticSpeed = missionNamespace getVariable ["Waldo_Paradrop_DefaultStaticRouteSpeed", 300];
_defaultStaticAltitude = (_defaultStaticAltitude max 100) min 2000;
_defaultStaticSpeed = (_defaultStaticSpeed max 80) min 500;
private _defaultName = format ["DZ %1", round (serverTime mod 10000)];

[
    "Create Dynamic Paradrop",
    [
        ["EDIT", ["Drop-zone name", "Used by map markers, boarding and removal selectors."], [_defaultName]],
        ["COMBO", ["Operational side", "Controls the AI pilot and optional AI jumpers; it does not filter the airframe."], [[west, east, independent], ["BLUFOR", "OPFOR", "Independent"], 0]],
        ["COMBO", ["Airframe", "Choose any configured cargo aircraft independently of operational side."], [_classes, _labels, 0]],
        ["SLIDER", ["Run direction", "Aircraft heading through standby, green and red lines."], [0, 359, 0, 0]],
        ["COMBO", ["Jump methods", "Static-Line, HALO, or both. WMP hard-gates altitude and speed so every selected method is usable."], [["STATIC", "HALO", "BOTH"], ["Static-Line", "HALO", "Static-Line and HALO"], 0]],
        ["SLIDER", ["Route altitude", "Metres AGL, exactly like Waldo_fnc_ParadropQuickFlightSetup. The server keeps it inside the selected jump method's MissionConfig limits."], [100, 2000, _defaultStaticAltitude, 0]],
        ["SLIDER", ["Route speed", "Kilometres per hour, exactly like Waldo_fnc_ParadropQuickFlightSetup. Static-Line routes cannot exceed WALDO_STATIC_MAXSPEED."], [80, 500, _defaultStaticSpeed, 0]],
        ["SLIDER", ["Approach distance", "Straight run-in before the standby line."], [800, 10000, 2500, 0]],
        ["SLIDER", ["Drop-zone length", "Distance between green and red lines."], [300, 6000, 2500, 0]],
        ["SLIDER", ["Exit distance", "Straight route after the red line before lifecycle handling."], [800, 10000, 2500, 0]],
        ["COMBO", ["After the pass", "Loop flies a wide circuit and realigns for another pass; retain makes one pass; despawn cleans the operation."], [["LOOP", "RETAIN", "DESPAWN"], ["Loop and repeat", "Single pass - retain aircraft", "Single pass - despawn"], 0]],
        ["COMBO", ["Circuit direction", "Side used for the wide return circuit."], [["LEFT", "RIGHT"], ["Left-hand circuit", "Right-hand circuit"], 0]],
        ["COMBO", ["Static-line parachute", "Used only by the Static Line profile; parachute vehicle created immediately after exit."], [_staticChutes, _staticLabels, 0]],
        ["COMBO", ["HALO parachute backpack", "Used only by the HALO profile; steerable backpack equipped after exit."], [_haloChutes, _haloLabels, 0]],
        ["CHECKBOX", ["Automatically sequence player cargo", "Forces embarked players out at the green line; normally leave off for jumpmaster-controlled player actions."], false],
        ["SLIDER", ["Optional generated AI jumpers", "AI cargo created for this operation. Default zero keeps the aircraft for players."], [0, 60, 0, 0]],
        ["SLIDER", ["Automatic jump interval", "Seconds between forced player or optional AI exits."], [0.5, 10, 2, 1]],
        ["CHECKBOX", ["Invincible drop aircraft", "Prevents normal engine damage for this operation and reapplies protection after locality changes. Scripted damage can still apply. Shipped default off."], missionNamespace getVariable ["Waldo_Paradrop_DefaultAircraftInvincible", false]],
        ["CHECKBOX", ["Create map markers", "Creates DZ, standby, green, red and named point markers."], true],
        ["CHECKBOX", ["Keep markers when the operation ends automatically", "Applies to an automatic DESPAWN pass or the aircraft being lost - the markers are removed along with the operation by default. Explicitly using Paradrop - Remove Operation always removes markers regardless of this setting."], false]
    ],
    {
        params ["_values", "_modulePosition"];
        _values params [
            "_name", "_side", "_class", "_direction", "_jumpMethods", "_requestedAltitude", "_requestedSpeed",
            "_approach", "_length", "_exit", "_lifecycle", "_circuitDirection", "_staticChute",
            "_haloChute", "_dropPlayers", "_count", "_interval", "_aircraftInvincible", "_markers",
            "_keepMarkersOnCleanup"
        ];
        private _idBase = [_name, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
        if (_idBase == "") then {_idBase = "DZ"};
        private _id = [_idBase] call Waldo_fnc_CreateRuntimeId;
        _jumpMethods = toUpperANSI _jumpMethods;
        if !(_jumpMethods in ["STATIC", "HALO", "BOTH"]) then {_jumpMethods = "STATIC"};
        private _staticEnabled = _jumpMethods in ["STATIC", "BOTH"];
        private _haloEnabled = _jumpMethods in ["HALO", "BOTH"];
        // These are hard compatibility gates, not cosmetic dialog advice. A client may submit any
        // slider combination, but the server repeats equivalent validation in CreateDropZone before
        // it creates an aircraft. Script callers retain the wider documented configuration API.
        private _staticMinimum = missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180];
        private _staticMaximum = (missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350]) max _staticMinimum;
        private _haloMinimum = missionNamespace getVariable ["WALDO_PARA_HALOALTITUDE", 1000];
        private _minimumAltitude = if (_haloEnabled) then {_haloMinimum} else {_staticMinimum};
        private _maximumAltitude = if (_jumpMethods == "STATIC") then {_staticMaximum} else {2000};
        private _altitude = ((_requestedAltitude max _minimumAltitude) min _maximumAltitude);
        private _speedCeiling = if (_staticEnabled) then {missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310]} else {500};
        private _speed = ((_requestedSpeed max 80) min _speedCeiling);
        private _config = createHashMapFromArray [
            ["id", _id], ["name", _name], ["centre", _modulePosition], ["side", _side], ["aircraftClass", _class],
            ["direction", _direction], ["altitude", _altitude], ["maximumSpeed", _speed], ["approachDistance", _approach],
            ["runLength", _length], ["exitDistance", _exit], ["lifecycle", _lifecycle], ["circuitDirection", _circuitDirection],
            ["jumpMethods", _jumpMethods], ["requestedAltitude", _requestedAltitude], ["requestedSpeed", _requestedSpeed],
            ["staticJumpEnabled", _staticEnabled], ["staticMinimumAltitude", _staticMinimum], ["staticMaximumAltitude", _staticMaximum],
            ["staticMaximumSpeed", _speedCeiling], ["staticChuteClass", _staticChute], ["haloJumpEnabled", _haloEnabled],
            ["haloMinimumAltitude", _haloMinimum],
            ["haloBackpackClass", _haloChute], ["requireOpenDoor", false],
            ["autoDropPlayers", _dropPlayers], ["automaticJumpMode", if (_jumpMethods == "HALO") then {"HALO"} else {"STATIC"}], ["jumperCount", round _count],
            ["createJumpers", _count > 0], ["jumpInterval", _interval], ["createMarkers", _markers],
            ["aircraftInvincible", _aircraftInvincible],
            ["keepMarkersOnCleanup", _keepMarkersOnCleanup]
        ];
        [_config, player] remoteExecCall ["Waldo_fnc_ParadropCreateDropZone", 2];
    },
    {},
    _modulePos
] call zen_dialog_fnc_create;
true
