/*
 * Author: WaldoTheWarfighter
 * Registers an existing aircraft or spawns a named, server-authoritative airborne gunship. The
 * server owns aircraft/crew creation, orbit state, service transitions and the JIP registry.
 * Non-server calls are forwarded; remote player requests require an assigned curator. Reusing an
 * id replaces the previous system.
 *
 * Arguments:
 * 0: config <HASHMAP> with:
 *    Required: id <STRING> - safe unique system key.
 *    Aircraft: aircraft <OBJECT>, or aircraftClass <STRING>/aircraftClasses <ARRAY> plus
 *      spawnPosition/home <ARRAY>. Side selection is independent from aircraft class.
 *    Identity/control: callsign <STRING>, side <SIDE>, faction <STRING>, controller <OBJECT> or
 *      controllerUID <STRING>, createCrew/forceCrewSide/lockAircraft <BOOL>.
 *    Flight: home/orbit <ARRAY>, radius/altitude <NUMBER>, direction <STRING CIRCLE_L|CIRCLE_R>,
 *      spawnDirection <NUMBER>.
 *    Service: minimumFuel, maximumDamage, serviceFuelFraction, serviceAmmoFraction and
 *      serviceDamage <NUMBER 0..1>; serviceDuration <SECONDS>; maximumServiceCycles <-1 unlimited>;
 *      returnWhenOutOfAmmo <BOOL>.
 *    Optional: turretProfiles <ARRAY> - display-name/turret-path pairs; defaults to discovered
 *      gunner turrets.
 *
 * Return Value:
 * Boolean - true when forwarded/registered; false when validation, aircraft or crew setup fails.
 *
 * Example:
 * private _gunship = createHashMapFromArray [
 *     ["id", "SPECTRE"], ["callsign", "SPECTRE"], ["side", west],
 *     ["aircraftClass", "B_T_VTOL_01_armed_F"],
 *     ["spawnPosition", [1000, 1000, 700]], ["orbit", [4000, 4000, 0]]
 * ];
 * [_gunship] call Waldo_fnc_GunshipRegister;
 *
 * Current callers: gunship ZEN registration, audit mission and mission-maker server scripts.
 */

params [["_config", createHashMap, [createHashMap]]];
if !(isServer) exitWith {[_config] remoteExecCall ["Waldo_fnc_GunshipRegister", 2]; true};
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
    _aircraft setPosATL _spawnPosition;
    _aircraft setDir (_config getOrDefault ["spawnDirection", 0]);
    createVehicleCrew _aircraft;
    _spawned = true;
};
// createVehicleCrew only ever fills EMPTY positions (it never ejects/replaces an existing occupant),
// so this is safe to run unconditionally rather than only when there is no driver at all. An
// Eden-placed aircraft that already has a placed-and-crewed pilot (driver not null) previously never
// reached this call, which left any gunner turret with no AI assigned - the turret still physically
// existed on the airframe, but with nobody sitting in it "Take Control" had nothing to discover below
// and nothing to hand control of even if a profile was configured manually.
if (!isNull _aircraft && {_config getOrDefault ["createCrew", true]}) then {createVehicleCrew _aircraft};
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
    // createVehicleCrew fix above now fills these before Take Control tries to use one, but discovery
    // itself should not silently come up empty just because a turret's crew hadn't been assigned yet.
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
[
    if (_started) then {format ["%1 registered and flying to its orbit.", _config getOrDefault ["callsign", _id]]} else {"Registration created an aircraft but its initial orbit could not be assigned."},
    if (_started) then {"SUCCESS"} else {"ERROR"}
] call _notifyRequester;
_started
