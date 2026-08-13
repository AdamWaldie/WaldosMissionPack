/*
 * Author: WaldoTheWarfighter
 * Registers an existing aircraft or spawns a named, server-authoritative airborne gunship. The
 * server owns aircraft/crew creation, orbit state, service transitions and the JIP registry.
 * Eden object init fields run everywhere, so non-server copies are ignored. The ZEN module submits
 * directly to the server, where remote player requests require an assigned curator. Reusing an id
 * replaces the previous system.
 *
 * Locality and authority:
 * The server owns registry, aircraft/crew creation and service state. Eden client copies exit;
 * curator requests are validated on the server and published state supplies current/JIP clients.
 *
 * Arguments:
 * 0: config <HASHMAP> with:
 *    Required: id <STRING> - safe unique system key.
 *    Aircraft: aircraft <OBJECT>, or aircraftClass <STRING>/aircraftClasses <ARRAY> plus
 *      spawnPosition/home <ARRAY>. Side selection is independent from aircraft class.
 *    Identity/control: callsign <STRING>, side <SIDE>, faction <STRING>, controller <OBJECT> or
 *      controllerUID <STRING>, createCrew/forceCrewSide/lockAircraft <BOOL>. createCrew defaults
 *      true only applies when this function dynamically spawns the aircraft. An existing Eden
 *      aircraft must already contain its intended correctly sided crew; registration never creates
 *      or fills crew for a composition aircraft.
 *    Flight: home <ARRAY>; orbit <ARRAY or marker-name STRING>; radius/altitude <NUMBER>;
 *      direction <STRING CIRCLE_L|CIRCLE_R>; spawnDirection <NUMBER>. When orbit is a marker name,
 *      WMP reads its position, then deletes that Eden placeholder after successful registration so
 *      only the live WMP orbit marker remains.
 *    Service: minimumFuel, maximumDamage, serviceFuelFraction, serviceAmmoFraction and
 *      serviceDamage <NUMBER 0..1>; serviceDuration <SECONDS>; maximumServiceCycles <-1 unlimited>;
 *      returnWhenOutOfAmmo <BOOL>.
 *    Optional: turretProfiles <ARRAY> - display-name/turret-path pairs; defaults to discovered
 *      gunner turrets.
 *
 * Return Value:
 * Boolean - true when the server registered the system (or ignored a duplicate Eden client copy);
 * false when validation, aircraft or crew setup fails.
 *
 * Example:
 * private _gunship = createHashMapFromArray [
 *     ["id", "SPECTRE"], ["callsign", "SPECTRE"], ["side", west],
 *     ["aircraftClass", "B_T_VTOL_01_armed_F"],
 *     ["spawnPosition", [1000, 1000, 700]], ["orbit", "gunship_initial_orbit"]
 * ];
 * [_gunship] call Waldo_fnc_GunshipRegister;
 * Result: SPECTRE is created, crewed and registered, or the request returns false without partial state.
 *
 * Current callers: gunship ZEN registration, audit mission and mission-maker server scripts.
 */

params [["_config", createHashMap, [createHashMap]]];
if !(isServer) exitWith {true};
private _requestOwner = remoteExecutedOwner;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull getAssignedCuratorLogic _caller}) exitWith {false};
};
private _notifyRequester = {
    params ["_message", ["_state", "INFO"]];
    diag_log format ["[WMP GUNSHIP] owner=%1 state=%2 detail=%3", _requestOwner, _state, _message];
    if (_requestOwner > 2) then {
        ["AIRBORNE GUNSHIP", _message, _state, "GUNSHIP_ZEN", 8]
            remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
    };
};
private _id = _config getOrDefault ["id", ""];
private _safeId = [_id, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_id == "" || {_safeId != _id}) exitWith {["Registration rejected: a safe unique id is required.", "ERROR"] call _notifyRequester; false};
private _orbitInput = _config getOrDefault ["orbit", []];
private _orbitSourceMarker = "";
if (_orbitInput isEqualType "") then {
    _orbitSourceMarker = _orbitInput;
};
if (_orbitInput isEqualType "" && {_orbitSourceMarker == "" || {markerShape _orbitSourceMarker == ""}}) exitWith {
    [format ["Registration rejected: orbit marker '%1' does not exist.", _orbitSourceMarker], "ERROR"] call _notifyRequester;
    false
};
if (_orbitSourceMarker != "") then {
    _config set ["orbit", getMarkerPos _orbitSourceMarker];
};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
if (_id in keys _registry) then {[_id, false] call Waldo_fnc_GunshipDestroy};

