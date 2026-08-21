/*
 * Author: WaldoTheWarfighter
 * Starts or stops speaker presentation: owner-local caller look/gesture plus client-local lip movement.
 * Locality/authority: accepts server execution only; each interface renders lips while the unit owner
 * applies AI commands. The server broadcasts this transient call without creating a JIP entry.
 * Repeat/JIP behaviour: start/stop are idempotent; no persistent remote-execution entry is created.
 * Arguments: speaker, caller, speaking BOOL, gesture STRING. Return Value: BOOL.
 * Current callers: simple and advanced server workers. Example: server remote execution to owner speaker.
 */
params [["_speaker", objNull, [objNull]], ["_caller", objNull, [objNull]], ["_speaking", false, [true]], ["_gesture", "", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (isNull _speaker || {!hasInterface && {!local _speaker}}) exitWith {false};
if (_speaking) then {
    if (local _speaker) then {
        if (!isNull _caller) then {
            _speaker lookAt _caller;
            _speaker setVariable ["Waldo_Dialogue_LookTargetNetId", netId _caller];
            _speaker setVariable ["Waldo_Dialogue_PresentationOwner", owner _speaker];
            diag_log format ["[WMP DIALOGUE] Owner-local lookAt applied speaker=%1 target=%2 objectOwner=%3 executingClientOwner=%4.", netId _speaker, netId _caller, owner _speaker, clientOwner];
        };
        if (_gesture != "") then {_speaker playActionNow _gesture};
    };
    if (hasInterface) then {
        missionNamespace setVariable ["Waldo_Dialogue_LastLookRequestLocal", [netId _speaker, netId _caller, true]];
        _speaker enableMimics true;
        _speaker setRandomLip true;
        _speaker setVariable ["Waldo_Dialogue_RandomLipActiveLocal", true];
    };
} else {
    if (hasInterface) then {
        missionNamespace setVariable ["Waldo_Dialogue_LastLookRequestLocal", [netId _speaker, netId _caller, false]];
        _speaker setRandomLip false;
        _speaker setVariable ["Waldo_Dialogue_RandomLipActiveLocal", false];
    };
    if (local _speaker) then {
        _speaker lookAt objNull;
        _speaker setVariable ["Waldo_Dialogue_LookTargetNetId", ""];
        _speaker setVariable ["Waldo_Dialogue_PresentationOwner", -1];
        diag_log format ["[WMP DIALOGUE] Owner-local lookAt cleared speaker=%1 objectOwner=%2 executingClientOwner=%3.", netId _speaker, owner _speaker, clientOwner];
    };
};
true
