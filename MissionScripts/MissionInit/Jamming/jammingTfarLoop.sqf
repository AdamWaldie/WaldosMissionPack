/*
 * Author: Waldo
 * Installs the TFAR side of the jamming system. TFAR has no signal hook like ACRE2, but it does
 * expose client-side unit variables that scale how far a player can receive/transmit and whether
 * they can use a radio at all. This runs a lightweight per-client loop that checks the local
 * player against the jammer registry and, when they are inside an active field affecting their
 * side, throttles their TFAR reception and transmission (and fully cuts the radio at near-total
 * jamming). It restores the variables to normal when the player leaves the field. TFAR jamming is
 * always broadband - the per-band filter is an ACRE2-only feature.
 *
 * Client-local. Works for Task Force Radio (legacy) and TFAR (task_force_radio / tfar_core).
 * The loop uses the current player each tick, so it survives respawns automatically.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_JammingTfarLoop;
 */

if !(hasInterface) exitWith {};

private _tfar = isClass (configFile >> "CfgPatches" >> "task_force_radio")
    || {isClass (configFile >> "CfgPatches" >> "tfar_core")};
if !(_tfar) exitWith {};

if (missionNamespace getVariable ["Waldo_Jamming_TfarRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Jamming_TfarRunning", true];

[] spawn {
    private _wasJammed = false;
    while {true} do {
        private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
        private _jam = 0;
        if !(_registry isEqualTo []) then {
            if (alive player) then {
                // Broadband (frequency -1): TFAR does not expose per-link frequency here.
                _jam = [getPosASL player, side player, -1] call Waldo_fnc_JammingFactor;
            };
        };

        if (_jam > 0) then {
            private _mult = (1 - _jam) max 0;
            player setVariable ["tf_receivingDistanceMultiplicator", _mult];
            player setVariable ["tf_sendingDistanceMultiplicator", _mult];
            player setVariable ["tf_unable_to_use_radio", (_jam >= 0.99)];
            _wasJammed = true;
        } else {
            // Only restore what we changed, and only once on leaving the field.
            if (_wasJammed) then {
                player setVariable ["tf_receivingDistanceMultiplicator", 1];
                player setVariable ["tf_sendingDistanceMultiplicator", 1];
                player setVariable ["tf_unable_to_use_radio", false];
                _wasJammed = false;
            };
        };

        sleep 1.5;
    };
};

diag_log "[WMP JAM] TFAR jamming loop started.";
