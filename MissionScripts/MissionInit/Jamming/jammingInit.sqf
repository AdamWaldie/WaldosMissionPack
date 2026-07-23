/*
 * Author: Waldo
 * Client bootstrap for the localised radio jamming system. Installs whichever radio engine is
 * present (the ACRE2 custom signal function and/or the TFAR throttle loop), starts a graduated
 * on-screen jamming meter, registers the handheld RDF "Scan for Radio Jammers" ACE self-action,
 * and starts the game-master Draw3D overlay. Runs on every client including JIP (called from
 * init.sqf) and does nothing on a dedicated server, since the engines are client-local and the
 * jammer registry is owned/broadcast by the server. Idempotent - safe to call more than once.
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

// Game-master 3D overlay (curators only).
[] call Waldo_fnc_JammerMapDraw;

// Handheld RDF detector as an ACE self-interaction.
if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    if !(missionNamespace getVariable ["Waldo_Jamming_ScanActionAdded", false]) then {
        missionNamespace setVariable ["Waldo_Jamming_ScanActionAdded", true];
        private _scan = [
            "Waldo_Jammer_Scan",
            "Scan for Radio Jammers",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\radio_ca.paa",
            { [] call Waldo_fnc_JammerScan; },
            { (count (missionNamespace getVariable ["Waldo_Jamming_Registry", []])) > 0 }
        ] call ace_interact_menu_fnc_createAction;
        [player, 1, ["ACE_SelfActions"], _scan] call ace_interact_menu_fnc_addActionToObject;
    };
};

// Player feedback watcher - one instance per client. Uses the persistent HUD (Waldo_fnc_JammingHud)
// plus enter/leave banners and a periodic chat reminder, so a jam is never confused with a game bug.
if (missionNamespace getVariable ["Waldo_Jamming_UiRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Jamming_UiRunning", true];

[] spawn {
    private _prev = false;
    private _lastChat = -999;
    while {true} do {
        private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
        private _factor = 0;
        if !(_registry isEqualTo []) then {
            if (alive player) then {
                _factor = [getPosASL player, side player, -1] call Waldo_fnc_JammingFactor;
            };
        };
        private _jammed = _factor > 0;
        private _notify = missionNamespace getVariable ["Waldo_Jamming_Notify", true];

        if (_notify) then {
            // Persistent, un-clobberable HUD banner (hidden when _factor is 0).
            [_factor] call Waldo_fnc_JammingHud;

            if (_jammed) then {
                // Loud, explicit entry banner the first time.
                if (!_prev) then {
                    systemChat "*** RADIO JAMMING ACTIVE - your comms are being jammed (this is intentional, not a bug). ***";
                    private _in = parseText "<t color='#c8102e' size='2' shadow='1' align='center'>RADIO JAMMED</t><br /><t size='1' align='center'>Comms in this area are being jammed - not a game bug</t><br />";
                    [_in, 4] spawn Waldo_fnc_TimedHint;
                    _lastChat = time;
                };
                // Periodic reminder so a long jam keeps signalling in the chat log too.
                if (time - _lastChat >= 8) then {
                    systemChat format ["~~ RADIO JAMMED (%1%2 strength) - transmissions unreliable here. ~~", round (_factor * 100), "%"];
                    _lastChat = time;
                };
            } else {
                if (_prev) then {
                    systemChat "RADIO JAMMING CLEARED - communications restored.";
                    private _out = parseText "<t color='#3a9c3a' size='1.8' shadow='1' align='center'>COMMS RESTORED</t><br />";
                    [_out, 3] spawn Waldo_fnc_TimedHint;
                };
            };
        } else {
            // Notifications off: still make sure the HUD is not left showing.
            [0] call Waldo_fnc_JammingHud;
        };

        _prev = _jammed;
        // Tighter tick while jammed so the meter blinks and tracks movement smoothly.
        sleep ([2, 0.5] select _jammed);
    };
};
