/*
 * Author: WaldoTheWarfighter
 * Validates controller and curator requests for a registered airborne gunship.
 *
 * Locality and authority: forwards to the server when called on a client; only server execution
 * mutates the registry. A remote request must come from the assigned controller (most operations)
 * or an active curator; SET_ORBIT_PARAMS is available to the controller only while
 * TRANSIT/ON_STATION/CONTROLLED, matching SET_ORBIT/SERVICE's own gating.
 *
 * Arguments: 0: id <STRING>; 1: operation <STRING> - ASSIGN|SET_ORBIT|SET_ORBIT_PARAMS|TAKE_CONTROL|
 * RELEASE_CONTROL|SERVICE|RETURN|REMOVE; 2: arguments <ARRAY> (SET_ORBIT_PARAMS: [radius, altitude]);
 * 3: requester <OBJECT>
 * Return Value: Boolean
 * Example: ["spectre_1", "SET_ORBIT_PARAMS", [2000, 900], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2];
 */

params ["_id", "_operation", ["_arguments", [], [[]]], ["_requester", objNull, [objNull]]];
if !(isServer) exitWith {[_id, _operation, _arguments, player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]; true};
private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
if !(_id in keys _registry) exitWith {false};
private _state = _registry get _id;
private _controller = _state getOrDefault ["controller", objNull];
private _config = _state get "config";
private _remoteRequest = remoteExecutedOwner > 0;
if (_remoteRequest && {isNull _requester || {owner _requester != remoteExecutedOwner}}) exitWith {false};
private _isController = !_remoteRequest || {!isNull _controller && {_requester isEqualTo _controller}};
private _isCurator = !_remoteRequest || {!isNull _requester && {!isNull getAssignedCuratorLogic _requester}};

