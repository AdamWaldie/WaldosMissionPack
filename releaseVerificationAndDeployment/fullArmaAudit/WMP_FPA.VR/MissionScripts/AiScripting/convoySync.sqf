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
if (remoteExecutedOwner != 2 || {hasInterface && {!isServer}}) exitWith {};
if (_revision <= (missionNamespace getVariable ["Waldo_Convoy_ReceivedRevision", -1])) exitWith {};
missionNamespace setVariable ["Waldo_Convoy_ReceivedRevision", _revision];
private _previous = missionNamespace getVariable ["Waldo_Convoy_LocalRegistry", []];
{
    _x params ["_group"];
    if (_registry findIf {(_x select 0) == _group} < 0) then {
        if (local _group) then {[_group] call Waldo_fnc_ConvoyReleaseLocal};
        private _handler = _group getVariable ["Waldo_Convoy_LocalHandler", -1];
        if (_handler >= 0 && {(_group getVariable ["Waldo_Convoy_Restore", []]) isEqualTo []}) then {
            _group removeEventHandler ["Local", _handler];
            _group setVariable ["Waldo_Convoy_LocalHandler", nil];
        };
    };
} forEach _previous;
missionNamespace setVariable ["Waldo_Convoy_LocalRegistry", _registry];
{
    _x params ["_group"];
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
            (_registry select _cursor) call Waldo_fnc_ConvoyTick;
            missionNamespace setVariable ["Waldo_Convoy_Cursor", _cursor + 1];
        };
    }, 0.25] call CBA_fnc_addPerFrameHandler];
};
