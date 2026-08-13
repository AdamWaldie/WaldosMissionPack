/*
 * Author: WaldoTheWarfighter
 * Shows an airborne-gunship status message through the shared WMP notification presentation.
 * Startup messages wait for the fake loading/title sequence to finish so controller assignment
 * cannot draw over mission presentation. The wait is client-local, repeat-safe and bounded; it
 * does not delay server gunship state or JIP publication.
 *
 * Locality and authority:
 * Runs only on the receiving interface client. The server decides who receives the message.
 *
 * Arguments:
 * 0: message <STRING> - player-facing gunship status text.
 *
 * Return Value:
 * Boolean - true when displayed or queued; false without a player interface.
 *
 * Current callers:
 * Waldo_fnc_GunshipServerHandle, Waldo_fnc_GunshipSetState and local gunship controls.
 *
 * Example:
 * ["SPECTRE is on station."] call Waldo_fnc_GunshipNotifyLocal;
 */

params [["_message", "", [""]]];
if !(hasInterface) exitWith {false};

if !(missionNamespace getVariable ["Waldo_InfoText_Complete", false]) exitWith {
    [_message, diag_tickTime] spawn {
        params ["_message", "_queuedAt"];
        waitUntil {
            uiSleep 0.25;
            missionNamespace getVariable ["Waldo_InfoText_Complete", false]
            || {
                !(missionNamespace getVariable ["Waldo_InfoText_Active", false])
                && {diag_tickTime - _queuedAt >= 60}
            }
        };
        ["AIRBORNE GUNSHIP", _message, "INFO", "AIRBORNE_GUNSHIP"] call Waldo_fnc_FeatureNotifyLocal;
    };
    true
};

["AIRBORNE GUNSHIP", _message, "INFO", "AIRBORNE_GUNSHIP"] call Waldo_fnc_FeatureNotifyLocal
