/*
 * Author: Waldo
 * Opens an accepted interaction procedure only on its owning player's client and reports typed
 * outcome metadata to the authoritative server resolver.
 */

params [
    ["_object", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_attemptId", "", [""]]
];

if (!hasInterface || {isNull _object} || {isNull _actor} || {_attemptId == ""}) exitWith {};
if (remoteExecutedOwner != 2) exitWith {};
if (!local _actor || {_actor isNotEqualTo player}) exitWith {};

private _challengeId = _object getVariable ["Waldo_MG_Int_ChallengeId", "wirecut"];
private _config = _object getVariable ["Waldo_MG_Int_Config", []];
private _presentation = _object getVariable ["Waldo_IMG_Presentation", []];
private _resolvedVar = format ["Waldo_MG_Int_LocalResolved_%1", _attemptId];
missionNamespace setVariable [_resolvedVar, false];

private _onSuccess = {
    params ["_actor", "_cid", "_ctx", ["_detail", ["SUCCESS", ""]]];
    if (_cid == "") exitWith {};
    _ctx params ["_object", "_attemptId", "_resolvedVar"];
    missionNamespace setVariable [_resolvedVar, true];
    [_object, _actor, true, _attemptId, _detail param [0, "SUCCESS"], _detail param [1, ""]]
        remoteExecCall ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
};
private _onFailure = {
    params ["_actor", "_cid", "_ctx", ["_detail", ["FAILURE", ""]]];
    if (_cid == "") exitWith {};
    _ctx params ["_object", "_attemptId", "_resolvedVar"];
    missionNamespace setVariable [_resolvedVar, true];
    [_object, _actor, false, _attemptId, _detail param [0, "FAILURE"], _detail param [1, ""]]
        remoteExecCall ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
};

private _opened = [_challengeId, _config, _onSuccess, _onFailure, _actor, [_object, _attemptId, _resolvedVar], _presentation]
    call Waldo_fnc_MiniGameChallenge;
private _attemptDisplay = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
if (!_opened) then {
    if !(missionNamespace getVariable [_resolvedVar, false]) then {
        missionNamespace setVariable [_resolvedVar, true];
        [_object, _actor, false, _attemptId, "ABANDONED", "PROCEDURE DISPLAY DID NOT OPEN"]
            remoteExecCall ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
    };
};

[_object, _actor, _attemptId, _resolvedVar, _attemptDisplay] spawn {
    params ["_object", "_actor", "_attemptId", "_resolvedVar", "_attemptDisplay"];
    uiSleep 0.25;
    private _watchStarted = diag_tickTime;
    private _watching = true;
    while {_watching} do {
        if (missionNamespace getVariable [_resolvedVar, false]) exitWith {_watching = false;};
        if (isNull _object) exitWith {_watching = false;};
        // Allow public object state to arrive independently of the owner-targeted start RPC.
        if ((diag_tickTime - _watchStarted) > 3) then {
            private _stateResult = _object getVariable ["Waldo_MG_InteractionResult", []];
            if ((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) != "RUNNING" || {(_stateResult param [5, ""]) != _attemptId}) exitWith {
                missionNamespace setVariable [_resolvedVar, true];
                if (!isNull _attemptDisplay && {(uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull]) isEqualTo _attemptDisplay}) then {
                    _attemptDisplay closeDisplay 1;
                };
                _watching = false;
            };
        };
        if (isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])) exitWith {
            uiSleep 0.15;
            if !(missionNamespace getVariable [_resolvedVar, false]) then {
                missionNamespace setVariable [_resolvedVar, true];
                [_object, _actor, false, _attemptId, "ABANDONED", "PROCEDURE DISPLAY CLOSED"]
                    remoteExecCall ["Waldo_fnc_MiniGameInteractionResolveServer", 2];
            };
            _watching = false;
        };
        uiSleep 0.1;
    };
    missionNamespace setVariable [_resolvedVar, nil];
};
