/*
 * Author: WaldoTheWarfighter
 * Applies an explicit `@Callsign` suffix from each group leader's Eden role description to that
 * group before the server compiles the ACRE communications plan. This is a fallback for missions
 * where CBA's Eden callsign attribute did not survive mission startup. Groups without an explicit
 * suffix are never renamed. Duplicate requested callsigns are rejected and logged.
 * Locality and authority: call once on the server from initServer.sqf before Waldo_fnc_ACRE2Init.
 * The callsign is broadcast by CBA_fnc_setCallsign when available, with setGroupIdGlobal as the
 * engine fallback. This function configures group identity only; it never applies player radios.
 *
 * Arguments: None.
 * Return Value: ARRAY - [renamed count, unchanged count, rejected count].
 *
 * Role examples:
 * - `Alpha Rifleman` has no `@` and is ignored.
 * - `Alpha Team Leader@Viking` sets the leader's group callsign to `Viking`.
 * - `Alpha Team Leader@Viking-1-1` sets it to `Viking-1-1`.
 * Example call: call Waldo_fnc_ACRE2ReconcileGroupCallsigns;
 * Current caller: initServer.sqf before authoritative ACRE plan compilation.
 */
if (!isServer) exitWith {[0, 0, 0]};

private _trimWhitespace = {
    params [['_text', '', ['']]];
    private _characters = toArray _text;
    while {count _characters > 0 && {(_characters select 0) in [9, 10, 13, 32]}} do {
        _characters deleteAt 0;
    };
    while {count _characters > 0 && {(_characters select ((count _characters) - 1)) in [9, 10, 13, 32]}} do {
        _characters deleteAt ((count _characters) - 1);
    };
    toString _characters
};

private _claimed = createHashMap;
private _renamed = 0;
private _unchanged = 0;
private _rejected = 0;

{
    private _group = _x;
    private _leader = leader _group;
    if (isNull _leader) then {
        _unchanged = _unchanged + 1;
    } else {
        private _description = roleDescription _leader;
        private _separator = _description find '@';
        if (_separator < 0) then {
            _unchanged = _unchanged + 1;
        } else {
            private _requested = [_description select [_separator + 1]] call _trimWhitespace;
            private _key = toUpperANSI (((_requested splitString " -_.") joinString ""));
            if (_requested == '' || {_requested find '@' >= 0}) then {
                _rejected = _rejected + 1;
                diag_log format ['[WMP ACRE] Empty or malformed @Callsign suffix rejected for group %1.', groupId _group];
            } else {
                private _existing = _claimed getOrDefault [_key, grpNull];
                if (!isNull _existing && {_existing != _group}) then {
                    _rejected = _rejected + 1;
                    diag_log format ['[WMP ACRE] Duplicate @Callsign %1 rejected for group %2; already claimed by %3.', _requested, groupId _group, groupId _existing];
                } else {
                    _claimed set [_key, _group];
                    if (toUpperANSI ((((groupId _group) splitString " -_.") joinString "")) == _key) then {
                        _unchanged = _unchanged + 1;
                    } else {
                        if (isNil 'CBA_fnc_setCallsign') then {
                            _group setGroupIdGlobal [_requested];
                        } else {
                            [_group, _requested] call CBA_fnc_setCallsign;
                        };
                        if (toUpperANSI ((((groupId _group) splitString " -_.") joinString "")) != _key) then {
                            _group setGroupIdGlobal [_requested];
                        };
                        if (toUpperANSI ((((groupId _group) splitString " -_.") joinString "")) == _key) then {
                            _renamed = _renamed + 1;
                            diag_log format ['[WMP ACRE] Group callsign reconciled from leader role description: %1.', _requested];
                        } else {
                            _rejected = _rejected + 1;
                            diag_log format ['[WMP ACRE] Group callsign read-back failed for requested value %1; current groupId is %2.', _requested, groupId _group];
                        };
                    };
                };
            };
        };
    };
} forEach allGroups;

[_renamed, _unchanged, _rejected]