private _aircraft = _config getOrDefault ["aircraft", objNull];
private _spawned = false;
if (isNull _aircraft) then {
    private _requestedSide = _config getOrDefault ["side", west];
    private _sideKey = switch (_requestedSide) do {case east: {"EAST"}; case independent: {"INDEPENDENT"}; case civilian: {"CIVILIAN"}; default {"WEST"}};
    private _sidePools = missionNamespace getVariable ["Waldo_Gunship_SideAircraftPools", createHashMap];
    private _classes = +(_config getOrDefault ["aircraftClasses", _sidePools getOrDefault [_sideKey, []]]);
    private _factionKey = _config getOrDefault ["faction", ""];
    if (_factionKey != "") then {
        private _factionPools = missionNamespace getVariable ["Waldo_Gunship_FactionAircraftPools", createHashMap];
        _classes = +(_factionPools getOrDefault [_factionKey, _classes]);
    };
    _classes = _classes select {isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "Air"}};
    private _class = _config getOrDefault ["aircraftClass", if (count _classes > 0) then {selectRandom _classes} else {""}];
    private _spawnPosition = _config getOrDefault ["spawnPosition", _config getOrDefault ["home", []]];
    private _spawnAltitude = ((_config getOrDefault ["altitude", missionNamespace getVariable ["Waldo_Gunship_DefaultAltitude", 700]]) max 100) min (missionNamespace getVariable ["Waldo_Gunship_MaximumAltitude", 5000]);
    if (count _spawnPosition == 2) then {_spawnPosition pushBack _spawnAltitude};
    if (count _spawnPosition >= 3 && {(_spawnPosition select 2) < 50}) then {_spawnPosition set [2, _spawnAltitude]};
    if !(isClass (configFile >> "CfgVehicles" >> _class) && {_class isKindOf "Air"} && {count _spawnPosition >= 2}) exitWith {false};
    _aircraft = createVehicle [_class, _spawnPosition, [], 0, "FLY"];
    [_aircraft] call Waldo_fnc_HeadlessPinCrew;
    _aircraft setPosATL _spawnPosition;
    _aircraft setDir (_config getOrDefault ["spawnDirection", 0]);
    if (_config getOrDefault ["createCrew", true]) then {createVehicleCrew _aircraft};
    _spawned = true;
};
// Existing Eden aircraft must be crewed in Eden. Do not create or fill any crew during registration:
// it duplicates composition intent, can populate unwanted seats and briefly exposes replicated AI
// on the wrong side. Only the separate dynamically spawned branch above may create runtime crew.
if (isNull _aircraft || {!(_aircraft isKindOf "Air")} || {isNull driver _aircraft}) exitWith {
    if (_spawned && {!isNull _aircraft}) then {deleteVehicleCrew _aircraft; deleteVehicle _aircraft};
    ["Registration failed: the selected aircraft could not be created with an AI pilot.", "ERROR"] call _notifyRequester;
    false
};
private _side = _config getOrDefault ["side", side group driver _aircraft];
if !(_side in [west, east, independent, civilian]) then {_side = side group driver _aircraft};
if (_config getOrDefault ["forceCrewSide", true] && {side group driver _aircraft != _side}) then {
    private _oldGroups = [];
    {_oldGroups pushBackUnique group _x} forEach crew _aircraft;
    private _newGroup = createGroup _side;
    (crew _aircraft) joinSilent _newGroup;
    {if (!isNull _x && {count units _x == 0}) then {deleteGroup _x}} forEach _oldGroups;
};
[_aircraft, _config getOrDefault ["lockAircraft", true]] remoteExecCall ["lock", owner _aircraft];
private _home = _config getOrDefault ["home", getPosATL _aircraft];
private _orbit = _config getOrDefault ["orbit", _home];
private _radius = ((_config getOrDefault ["radius", missionNamespace getVariable ["Waldo_Gunship_DefaultRadius", 1500]]) max 200) min (missionNamespace getVariable ["Waldo_Gunship_MaximumRadius", 10000]);
private _altitude = ((_config getOrDefault ["altitude", missionNamespace getVariable ["Waldo_Gunship_DefaultAltitude", 700]]) max 100) min (missionNamespace getVariable ["Waldo_Gunship_MaximumAltitude", 5000]);
private _turrets = _config getOrDefault ["turretProfiles", []];
if (count _turrets == 0) then {
    // allTurrets [.., true] lists every turret path the airframe actually has, independent of whether
    // anyone is currently sitting in it - unlike the previous fullCrew-based discovery, which only
    // found turrets that already happened to be crewed at this exact moment. That made discovery
    // depend on crew-fill timing/success instead of the airframe's own turret layout; the
    // Discovery itself must not silently come up empty just because a turret is deliberately vacant.
    {
        if (count _x > 0) then {_turrets pushBackUnique [format ["Turret %1", _x], _x]};
    } forEach (allTurrets [_aircraft, true]);
};
_config set ["id", _id];
_config set ["aircraft", _aircraft];
_config set ["side", _side];
_config set ["home", _home];
_config set ["orbit", _orbit];
_config set ["radius", _radius];
_config set ["altitude", _altitude];
private _direction = toUpperANSI (_config getOrDefault ["direction", "CIRCLE_L"]);
if !(_direction in ["CIRCLE_L", "CIRCLE_R"]) then {_direction = "CIRCLE_L"};
_config set ["direction", _direction];
_config set ["turretProfiles", _turrets];
_config set ["callsign", _config getOrDefault ["callsign", _id]];
_config set ["minimumFuel", ((_config getOrDefault ["minimumFuel", missionNamespace getVariable ["Waldo_Gunship_MinimumFuel", 0.25]]) max 0) min 1];
_config set ["maximumDamage", ((_config getOrDefault ["maximumDamage", missionNamespace getVariable ["Waldo_Gunship_MaximumDamage", 0.65]]) max 0) min 1];
_config set ["serviceDuration", (_config getOrDefault ["serviceDuration", missionNamespace getVariable ["Waldo_Gunship_DefaultServiceDuration", 900]]) max 0];
_config set ["serviceFuelFraction", ((_config getOrDefault ["serviceFuelFraction", missionNamespace getVariable ["Waldo_Gunship_ServiceFuelFraction", 1]]) max 0) min 1];
_config set ["serviceAmmoFraction", ((_config getOrDefault ["serviceAmmoFraction", missionNamespace getVariable ["Waldo_Gunship_ServiceAmmoFraction", 1]]) max 0) min 1];
_config set ["serviceDamage", ((_config getOrDefault ["serviceDamage", missionNamespace getVariable ["Waldo_Gunship_ServiceDamage", 0]]) max 0) min 1];
_config set ["maximumServiceCycles", round (_config getOrDefault ["maximumServiceCycles", missionNamespace getVariable ["Waldo_Gunship_MaximumServiceCycles", -1]])];
_config set ["returnWhenOutOfAmmo", _config getOrDefault ["returnWhenOutOfAmmo", missionNamespace getVariable ["Waldo_Gunship_ReturnWhenOutOfAmmo", true]]];
_aircraft setVariable ["Waldo_Gunship_Id", _id, true];
_aircraft enableSimulationGlobal true;
// Gunship crew is continuously driven by Waldo_fnc_GunshipMonitor and expected to stay server-owned
// (already excluded from WMP's own native headless rebalance via Waldo_Gunship_Registry) - pin it
// against ACE's own, uncoordinated ace_headless module too, since that mover has no knowledge of
// this system and no settle-time protection. This registration also carries mission-maker-configured
// setup (turret profiles, orbit, service policy above) applied once to this aircraft/group and never
// reapplied by a bare setGroupOwner - a migration wouldn't just desync the monitor, it would silently
// drop the configured orbit/turret behaviour. See headlessPinCrew.sqf for detail.
[_aircraft] call Waldo_fnc_HeadlessPinCrew;
private _controller = _config getOrDefault ["controller", objNull];
if (!isNull _controller && {!(_controller isKindOf "CAManBase")}) then {_controller = objNull};
private _controllerUID = _config getOrDefault ["controllerUID", if (!isNull _controller && {isPlayer _controller}) then {getPlayerUID _controller} else {""}];
private _state = createHashMapFromArray [
    ["config", _config], ["aircraft", _aircraft], ["controller", _controller], ["controllerUID", _controllerUID],
    ["status", "INITIALISING"], ["orbit", _orbit], ["spawned", _spawned], ["serviceCycles", 0],
    ["serviceCompleteAt", -1], ["active", true], ["handle", scriptNull]
];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
missionNamespace setVariable ["Waldo_Gunship_Enable", true, true];
private _handle = [_id] spawn Waldo_fnc_GunshipMonitor;
_state set ["handle", _handle];
_registry set [_id, _state];
missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
[] call Waldo_fnc_GunshipPublishState;
private _started = [_id, _orbit, "TRANSIT"] call Waldo_fnc_GunshipSetOrbit;
if (_started && {_orbitSourceMarker != ""}) then {
    private _safeMarkerKey = [_orbitSourceMarker, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
    [_orbitSourceMarker] remoteExecCall ["Waldo_fnc_HideSetupMarkerLocal", 0, format ["WMP_HIDE_SETUP_%1", _safeMarkerKey]];
    deleteMarker _orbitSourceMarker;
    diag_log format ["[WMP GUNSHIP] %1 replaced Eden orbit marker '%2' with its live WMP orbit marker.", _id, _orbitSourceMarker];
};
[
    if (_started) then {format ["%1 registered and flying to its orbit.", _config getOrDefault ["callsign", _id]]} else {"Registration created an aircraft but its initial orbit could not be assigned."},
    if (_started) then {"SUCCESS"} else {"ERROR"}
] call _notifyRequester;
_started
