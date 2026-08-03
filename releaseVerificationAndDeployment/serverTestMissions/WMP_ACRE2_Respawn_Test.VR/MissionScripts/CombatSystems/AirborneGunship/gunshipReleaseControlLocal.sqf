/*
 * Author: WaldoTheWarfighter
 * Releases local gunship remote control and restores the player's camera.
 * Arguments: 0: id <STRING>
 * Return Value: Boolean
 */

params [["_id", "", [""]]];
if !(hasInterface) exitWith {false};
if (_id == "" || {missionNamespace getVariable ["Waldo_Gunship_ControlledId", ""] == _id}) then {
    player remoteControl objNull;
    player switchCamera "INTERNAL";
    missionNamespace setVariable ["Waldo_Gunship_ControlledId", ""];
};
true