switch (toUpperANSI _operation) do {
    case "ASSIGN": {
        if !(_isCurator) exitWith {false};
        private _newController = _arguments param [0, objNull];
        if (isNull _newController || {!isPlayer _newController}) exitWith {false};
        if (!isNull _controller && {!(_controller isEqualTo _newController)}) then {
            [_id] remoteExecCall ["Waldo_fnc_GunshipReleaseControlLocal", owner _controller];
        };
        _state set ["controller", _newController];
        _state set ["controllerUID", getPlayerUID _newController];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
        [] call Waldo_fnc_GunshipPublishState;
        [format ["You are assigned as controller for %1.", _config getOrDefault ["callsign", _id]]] remoteExecCall ["Waldo_fnc_GunshipNotifyLocal", owner _newController];
        private _callback = _config getOrDefault ["onControllerChanged", {}];
        if (_callback isEqualType {}) then {[_id, _controller, _newController, _state] call _callback};
        true
    };
    case "SET_ORBIT": {
        if !(_isController || {_isCurator}) exitWith {false};
        if (_isController && {!_isCurator} && {!((_state getOrDefault ["status", ""]) in ["TRANSIT", "ON_STATION", "CONTROLLED"])}) exitWith {false};
        private _position = _arguments param [0, []];
        if !(_position isEqualType [] && {count _position >= 2}) exitWith {false};
        private _home = _config getOrDefault ["home", _position];
        private _maximumRange = _config getOrDefault ["maximumRangeFromHome", -1];
        if (_maximumRange >= 0 && {_position distance2D _home > _maximumRange}) exitWith {false};
        [_id, _position, "TRANSIT"] call Waldo_fnc_GunshipSetOrbit
    };
    case "TAKE_CONTROL": {
        if !(_isController) exitWith {
            ["You are not this gunship's assigned controller. Ask your curator to run Gunship: Assign Controller."] remoteExecCall ["Waldo_fnc_GunshipNotifyLocal", owner _requester];
            false
        };
        if !((_state getOrDefault ["status", ""]) in ["ON_STATION", "CONTROLLED"]) exitWith {
            [format ["%1 is not on station yet - weapon control unlocks once it arrives.", _config getOrDefault ["callsign", _id]]] remoteExecCall ["Waldo_fnc_GunshipNotifyLocal", owner _requester];
            false
        };
        private _path = _arguments param [0, []];
        private _validPaths = (_config getOrDefault ["turretProfiles", []]) apply {_x select 1};
        if !(_path in _validPaths) exitWith {
            [format ["%1 has no turret at that station right now - its crew may have changed.", _config getOrDefault ["callsign", _id]]] remoteExecCall ["Waldo_fnc_GunshipNotifyLocal", owner _requester];
            false
        };
        [_id, "CONTROLLED", format ["%1 weapon control connected.", _config getOrDefault ["callsign", _id]]] call Waldo_fnc_GunshipSetState;
        [_id, _state getOrDefault ["aircraft", objNull], _path] remoteExecCall ["Waldo_fnc_GunshipGrantControlLocal", owner _requester];
        true
    };
    case "RELEASE_CONTROL": {
        if !(_isController || {_isCurator}) exitWith {false};
        if (!isNull _controller) then {[_id] remoteExecCall ["Waldo_fnc_GunshipReleaseControlLocal", owner _controller]};
        if ((_state getOrDefault ["status", ""]) == "CONTROLLED") then {[_id, "ON_STATION"] call Waldo_fnc_GunshipSetState};
        true
    };
    case "SERVICE": {
        if !(_isController || {_isCurator}) exitWith {false};
        if !((_state getOrDefault ["status", ""]) in ["TRANSIT", "ON_STATION", "CONTROLLED"]) exitWith {false};
        if (!isNull _controller) then {[_id] remoteExecCall ["Waldo_fnc_GunshipReleaseControlLocal", owner _controller]};
        // A null requester only ever arrives from Waldo_fnc_GunshipMonitor's own automatic
        // fuel/damage/ammo trigger; every player-facing "Return for Service" action always passes
        // a real requester object. This is the one place both paths are distinguishable.
        _state set ["offStationReason", if (isNull _requester) then {"AUTO"} else {"REQUEST"}];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
        [_id, _config getOrDefault ["home", []], "RTB"] call Waldo_fnc_GunshipSetOrbit
    };
    case "RETURN": {
        if !(_isController || {_isCurator}) exitWith {false};
        if ((_state getOrDefault ["status", ""]) == "DESTROYED") exitWith {false};
        [_id, _state getOrDefault ["orbit", _config getOrDefault ["orbit", []]], "TRANSIT"] call Waldo_fnc_GunshipSetOrbit
    };
    case "REMOVE": {
        if !(_isCurator) exitWith {false};
        [_id, _arguments param [0, false]] call Waldo_fnc_GunshipDestroy
    };
    case "SET_ORBIT_PARAMS": {
        // Live loiter radius/altitude change from the FAC/JTAC "Configure Orbit" dialog
        // (Waldo_fnc_GunshipPromptOrbitConfig). Unlike Waldo_fnc_GunshipRegister's own 200m/100m
        // registration-time floors (gunshipRegister.sqf), this interactive path enforces a
        // deliberately higher 300m floor on both values - the popup, not mission-maker-authored
        // registration config, is what the 300m requirement targets.
        if !(_isController || {_isCurator}) exitWith {false};
        if (_isController && {!_isCurator} && {!((_state getOrDefault ["status", ""]) in ["TRANSIT", "ON_STATION", "CONTROLLED"])}) exitWith {false};
        private _aircraft = _state getOrDefault ["aircraft", objNull];
        private _maximumRadius = missionNamespace getVariable ["Waldo_Gunship_MaximumRadius", 10000];
        private _maximumAltitude = missionNamespace getVariable ["Waldo_Gunship_MaximumAltitude", 5000];
        private _radius = ((_arguments param [0, _config getOrDefault ["radius", 1500]]) max 300) min _maximumRadius;
        private _altitude = ((_arguments param [1, _config getOrDefault ["altitude", 700]]) max 300) min _maximumAltitude;
        _config set ["radius", _radius];
        _config set ["altitude", _altitude];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
        // Only meaningful while the aircraft is actually flying a loiter route - re-applying it
        // during RTB/SERVICING/DESTROYED/UNAVAILABLE would fight the route those states already own.
        if (!isNull _aircraft && {(_state getOrDefault ["status", ""]) in ["TRANSIT", "ON_STATION", "CONTROLLED"]}) then {
            [
                _aircraft, _state getOrDefault ["orbit", _config getOrDefault ["orbit", []]],
                _altitude, _radius, _config getOrDefault ["direction", "CIRCLE_L"],
                _config getOrDefault ["pilotBehaviour", "CARELESS"], _config getOrDefault ["pilotCombatMode", "BLUE"]
            ] remoteExecCall ["Waldo_fnc_GunshipApplyOrbitLocal", owner _aircraft];
        };
        [] call Waldo_fnc_GunshipPublishState;
        if (!isNull _requester) then {
            [format ["%1 orbit updated: radius %2m, altitude %3m.", _config getOrDefault ["callsign", _id], round _radius, round _altitude]] remoteExecCall ["Waldo_fnc_GunshipNotifyLocal", owner _requester];
        };
        true
    };
    default {false};
}
