/*
 * Author: WaldoTheWarfighter
 * Purpose: Executes one approved base service on the requesting player's machine.
 * Locality / Authority: Player owner only; accepts a server-dispatched request.
 * Repeat / JIP: Stateless, repeatable actions; no ongoing state except each service's own system.
 * Arguments: player <OBJECT>, service <STRING>. Return Value: <BOOL> executed.
 * Current caller: Waldo_fnc_BaseServicesUseServer.
 * Example: [player, "SAVE"] remoteExecCall ["Waldo_fnc_BaseServicesUseLocal", player];
 * Result: The player's client performs the approved save, heal or spectator service.
 */
params [["_unit", objNull, [objNull]], ["_service", "", [""]]];
if (!hasInterface || {!local _unit} || {_unit isNotEqualTo player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
switch (_service) do {
    case "SAVE": {[] call Waldo_fnc_SaveLoadout; true};
    case "HEAL": {
        if (isNil "ace_medical_treatment_fnc_fullHeal") exitWith {false};
        [_unit, _unit] call ace_medical_treatment_fnc_fullHeal;
        ["BASE SERVICES", "Full heal complete.", "SUCCESS", 6, "BOTTOM_RIGHT", "BASE_HEAL"]
            call Waldo_fnc_ShowUiNotification;
        true
    };
    case "SPECTATE": {
        if (isNil "ace_spectator_fnc_setSpectator") exitWith {false};
        [true, false, false] call ace_spectator_fnc_setSpectator;
        true
    };
    default {false};
}
