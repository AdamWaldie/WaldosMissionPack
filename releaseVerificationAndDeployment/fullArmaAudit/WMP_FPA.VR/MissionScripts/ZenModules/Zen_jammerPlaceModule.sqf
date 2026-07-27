/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: prompts the curator for a jammer's radius, falloff, strength, the side it
 * jams and whether to mark it, then spawns an emitter object at the module position and registers
 * it as a localised radio jammer (Waldo_fnc_Jammer). Works for ACRE2 and TFAR. The object is
 * created on the curator's machine and added to the curator so it can be moved or deleted in Zeus;
 * the jammer registry write is forwarded to the server by Waldo_fnc_Jammer.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object the module was dropped on (unused)
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenJammerPlace;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

[
    "Waldos Radio Jammer",
    [
        ["SLIDER", ["Radius (m)", "Full-strength jamming radius in metres."], [50, 2000, 300, 0], false],
        ["SLIDER", ["Falloff (m)", "Extra metres of linear falloff beyond the radius."], [0, 1000, 50, 0], false],
        ["SLIDER", ["Strength (%)", "Jamming strength at full effect (100% = total blackout)."], [0, 100, 100, 0], false],
        ["COMBO", ["Affected Side", "Which side's radios are jammed."],
            [
                ["ALL", "WEST", "EAST", "IND", "CIV"],
                ["All Sides", "BLUFOR", "OPFOR", "INDFOR", "CIVILIAN"],
                0
            ],
        false],
        ["EDIT", ["Frequency Bands", "ALL, or semicolon-separated MHz ranges such as 30-88;225-400. ACRE2 only; TFAR remains broadband."], "ALL"],
        ["CHECKBOX", ["Start Active", "Enable the emitter immediately after placement."], true, false],
        ["SLIDER", ["Cone Arc (deg)", "360 = omnidirectional; less = a directional cone facing the bearing below."], [10, 360, 360, 0], false],
        ["SLIDER", ["Cone Bearing (deg)", "Compass bearing the cone faces (ignored when arc is 360)."], [0, 359, 0, 0], false],
        ["CHECKBOX", ["Pulsing", "Jam intermittently using the on/off timing below."], false, false],
        ["SLIDER", ["Pulse On (s)", "Seconds the jammer remains active during each pulse."], [0.5, 30, 4, 1], false],
        ["SLIDER", ["Pulse Off (s)", "Seconds the jammer remains silent during each pulse."], [0.5, 30, 2, 1], false],
        ["CHECKBOX", ["Also Jam UAVs / Drones", "Freeze autonomous drones and cut controlling players' datalinks in the field."], false, false],
        ["CHECKBOX", ["Show Map Marker", "Place a persistent map marker on the jammer."], false, false],
        ["CHECKBOX", ["Show Curator 3D Marker", "Show a floating curator-only marker for this emitter. Ordinary players never see it."], false, false],
        ["EDIT", ["Emitter Class", "CfgVehicles classname spawned as the physical emitter."], "Land_PowerGenerator_F"]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_radius", "_falloff", "_strengthPct", "_sideStr", "_bandsText", "_active", "_arc", "_bearing", "_pulse", "_pulseOn", "_pulseOff", "_jamUAV", "_marker", "_show3D", "_className"];
        _pos params ["_modulePos"];

        private _sector = [];
        if (_arc < 360) then { _sector = [_bearing, _arc]; };
        private _duty = [];
        if (_pulse) then { _duty = [_pulseOn, _pulseOff]; };
        private _bands = "ALL";
        private _bandInvalid = false;
        if !(toUpper _bandsText isEqualTo "ALL") then {
            private _ranges = [];
            {
                private _parts = _x splitString "-,";
                if ((count _parts) >= 2) then {
                    private _low = parseNumber (_parts select 0);
                    private _high = parseNumber (_parts select 1);
                    if (_high > _low && {_low >= 0}) then {
                        _ranges pushBack [_low, _high];
                    } else {
                        _bandInvalid = true;
                    };
                } else {
                    _bandInvalid = true;
                };
            } forEach (_bandsText splitString ";");
            if (_ranges isEqualTo []) then {_bandInvalid = true;} else {_bands = _ranges;};
        };
        if (_bandInvalid) exitWith {
            ["JAMMER NOT PLACED", "Frequency bands must be ALL or ranges such as 30-88;225-400.", 8, "FAILURE"] call Waldo_fnc_JammingNotice;
        };
        if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {
            ["JAMMER NOT PLACED", format ["Emitter class does not exist: %1", _className], 8, "FAILURE"] call Waldo_fnc_JammingNotice;
        };

        [
            _modulePos,
            [_radius, _sideStr, _bands, _falloff, (_strengthPct / 100), _active, _marker, _sector, _duty, _jamUAV, _show3D, _className],
            player
        ] remoteExecCall ["Waldo_fnc_ZenCreateJammerServer", 2];
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
