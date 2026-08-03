/*
 * Author: WaldoTheWarfighter
 * Shows a Field Resupply grant notification to the receiving player after introductory UI ends.
 *
 * The message is client-local and is delayed while the stock fake loading screen/title sequence is
 * active or expected. A bounded fallback releases it when a mission has removed or replaced that
 * sequence without publishing the normal completion flag. This prevents early grants from drawing
 * over mission presentation while ensuring custom mission flows cannot strand the notice forever.
 *
 * Arguments:
 * 0: granted crates <NUMBER>
 * 1: current crates <NUMBER>
 * 2: maximum crates <NUMBER>
 *
 * Return Value:
 * Boolean - true when the local notification was queued; false without a player interface.
 *
 * Example:
 * [2, 3, 4] remoteExecCall ["Waldo_fnc_FieldResupplyNotifyGrantLocal", owner _unit];
 *
 * Current caller: Waldo_fnc_FieldResupplyGrantCrates after a server-authorized grant.
 */

params [
    ["_granted", 0, [0]],
    ["_current", 0, [0]],
    ["_maximum", 0, [0]]
];
if !(hasInterface) exitWith {false};

[_granted, _current, _maximum, diag_tickTime] spawn {
    params ["_granted", "_current", "_maximum", "_queuedAt"];
    waitUntil {
        uiSleep 0.25;
        missionNamespace getVariable ["Waldo_InfoText_Complete", false]
        || {
            !(missionNamespace getVariable ["Waldo_InfoText_Active", false])
            && {diag_tickTime - _queuedAt >= 60}
        }
    };
    [
        "FIELD RESUPPLY",
        format [
            "%1 portable crate%2 granted. Carrying %3 of %4.",
            _granted,
            if (_granted == 1) then {""} else {"s"},
            _current,
            _maximum
        ],
        "SUCCESS",
        "FIELD_RESUPPLY_CARRIER"
    ] call Waldo_fnc_FeatureNotifyLocal;
};
true
