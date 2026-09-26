/*
 * Author: WaldoTheWarfighter
 * Applies an ordered convoy registry on server/headless machines and runs one bounded worker per machine.
 * Locality/authority: server owns registration; driving commands execute only on current owners.
 * Repeat/JIP: ordered registry snapshots replace old settings; owner-local paths rebuild on migration.
 * Arguments: 0: revision <NUMBER>; 1: registry <ARRAY> of [group, configuration].
 * Return Value: Nothing.
 * Current callers: SimpleAiConvoy and JIP replay.
 * Example: [_revision, _registry] remoteExecCall ["Waldo_fnc_ConvoySync", 0, "Waldo_Convoy_RegistrySync"];
 */
params ["_revision", "_registry"];
if (remoteExecutedOwner != 2) exitWith {};
if (_revision <= (missionNamespace getVariable ["Waldo_Convoy_ReceivedRevision", -1])) exitWith {};
missionNamespace setVariable ["Waldo_Convoy_ReceivedRevision", _revision];
private _previous = missionNamespace getVariable ["Waldo_Convoy_LocalRegistry", []];
{
    _x params ["_group", "_configuration"];
    private _next = _registry findIf {(_x select 0) == _group};
    if (_next < 0 || {(((_registry select _next) select 1) select 0) != (_configuration select 0)}) then {
        [_group, _configuration, true] call Waldo_fnc_ConvoyDismountLocal;
        private _keepCrew = if (_next < 0) then {[]} else {((_registry select _next) select 1) select 4};
        [_group, true, _configuration select 7, _keepCrew] call Waldo_fnc_ConvoyReleaseLocal;
        private _handler = _group getVariable ["Waldo_Convoy_LocalHandler", -1];
        if (_handler >= 0 && {(_group getVariable ["Waldo_Convoy_Restore", []]) isEqualTo []}) then {
            _group removeEventHandler ["Local", _handler];
            _group setVariable ["Waldo_Convoy_LocalHandler", nil];
        };
    };
} forEach _previous;
missionNamespace setVariable ["Waldo_Convoy_LocalRegistry", _registry];
if (hasInterface && {!isServer}) exitWith {};
{
    _x params ["_group", "_configuration"];
    _group setVariable ["Waldo_Convoy_Restore", _configuration select 7];
    _group setVariable ["Waldo_Convoy_CrewDue", -1];
    _group setVariable ["Waldo_Convoy_NextTick", -1];
    _group setVariable ["Waldo_Convoy_Suspended", false];
    [_group, _configuration] call Waldo_fnc_ConvoyCrewLocal;
    if (isNil {_group getVariable "Waldo_Convoy_LocalHandler"}) then {
        _group setVariable ["Waldo_Convoy_LocalHandler", _group addEventHandler ["Local", {
            params ["_group", "_isLocal"];
            if (_isLocal && {!(_group getVariable ["Waldo_Convoy_Active", false])}) then {[_group] call Waldo_fnc_ConvoyReleaseLocal};
            _group setVariable ["Waldo_Convoy_LocalState", nil];
        }]];
    };
} forEach _registry;
private _handler = missionNamespace getVariable ["Waldo_Convoy_Worker", -1];
if (_registry isEqualTo [] && {_handler >= 0}) then {
    [_handler] call CBA_fnc_removePerFrameHandler;
    missionNamespace setVariable ["Waldo_Convoy_Worker", nil];
};
if (_registry isNotEqualTo [] && {_handler < 0}) then {
    missionNamespace setVariable ["Waldo_Convoy_Worker", [{
        private _registry = missionNamespace getVariable ["Waldo_Convoy_LocalRegistry", []];
        if (_registry isNotEqualTo []) then {
            private _cursor = (missionNamespace getVariable ["Waldo_Convoy_Cursor", 0]) mod count _registry;
            private _entry = _registry select _cursor;
            if (isServer && {isNull (_entry select 0)}) then {
                // Removed groups must still restore their surviving vehicles from the previous snapshot.
                private _serverRegistry = (missionNamespace getVariable ["Waldo_Convoy_Registry", []]) select {!isNull (_x select 0)};
                missionNamespace setVariable ["Waldo_Convoy_Registry", _serverRegistry];
                private _nextRevision = (missionNamespace getVariable ["Waldo_Convoy_RegistryRevision", 0]) + 1;
                missionNamespace setVariable ["Waldo_Convoy_RegistryRevision", _nextRevision];
                [_nextRevision, _serverRegistry] remoteExecCall ["Waldo_fnc_ConvoySync", 0, "Waldo_Convoy_RegistrySync"];
            } else {_entry call Waldo_fnc_ConvoyTick};
            missionNamespace setVariable ["Waldo_Convoy_Cursor", _cursor + 1];
        };
    }, 0.25] call CBA_fnc_addPerFrameHandler];
};
