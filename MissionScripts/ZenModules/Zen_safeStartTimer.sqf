/*
 * Author: Waldo
 * Zeus module handler: prompts the curator for a go-live countdown length (minutes) and
 * starts the Safestart auto-lift timer on the server. The countdown shows on every
 * player's safestart banner and auto goes-live at zero; the curator can still overrule it
 * early with the "Safestart - Go Live (Lift)" module.
 *
 * Arguments:
 * None
 *
 * Example:
 * [] call Waldo_fnc_ZenSafeStartTimer;
 *
 * Public: No
 */

if !(isClass(configFile >> "CfgPatches" >> "zen_main")) exitWith {};

[
    "Safestart Go-Live Countdown",
    [
        // Minutes until automatic go-live.
        ["SLIDER", ["Minutes", "Time until safestart automatically lifts."], [1, 60, 5, 0], false]
    ],
    {
        params ["_args"];
        _args params ["_minutes"];
        private _seconds = round (_minutes * 60);
        [_seconds] remoteExec ["Waldo_fnc_SafeStartTimer", 2];
    }
] call zen_dialog_fnc_create;
