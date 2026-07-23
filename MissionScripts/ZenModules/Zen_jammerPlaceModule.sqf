/*
 * Author: Waldo
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
        ["SLIDER", ["Cone Arc (deg)", "360 = omnidirectional; less = a directional cone facing the bearing below."], [10, 360, 360, 0], false],
        ["SLIDER", ["Cone Bearing (deg)", "Compass bearing the cone faces (ignored when arc is 360)."], [0, 359, 0, 0], false],
        ["CHECKBOX", ["Pulsing (4s on / 2s off)", "Jam intermittently instead of constantly."], false, false],
        ["CHECKBOX", ["Show Map Marker", "Place a map marker on the jammer (visible to curators)."], false, false]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_radius", "_falloff", "_strengthPct", "_sideStr", "_arc", "_bearing", "_pulse", "_marker"];
        _pos params ["_modulePos"];

        private _sector = [];
        if (_arc < 360) then { _sector = [_bearing, _arc]; };
        private _duty = [];
        if (_pulse) then { _duty = [4, 2]; };

        private _obj = "Land_PowerGenerator_F" createVehicle _modulePos;
        [_obj, _radius, _sideStr, "ALL", _falloff, (_strengthPct / 100), true, _marker, _sector, _duty] call Waldo_fnc_Jammer;

        // Add the emitter to the curator so it can be managed in Zeus.
        [{
            _this call ace_zeus_fnc_addObjectToCurator;
        }, _obj] call CBA_fnc_execNextFrame;

        systemChat format ["Radio jammer placed: %1 m radius, jams %2.", _radius, _sideStr];
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
