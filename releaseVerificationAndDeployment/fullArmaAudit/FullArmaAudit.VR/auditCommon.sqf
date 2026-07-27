Waldo_QA_fnc_emit = {
    params ["_kind", "_caseId", ["_detail", ""]];
    private _payload = str [_kind, _caseId, _detail, diag_tickTime, clientOwner, isServer, hasInterface];
    diag_log format ["WMP PR AUDIT %1: %2", _kind, _payload];
};

Waldo_QA_fnc_assert = {
    params ["_caseId", "_condition", ["_detail", ""]];
    private _kind = if (_condition) then {"PASS"} else {"FAIL"};
    [_kind, _caseId, _detail] call Waldo_QA_fnc_emit;
    private _results = +(missionNamespace getVariable ["Waldo_QA_LocalResults", []]);
    _results pushBack [_caseId, _condition, _detail];
    missionNamespace setVariable ["Waldo_QA_LocalResults", _results];
    _condition
};

Waldo_QA_fnc_case = {
    params ["_caseId", "_code"];
    ["CASE", _caseId, "BEGIN"] call Waldo_QA_fnc_emit;
    private _before = count (missionNamespace getVariable ["Waldo_QA_LocalResults", []]);
    call _code;
    private _afterResults = missionNamespace getVariable ["Waldo_QA_LocalResults", []];
    if (count _afterResults == _before) then {[_caseId, false, "CASE PRODUCED NO ASSERTION"] call Waldo_QA_fnc_assert;};
    ["CASE", _caseId, "END"] call Waldo_QA_fnc_emit;
};

Waldo_QA_fnc_complete = {
    private _results = missionNamespace getVariable ["Waldo_QA_LocalResults", []];
    private _failed = _results select {!(_x select 1)};
    ["COMPLETE", missionNamespace getVariable ["Waldo_QA_Suite", "all"], [count _results, count _failed, _failed]] call Waldo_QA_fnc_emit;
    count _failed == 0
};
