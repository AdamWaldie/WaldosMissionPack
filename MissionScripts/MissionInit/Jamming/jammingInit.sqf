/*
 * Author: Waldo
 * Client bootstrap for the localised radio jamming system. Installs whichever radio engine is
 * present (the ACRE2 custom signal function and/or the TFAR throttle loop) and starts a small
 * on-screen watcher that tells the player when they enter or leave a jamming field. Runs on every
 * client including JIP (it is called from init.sqf), and does nothing on a dedicated server since
 * both engines are client-local and the jammer registry itself is owned/broadcast by the server
 * through the create/toggle/remove functions. Idempotent - safe to call more than once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_JammingInit;   // called from init.sqf when Waldo_Jamming_Enable is true
 */

if !(hasInterface) exitWith {};

// Install the radio engines (each self-guards on its mod being present).
[] call Waldo_fnc_JammingAcreSignal;
[] call Waldo_fnc_JammingTfarLoop;

// Player feedback watcher - one instance per client.
if (missionNamespace getVariable ["Waldo_Jamming_UiRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Jamming_UiRunning", true];

[] spawn {
    private _prev = false;
    while {true} do {
        private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
        private _jammed = false;
        if !(_registry isEqualTo []) then {
            if (alive player) then {
                _jammed = ([getPosASL player, side player, -1] call Waldo_fnc_JammingFactor) > 0;
            };
        };

        if (missionNamespace getVariable ["Waldo_Jamming_Notify", true]) then {
            if (_jammed && {!_prev}) then {
                systemChat "RADIO JAMMING DETECTED - communications degraded in this area.";
                private _msg = parseText "<t color='#c8102e' size='1.4' shadow='1' align='center'>RADIO JAMMED</t><br /><t size='0.9' align='center'>Comms degraded in this area</t><br />";
                [_msg, 3] spawn Waldo_fnc_TimedHint;
            };
            if (!_jammed && {_prev}) then {
                systemChat "Radio jamming cleared - communications restored.";
            };
        };

        _prev = _jammed;
        sleep 2;
    };
};
