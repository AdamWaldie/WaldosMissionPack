/*
 * Author: WaldoTheWarfighter
 * Validates controller and curator requests for a registered airborne gunship.
 * Arguments: 0: id <STRING>; 1: operation <STRING>; 2: arguments <ARRAY>; 3: requester <OBJECT>
 * Return Value: Boolean
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
    default {false};
}
