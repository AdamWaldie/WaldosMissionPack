/*
 * Author: Waldo
 * Client side of UAV/UGV jamming - and, like the radio HUD, it is deliberately loud so a jammed
 * drone is never mistaken for one of Arma's UAV bugs. While the local player is controlling a drone
 * whose datalink runs into a UAV-jamming field it: degrades the video feed with a rising screen
 * distortion as the link weakens, shows the persistent "UAV LINK JAMMED - not a game bug" HUD
 * banner, and at near-total jamming cuts the terminal link outright with a clear message. Everything
 * restores when the drone leaves the field or the player disconnects the terminal.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_JammingUavClient;
 */

if !(hasInterface) exitWith {};
if (missionNamespace getVariable ["Waldo_Jamming_UavClientRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Jamming_UavClientRunning", true];

[] spawn {
    private _pp = -1;
    private _lastUav = objNull;
    private _cutThisLink = false;

    while {true} do {
        private _uav = getConnectedUAV player;
        private _factor = 0;
        if (!isNull _uav && {alive _uav}) then {
            _factor = [getPosASL _uav, side _uav, -1, -1, true] call Waldo_fnc_JammingFactor;
        };

        // A freshly connected drone clears the one-shot "cut" latch.
        if (_uav != _lastUav) then {
            _cutThisLink = false;
            _lastUav = _uav;
        };

        private _notify = missionNamespace getVariable ["Waldo_Jamming_Notify", true];

        if (_factor > 0 && {!isNull _uav}) then {
            // Video feed degradation - chromatic tearing that gets worse as the link weakens.
            if (_pp < 0) then { _pp = ppEffectCreate ["ChromAberration", 2200]; };
            _pp ppEffectEnable true;
            _pp ppEffectAdjust [0.02 * _factor, 0.02 * _factor, true];
            _pp ppEffectCommit 0;

            if (_notify) then { [_factor, "UAV LINK JAMMED", 5311, "Drone datalink is jammed - not a game bug"] call Waldo_fnc_JammingHud; };

            // Hard jam: sever the terminal link once for this connection.
            if (_factor >= 0.95 && {!_cutThisLink}) then {
                _cutThisLink = true;
                player connectTerminalToUAV objNull;
                if (_notify) then {
                    systemChat "*** UAV DATALINK LOST - your drone is being jammed (intentional, not a bug). ***";
                    private _msg = parseText "<t color='#c8102e' size='2' shadow='1' align='center'>UAV LINK LOST</t><br /><t size='1' align='center'>Datalink jammed in this area - not a game bug</t><br />";
                    [_msg, 4] spawn Waldo_fnc_TimedHint;
                };
            };
        } else {
            // Clear effects when not connected / not jammed.
            if (_pp >= 0) then {
                _pp ppEffectEnable false;
                ppEffectDestroy _pp;
                _pp = -1;
            };
            [0, "UAV LINK JAMMED", 5311] call Waldo_fnc_JammingHud;
        };

        sleep ([1.5, 0.5] select (_factor > 0));
    };
};
