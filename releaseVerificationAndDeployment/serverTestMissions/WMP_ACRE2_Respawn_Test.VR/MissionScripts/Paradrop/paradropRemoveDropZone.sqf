/*
 * Author: WaldoTheWarfighter
 * Removes one server-owned paradrop operation, boarding points, aircraft/embarked generated AI
 * and global markers.
 * Generated troops that have already jumped are deliberately left in the mission; removing an
 * operation is not a remote-delete mechanism for deployed infantry. Aircraft deletion is safely
 * suppressed while players remain aboard. Empty owned groups are cleaned.
 *
 * Arguments:
 * 0: operation ID <STRING>
 * 1: delete aircraft <BOOL> (default true)
 * 2: requester <OBJECT> (default objNull) - curator authorization for remote calls
 * 3: notify requester <BOOL> (default true)
 * 4: delete markers <BOOL> (default true) - explicit removal (this function called directly, e.g.
 *    the ZEN "Remove Operation" module) always tears down the markers along with everything else.
 *    Automatic cleanup (on aircraft loss or a DESPAWN pass completing normally) passes the inverse of
 *    the operation's own configured keepMarkersOnCleanup option here (default false there, so markers
 *    are deleted by default - see Waldo_fnc_ParadropCreateDropZone), so a mission maker who wants the
 *    markers left in place can opt out.
 *
 * Pre-placed Eden/quick-flight operations use the same removal contract as runtime-created ones:
 * markers and registration are removed, and the delete-aircraft option removes aircraft and AI crew
 * unless a player is aboard. A retained aircraft loses its WMP jump interactions.
 *
 * Locality and authority: The server owns removal and cleanup. Curator requests are authenticated
 * before changing the registry; public aircraft state drives local action removal for all clients.
 *
 * Return Value: Boolean - true when a registered dynamic or quick/Eden operation was removed.
 * Result: Successful removal cleans the same WMP-owned state for ZEN and Eden-created operations.
 *
 * Example: ["DZ_ALPHA", true, player, true] remoteExecCall ["Waldo_fnc_ParadropRemoveDropZone", 2];
 * Current callers: ParadropRemoveDropZoneZen, automatic run cleanup and mission scripts.
 */
