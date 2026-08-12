/*
 * Author: WaldoTheWarfighter
 * Client-side worker for Waldo_fnc_ACRE2RackApply: performs one read/write action against a vehicle
 * rack's live ACRE2 radio state on THIS machine, and reports the result back to the server if this
 * machine can actually see that state. Exists because ACRE2's per-rack radio state
 * (acre_api_fnc_getMountedRackRadio, acre_api_fnc_isRackRadioRemovable, acre_api_fnc_setRadioChannel/
 * getRadioChannel, acre_api_fnc_getCurrentRadioList) is tracked locally on whichever client ACRE2
 * itself delegated the rack's mount/init work to - it is not synced to the server. Calling these
 * functions directly from the server works only by coincidence on a listen server (where the host is
 * simultaneously the server and a client, so "local" state is shared); on a genuine dedicated server
 * it throws "[ACRE] (api) WARNING: Non existant rack ID provided" and a follow-on script error,
 * because the server's own local ACRE2 state genuinely never had that rack's data. Broadcasting this
 * action to every connected client and letting whichever one actually holds the live state succeed
 * removes the need to know in advance which client ACRE2 chose - a client with no visibility into the
 * rack ID simply throws internally (caught here) and reports nothing, so only a genuine holder of the
 * state ever answers.
 *
 * Locality and authority:
 * Runs on every connected client (remoteExec target 0 from the server); a client with no interface
 * (dedicated server's own copy, a headless client with no live ACRE2 session) exits immediately and
 * harmlessly. Every ACRE2 call is wrapped in isNil {CODE}, SQF's standard safe-eval idiom - it
 * evaluates CODE and reports true on both a nil result and a runtime error inside it, so an
 * unrecognised rack ID on this machine is treated as "this machine cannot answer" rather than crashing
 * or reporting a false result. Reports back to the server only on a successful, meaningful read/write
 * via Waldo_fnc_ACRE2RackClientActionResult; multiple clients successfully reporting the same result
 * for the same request is harmless (the server keeps the first).
 *
 * Arguments:
 * 0: RackId <STRING> - the rack ID this action targets.
 * 1: Action <STRING> - "GET_BASE" | "GET_ID" | "IS_REMOVABLE" | "SET_CHANNEL" | "SET_FREQUENCY".
 * 2: Args <ARRAY> - action-specific:
 *    GET_BASE: [] - reads the currently mounted base radio classname (possibly "" for an empty rack).
 *    GET_ID: [] - reads the mounted radio's real unique ID once ACRE2 has issued one (not just the
 *      bare base classname); reports nothing while still un-initialised, matching the server's own
 *      bounded retry loop.
 *    IS_REMOVABLE: [] - reads whether the current occupant may be replaced/removed.
 *    SET_CHANNEL: [radioId, channel] - writes and reads back a CHANNEL/BLOCK_CHANNEL-mode radio's
 *      channel; reports [written, verified].
 *    SET_FREQUENCY: [radioId, base, freqSetting] - resolves this radio's ordinal occurrence among
 *      same-base radios visible on this machine and requests the batched, unverified
 *      acre_api_fnc_setupRadios frequency write; reports the accepted/rejected boolean.
 * 3: RequestId <STRING> - correlates this action's result with the server's waiting caller.
 *
 * Return Value: Nothing - result delivery is via remoteExecCall, not a return value.
 * Example: [_rackId, "GET_ID", [], _requestId] remoteExecCall ["Waldo_fnc_ACRE2RackClientAction", 0];
 * Current caller: Waldo_fnc_ACRE2RackApply's client-query helper.
 */

params [
    ["_rackId", "", [""]],
    ["_action", "", [""]],
    ["_args", [], [[]]],
    ["_requestId", "", [""]]
];

if !(hasInterface) exitWith {};
if (_rackId == "" || {_action == ""} || {_requestId == ""}) exitWith {};

private _report = {
    params ["_value"];
    [_requestId, _value] remoteExecCall ["Waldo_fnc_ACRE2RackClientActionResult", 2];
};

switch (toUpper _action) do {
    case "GET_BASE": {
        private _base = "";
        if !(isNil {_base = [_rackId, true] call acre_api_fnc_getMountedRackRadio}) then {
            [_base] call _report;
        };
    };
    case "GET_ID": {
        private _raw = "";
        private _base = "";
        private _rawOk = !(isNil {_raw = [_rackId, false] call acre_api_fnc_getMountedRackRadio});
        private _baseOk = !(isNil {_base = [_rackId, true] call acre_api_fnc_getMountedRackRadio});
        if (_rawOk && _baseOk && {_raw != ""} && {_raw != _base}) then {
            [_raw] call _report;
        };
    };
    case "IS_REMOVABLE": {
        private _removable = false;
        if !(isNil {_removable = [_rackId] call acre_api_fnc_isRackRadioRemovable}) then {
            [_removable] call _report;
        };
    };
    case "SET_CHANNEL": {
        _args params [["_radioId", "", [""]], ["_channel", 0, [0]]];
        private _set = false;
        private _readBack = -1;
        if !(isNil {_set = [_radioId, _channel] call acre_api_fnc_setRadioChannel}) then {
            if (isNil {_readBack = [_radioId] call acre_api_fnc_getRadioChannel}) then {_readBack = -1;};
            [[_set, _readBack == _channel]] call _report;
        };
    };
    case "SET_FREQUENCY": {
        _args params [["_radioId", "", [""]], ["_base", "", [""]], ["_freqSetting", [], [[]]]];
        private _broad = [];
        if (isNil {_broad = [] call acre_api_fnc_getCurrentRadioList}) exitWith {};
        private _sameBase = _broad select {
            private _candidateBase = "";
            !(isNil {_candidateBase = [_x] call acre_api_fnc_getBaseRadio}) && {toUpper _candidateBase == toUpper _base}
        };
        private _occurrence = (_sameBase find _radioId) + 1;
        if (_occurrence <= 0 || {isNil "acre_api_fnc_setupRadios"}) exitWith {};
        private _result = false;
        if !(isNil {_result = [[_base, _occurrence, _freqSetting]] call acre_api_fnc_setupRadios}) then {
            [_result] call _report;
        };
    };
    default {};
};
