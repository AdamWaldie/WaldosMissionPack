/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: prompts the curator for a go-live countdown length in seconds and
 * starts the Safestart auto-lift timer on the server. The countdown shows on every
 * player's safestart banner and auto goes-live at zero; the curator can still overrule it
 * early with the "SafeStart: Go Live Now" module. Because the timer activates SafeStart when it
 * is currently inactive, it also works with the pack's default live starting state.
 * Locality and authority: Opens on the curator interface; the server starts the authoritative
 * SafeStart countdown after the curator submits seconds.
 * Repeat/JIP: Opening the dialog changes nothing. A submitted timer replaces current countdown
 * state, which the SafeStart service publishes for joining players.
 *
 * Arguments:
 * None
 *
 * Example:
 * [] call Waldo_fnc_ZenSafeStartTimer;
 * Return Value: Nothing useful; the dialog opens and submits asynchronously.
 * Result: Players see the chosen go-live countdown after server acceptance.
 *
 * Public: No
 * Current caller: "SafeStart: Start Go-Live Timer" in Waldo_fnc_ZenInitModules.
 */

if !(isClass(configFile >> "CfgPatches" >> "zen_main")) exitWith {};

[
    "Safestart Go-Live Countdown",
    [
        ["SLIDER", ["Seconds", "Seconds until Safestart automatically lifts. The player display uses MM:SS."], [5, 3600, 300, 0], false]
    ],
    {
        params ["_args"];
        _args params ["_seconds"];
        _seconds = round _seconds;
        [_seconds] remoteExec ["Waldo_fnc_SafeStartTimer", 2];
    }
] call zen_dialog_fnc_create;