params [["_id", "", [""]], ["_deleteAircraft", true, [false]], ["_requester", objNull, [objNull]], ["_notifyRequester", true, [false]], ["_deleteMarkers", true, [false]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_ParadropRemoveDropZone", 2]; true};
if (remoteExecutedOwner > 0) then {
    if (isNull _requester || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}) exitWith {false};
};
private _registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
if !(_id in keys _registry) exitWith {
    private _quickRegistry = missionNamespace getVariable ["Waldo_Paradrop_QuickSetups", createHashMap];
    if !(_id in keys _quickRegistry) exitWith {false};
    private _quickState = _quickRegistry get _id;
    if (_deleteMarkers) then {{deleteMarker _x} forEach (_quickState getOrDefault ["markers", []])};
    private _quickAircraft = _quickState getOrDefault ["aircraft", objNull];
    private _deletionSuppressed = false;
    if (_deleteAircraft && {!isNull _quickAircraft} && {(crew _quickAircraft) findIf {isPlayer _x} >= 0}) then {
        _deleteAircraft = false;
        _deletionSuppressed = true;
        diag_log format ["[WMP PARADROP] Pre-placed aircraft deletion suppressed because players remain aboard id=%1", _id];
        if (!isNull _requester && {_notifyRequester}) then {
            ["PARADROP", "Operation and markers removed, but the aircraft was retained because players are aboard.", "WARNING", "PARADROP_REMOVE", 8]
                remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
        };
    };
    if (!isNull _quickAircraft) then {
        private _actionJipKey = _quickAircraft getVariable ["Waldo_Paradrop_ActionJipKey", ""];
        if (_actionJipKey != "") then {[] remoteExecCall ["", _actionJipKey]};
        private _damageJipKey = _quickAircraft getVariable ["Waldo_Paradrop_DamageJipKey", ""];
        if (_damageJipKey != "") then {[] remoteExecCall ["", _damageJipKey]};
        if (!_deleteAircraft && {_quickAircraft getVariable ["Waldo_Paradrop_AircraftInvincible", false]}) then {
            [netId _quickAircraft, false] remoteExecCall ["Waldo_fnc_ParadropSetAircraftInvincibilityLocal", 0];
        };
        _quickAircraft setVariable ["Waldo_Paradrop_AircraftInvincible", false, true];
        _quickAircraft setVariable ["Waldo_Paradrop_DamageJipKey", "", true];
        [_quickAircraft] remoteExecCall ["Waldo_fnc_ParadropRemoveAircraftActionsLocal", 0];
        _quickAircraft setVariable ["Waldo_Paradrop_LocalSetupComplete", false, true];
        _quickAircraft setVariable ["Waldo_Paradrop_ConfiguredJumpTypes", [], true];
    };
    if (_deleteAircraft && {!isNull _quickAircraft}) then {deleteVehicleCrew _quickAircraft; deleteVehicle _quickAircraft};
    private _quickFlightGroup = _quickState getOrDefault ["flightGroup", grpNull];
    if (!isNull _quickFlightGroup && {count units _quickFlightGroup == 0}) then {deleteGroup _quickFlightGroup};
    _quickRegistry deleteAt _id;
    missionNamespace setVariable ["Waldo_Paradrop_QuickSetups", _quickRegistry];
    private _publicAircraft = missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []];
    _publicAircraft = _publicAircraft select {(_x select 0) != _id};
    missionNamespace setVariable ["Waldo_Paradrop_PublicAircraft", _publicAircraft, true];
    [] remoteExecCall ["Waldo_fnc_ParadropSetupLocal", 0];
    diag_log format ["[WMP PARADROP] Removed pre-placed/quick operation id=%1 deleteAircraft=%2.", _id, _deleteAircraft];
    if (!isNull _requester && {_notifyRequester} && {!_deletionSuppressed}) then {
        ["PARADROP", "Operation state, interactions and associated map markers removed.", "SUCCESS", "PARADROP_REMOVE", 7]
            remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
    };
    true
};
private _state = _registry get _id;
if (_deleteMarkers) then {{deleteMarker _x} forEach (_state getOrDefault ["markers", []])};
{if (!isNull _x) then {deleteVehicle _x}} forEach (_state getOrDefault ["boardingPoints", []]);
private _aircraft = _state getOrDefault ["aircraft", objNull];
if (_deleteAircraft && {!isNull _aircraft} && {(crew _aircraft) findIf {isPlayer _x} >= 0}) then {
    _deleteAircraft = false;
    diag_log format ["[WMP PARADROP] Aircraft deletion suppressed because players remain aboard id=%1", _id];
    if (!isNull _requester && {_notifyRequester}) then {
        ["DYNAMIC PARADROP", "Operation and markers removed, but the aircraft was retained because players are aboard.", "WARNING", "PARADROP_REMOVE", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
    };
};
if (!isNull _aircraft) then {
    private _damageJipKey = _aircraft getVariable ["Waldo_Paradrop_DamageJipKey", ""];
    if (_damageJipKey != "") then {[] remoteExecCall ["", _damageJipKey]};
    if (!_deleteAircraft && {_aircraft getVariable ["Waldo_Paradrop_AircraftInvincible", false]}) then {
        [netId _aircraft, false] remoteExecCall ["Waldo_fnc_ParadropSetAircraftInvincibilityLocal", 0];
    };
    _aircraft setVariable ["Waldo_Paradrop_AircraftInvincible", false, true];
    _aircraft setVariable ["Waldo_Paradrop_DamageJipKey", "", true];
};
if (!_deleteAircraft && {!isNull _aircraft}) then {
    private _actionJipKey = _aircraft getVariable ["Waldo_Paradrop_ActionJipKey", ""];
    if (_actionJipKey != "") then {[] remoteExecCall ["", _actionJipKey]};
    [_aircraft] remoteExecCall ["Waldo_fnc_ParadropRemoveAircraftActionsLocal", 0];
    _aircraft setVariable ["Waldo_Paradrop_LocalSetupComplete", false, true];
    _aircraft setVariable ["Waldo_Paradrop_ConfiguredJumpTypes", [], true];
};
if (_deleteAircraft && {!isNull _aircraft}) then {
    private _actionJipKey = _aircraft getVariable ["Waldo_Paradrop_ActionJipKey", ""];
    if (_actionJipKey != "") then {[] remoteExecCall ["", _actionJipKey]};
};
if (_deleteAircraft && {!isNull _aircraft}) then {deleteVehicleCrew _aircraft; deleteVehicle _aircraft};
if (_deleteAircraft) then {
    {
        if (!isNull _x && {!isPlayer _x} && {vehicle _x == _aircraft}) then {deleteVehicle _x};
    } forEach (_state getOrDefault ["jumpers", []]);
};
private _flightGroup = _state getOrDefault ["flightGroup", grpNull];
if (!isNull _flightGroup && {count units _flightGroup == 0}) then {deleteGroup _flightGroup};
private _jumpGroup = _state getOrDefault ["jumpGroup", grpNull];
if (!isNull _jumpGroup && {count units _jumpGroup == 0}) then {deleteGroup _jumpGroup};
_registry deleteAt _id;
missionNamespace setVariable ["Waldo_Paradrop_DropZones", _registry];
private _public = missionNamespace getVariable ["Waldo_Paradrop_PublicDropZones", []];
_public = _public select {(_x select 0) != _id};
missionNamespace setVariable ["Waldo_Paradrop_PublicDropZones", _public, true];
private _publicAircraft = missionNamespace getVariable ["Waldo_Paradrop_PublicAircraft", []];
_publicAircraft = _publicAircraft select {(_x select 0) != _id};
missionNamespace setVariable ["Waldo_Paradrop_PublicAircraft", _publicAircraft, true];
[] remoteExecCall ["Waldo_fnc_ParadropSetupLocal", 0];
diag_log format ["[WMP PARADROP] Removed id=%1 deleteAircraft=%2", _id, _deleteAircraft];
if (!isNull _requester && {_notifyRequester}) then {
    ["DYNAMIC PARADROP", "Operation state and associated map markers removed.", "SUCCESS", "PARADROP_REMOVE", 6] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
};
true
