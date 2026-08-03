/*
 * Author: WaldoTheWarfighter
 * Applies the current server plan to the local player's supported carried radios. Unique radio
 * IDs are handled only after ACRE initialises. Calls are idempotent by revision, side, group and
 * loadout generation; unsupported and newly captured radios are left unchanged.
 *
 * Arguments:
 * 0: force <BOOL> (default false)
 * 1: reason <STRING> (default MANUAL)
 * 2: allow one retry <BOOL> (internal, default true)
 *
 * Return Value: BOOL - true when a matching plan was applied or was already current.
 *
 * Example: [true, 'RESPAWN'] call Waldo_fnc_ACRE2ApplyPlayerPlan;
 * Current callers: Waldo_fnc_ACRE2Init, respawn restoration and persistence fallback.
 */
params [['_force', false, [true]], ['_reason', 'MANUAL', ['']], ['_retryAllowed', true, [true]]];
if (!hasInterface || {isNull player} || {!(isClass (configFile >> 'CfgPatches' >> 'acre_main'))}) exitWith {false};
private _plan = missionNamespace getVariable ['Waldo_ACRE2_Plan', []];
if (count _plan < 4) exitWith {false};
private _sideKey = switch (side player) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'}};
private _sideIndex = (_plan select 2) findIf {(_x select 0) == _sideKey};
if (_sideIndex < 0) exitWith {false};
private _sidePlan = (_plan select 2) select _sideIndex;
_sidePlan params ['_unusedSide', '_preset', '_nets', '_groups'];
private _groupKey = toUpper groupId group player;
private _groupIndex = _groups findIf {(_x select 0) == _groupKey};
if (_groupIndex < 0) exitWith {diag_log format ['[WMP ACRE] No %1 plan for group %2.', _sideKey, _groupKey]; false};
private _generation = missionNamespace getVariable ['Waldo_ACRE2_LoadoutGeneration', 0];
if ((missionNamespace getVariable ['Waldo_ACRE2_PersistenceRadioGeneration', -1]) == _generation) exitWith {true};
private _signature = format ['%1|%2|%3|%4', _plan select 1, _sideKey, _groupKey, _generation];
if (!_force && {(uiNamespace getVariable ['Waldo_ACRE2_AppliedSignature', '']) == _signature}) exitWith {true};
private _groupPlan = _groups select _groupIndex;
_groupPlan params ['_unusedGroup', '_netKeys', '_shortAssignment'];
private _radios = [player] call acre_api_fnc_getCurrentRadioList;
private _success = true;
private _shortFlat = ((_shortAssignment select 0) - 1) * 16 + (_shortAssignment select 1);
{
    if ([_x, 'ACRE_PRC343'] call acre_api_fnc_isKindOf) then {
        if !([_x, _shortFlat] call acre_api_fnc_setRadioChannel) then {_success = false};
        if (([_x] call acre_api_fnc_getRadioChannel) != _shortFlat) then {_success = false};
        if !([_x, 'LEFT'] call acre_api_fnc_setRadioSpatial) then {_success = false};
    };
} forEach _radios;
private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap];
private _profiles = _config getOrDefault ['radioProfiles', []];
private _priority = _config getOrDefault ['radioPriority', []];
private _longRadios = _radios select {!([_x, 'ACRE_PRC343'] call acre_api_fnc_isKindOf)};
private _ordered = [];
{
    private _base = _x;
    if ((_profiles findIf {(_x select 0) == _base}) >= 0) then {
        {private _radioId = _x; if (([_radioId] call acre_api_fnc_getBaseRadio) == _base) then {_ordered pushBackUnique _radioId}} forEach _longRadios;
    };
} forEach _priority;
private _netCursor = 0;
{
    if (_netCursor < count _netKeys) then {
        private _radioId = _x;
        private _base = [_radioId] call acre_api_fnc_getBaseRadio;
        private _profileIndex = _profiles findIf {(_x select 0) == _base};
        private _netIndex = _nets findIf {(_x select 0) == toUpper (_netKeys select _netCursor)};
        if (_profileIndex >= 0 && {_netIndex >= 0}) then {
            private _profile = _profiles select _profileIndex;
            private _net = _nets select _netIndex;
            private _mode = _profile select 1;
            private _consumed = false;
            if (_mode == 'CHANNEL') then {
                if !([_radioId, _net select 2] call acre_api_fnc_setRadioChannel) then {_success = false};
                if (([_radioId] call acre_api_fnc_getRadioChannel) != (_net select 2)) then {_success = false};
                _consumed = true;
            };
            if (_mode == 'FREQUENCY') then {
                private _overrideIndex = (_net select 3) findIf {(_x select 0) == _base};
                if (_overrideIndex < 0) then {
                    diag_log format ['[WMP ACRE] %1 requires an explicit net override and was unchanged.', _base];
                } else {
                    diag_log format ['[WMP ACRE] %1 explicit frequency override is declared but no safe public runtime API exists; radio unchanged.', _base];
                };
            };
            if (_consumed) then {
                if !([_radioId, _profile select 2] call acre_api_fnc_setRadioSpatial) then {_success = false};
                _netCursor = _netCursor + 1;
            };
        };
    };
} forEach _ordered;
if (!_success && {_retryAllowed}) then {
    if (canSuspend) then {uiSleep 0.2};
    _success = [true, _reason, false] call Waldo_fnc_ACRE2ApplyPlayerPlan;
};
if (!_success) then {
    diag_log format ['[WMP ACRE] One or more radio writes failed during %1 after retry.', _reason];
} else {
    uiNamespace setVariable ['Waldo_ACRE2_AppliedSignature', _signature];
};
_success
