/*
 * Author: WaldoTheWarfighter
 * Releases local gunship remote control and restores the player's camera.
 * Locality and authority: Runs on the assigned player's interface client after server cleanup
 * or a local exit action; it changes only that player's remote control and camera.
 * Repeat/JIP: Calling again after release is harmless. Camera control is not a JIP replay.
 * Arguments: 0: id <STRING>
 * Return Value: Boolean
 * Current callers: GunshipDestroy and controller release paths in GunshipServerHandle.
 * Example: ["SPECTRE_1"] call Waldo_fnc_GunshipReleaseControlLocal;
 * Result: The player returns to their own unit and the normal internal camera.
 */

params [["_id", "", [""]]];
if !(hasInterface) exitWith {false};
if (_id == "" || {missionNamespace getVariable ["Waldo_Gunship_ControlledId", ""] == _id}) then {
    player remoteControl objNull;
    player switchCamera "INTERNAL";
    missionNamespace setVariable ["Waldo_Gunship_ControlledId", ""];
};
true
