/*
 * Author: WaldoTheWarfighter
 * Completes a server-requested group migration on the machine that now owns the group. It waits for
 * Arma's asynchronous locality transfer, reapplies the active WMP AI skill profile to every local AI
 * unit, records a public adoption result for diagnostics, and only then publishes the migration
 * compatibility event used by other AI systems.
 *
 * Locality and authority:
 * The server remote-executes this function only to the expected destination owner. The function
 * rejects execution on any other machine. Work is scheduled and bounded to 15 seconds because
 * setGroupOwner can succeed on the server before the destination observes the new locality. The
 * revision prevents an older, delayed handoff from overwriting the result of a newer one. Safe to
 * repeat; the AI profile and its optional per-unit variance are idempotent across migrations.
 * JIP does not replay this transient operation; the current result is stored publicly on the group.
 *
 * Arguments:
 * 0: group <GROUP> - group whose ownership has just changed.
 * 1: previous owner <NUMBER> - network owner before migration, used for the compatibility event.
 * 2: expected owner <NUMBER> - network owner that must execute the adoption.
 * 3: migration revision <NUMBER> - server-issued sequence used to reject stale work.
 *
 * Return Value:
 * Boolean - true when the bounded adoption worker was scheduled; false when the call was invalid.
 *
 * Example:
 * [_group, 2, 5, 17] remoteExecCall ["Waldo_fnc_HeadlessAdoptGroupLocal", 5];
 * Result: owner 5 waits for locality, reapplies WMP AI and records revision 17 on the group.
 *
 * Current caller: Waldo_fnc_HeadlessMigrateGroup after every successful setGroupOwner call.
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_previousOwner", 2, [0]],
    ["_expectedOwner", 2, [0]],
    ["_revision", -1, [0]]
];
if (isNull _group || {_revision < 0} || {clientOwner != _expectedOwner}) exitWith {false};

[_group, _previousOwner, _expectedOwner, _revision] spawn {
    params ["_group", "_previousOwner", "_expectedOwner", "_revision"];
    private _deadline = diag_tickTime + 15;
    waitUntil {
        uiSleep 0.1;
        isNull _group
        || {local _group}
        || {diag_tickTime >= _deadline}
        || {!((_group getVariable ["Waldo_Headless_ExpectedAdoption", []]) isEqualTo [_revision, _expectedOwner])}
    };

    if (isNull _group) exitWith {};
    if !((_group getVariable ["Waldo_Headless_ExpectedAdoption", []]) isEqualTo [_revision, _expectedOwner]) exitWith {
        diag_log format ["[WMP HEADLESS] Ignored stale adoption group=%1 revision=%2 owner=%3.", _group, _revision, _expectedOwner];
    };
    if !(local _group) exitWith {
        _group setVariable ["Waldo_Headless_LastAdoption", [_revision, _expectedOwner, false, 0, "locality-timeout"], true];
        diag_log format ["[WMP HEADLESS] Adoption timed out group=%1 revision=%2 expectedOwner=%3 actualOwner=%4.", _group, _revision, _expectedOwner, groupOwner _group];
    };

    private _applied = 0;
    private _aiEnabled = missionNamespace getVariable ["Waldo_AIRebalance_Enable", false];
    if (_aiEnabled) then {
        if !(missionNamespace getVariable ["Waldo_AI_RebalanceActive", false]) then {
            [
                missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"],
                missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"]
            ] call Waldo_fnc_AIRebalanceInit;
        };
        {
            if (local _x && {!isPlayer _x} && {[_x] call Waldo_fnc_AIApplyProfile}) then {
                _applied = _applied + 1;
            };
        } forEach units _group;
    };

    private _profile = if (_aiEnabled) then {
        format ["%1/%2", missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"], missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"]]
    } else {
        "DISABLED"
    };
    _group setVariable ["Waldo_Headless_LastAdoption", [_revision, _expectedOwner, true, _applied, _profile], true];
    ["Waldo_Headless_GroupMigrated", [_group, _previousOwner, _expectedOwner]] call CBA_fnc_globalEvent;
    diag_log format ["[WMP HEADLESS] Adoption complete group=%1 revision=%2 owner=%3 localUnits=%4 aiApplied=%5 profile=%6.", _group, _revision, _expectedOwner, {local _x} count units _group, _applied, _profile];
};
true
