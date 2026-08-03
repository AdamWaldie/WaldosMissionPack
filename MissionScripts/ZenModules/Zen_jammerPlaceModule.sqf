/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: prompts the curator for a jammer's radius, falloff, strength, the side it
 * jams, whether it has an operator toggle, and whether hostile field disablement requires a
 * shared interaction procedure. It then spawns an emitter object at the module position and registers
 * it as a localised radio jammer (Waldo_fnc_Jammer). Works for ACRE2 and TFAR. The object is
 * created server-side, explicitly simulation-enabled, and transferred to the requesting curator
 * so it can be moved or deleted smoothly; alternatively, an existing object directly under the
 * module becomes the emitter without changing its simulation state. The jammer registry follows
 * the live object transform in either case.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object the module was dropped on (unused)
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised creation request to the server.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenJammerPlace;
 *
 * Current caller: the ZEN "Create Radio Jammer" module registered by Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

private _emitterClasses = ["Land_PowerGenerator_F", "Land_PortableGenerator_01_F", "Land_DataTerminal_01_F", "Land_TTowerSmall_1_F"];
_emitterClasses = _emitterClasses select {isClass (configFile >> "CfgVehicles" >> _x)};
if (_emitterClasses isEqualTo []) exitWith {
    ["JAMMER NOT PLACED", "No supported jammer emitter objects are available in the current modset.", 8, "FAILURE"] call Waldo_fnc_JammingNotice;
};
private _emitterLabels = _emitterClasses apply {
    private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
    if (_name == "") then {_x} else {format ["%1 (%2)", _name, _x]}
};
private _sourceValues = ["SPAWN"];
private _sourceLabels = [["Spawn object", "Create the selected emitter at the module position."]];
if (!isNull _objectPos) then {
    _sourceValues insert [0, ["EXISTING"]];
    _sourceLabels insert [0, [[
        "Use object under module",
        format ["Use %1 (%2) without replacing it.", getText (configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "displayName"), typeOf _objectPos]
    ]]];
};

[
    "Waldos Radio Jammer",
    [
        ["SLIDER", ["Radius (m)", "Full-strength jamming radius in metres."], [50, 2000, 300, 0], false],
        ["SLIDER", ["Falloff (m)", "Extra metres of linear falloff beyond the radius."], [0, 1000, 50, 0], false],
        ["SLIDER", ["Strength (%)", "Jamming strength at full effect (100% = total blackout)."], [0, 100, 100, 0], false],
        ["TOOLBOX:WIDE", ["Affected Side", "Which side's radios are jammed."], [0, 1, 5, ["All", "BLUFOR", "OPFOR", "INDFOR", "Civilian"]]],
        ["TOOLBOX:WIDE", ["ACRE frequency coverage", "TFAR is always broadband. Choose a common ACRE operating range."], [0, 2, 2, [
            ["All frequencies", "Jam every supported ACRE frequency."],
            ["VHF combat", "Jam 30-88 MHz."],
            ["UHF air", "Jam 225-400 MHz."],
            ["VHF + UHF", "Jam both 30-88 MHz and 225-400 MHz."]
        ]]],
        ["CHECKBOX", ["Start Active", "Enable the emitter immediately after placement."], true, false],
        ["SLIDER", ["Cone Arc (deg)", "360 = omnidirectional; less = a directional cone facing the bearing below."], [10, 360, 360, 0], false],
        ["SLIDER", ["Cone Bearing (deg)", "Compass bearing the cone faces (ignored when arc is 360)."], [0, 359, 0, 0], false],
        ["CHECKBOX", ["Pulsing", "Jam intermittently using the on/off timing below."], false, false],
        ["SLIDER", ["Pulse On (s)", "Seconds the jammer remains active during each pulse."], [0.5, 30, 4, 1], false],
        ["SLIDER", ["Pulse Off (s)", "Seconds the jammer remains silent during each pulse."], [0.5, 30, 2, 1], false],
        ["CHECKBOX", ["Also Jam UAVs / Drones", "Freeze autonomous drones and cut controlling players' datalinks in the field."], false, false],
        ["CHECKBOX", ["Show Map Marker", "Place a persistent map marker on the jammer."], false, false],
        ["CHECKBOX", ["Show Curator 3D Marker", "Show a floating curator-only marker for this emitter. Ordinary players never see it."], false, false],
        ["TOOLBOX:WIDE", ["Emitter source", "Use the object directly under the module, when available, or spawn a new emitter."], [0, 1, count _sourceLabels, _sourceLabels]],
        ["LIST", ["Spawned emitter object", "Exact physical class created when Emitter source is Spawn."], [_emitterClasses, _emitterLabels, 0, 4]],
        ["CHECKBOX", ["Allow Reactivation", "Add Activate Jammer while the field is off. Turning it off still requires Disable Jammer, so this cannot bypass the procedure below."], true, false],
        ["CHECKBOX", ["Require Field Disable Procedure", "Replace instant hostile field disablement with a shared interaction challenge."], true, false],
        ["TOOLBOX:WIDE", ["Disable Procedure", "Procedure players complete to shut down the jammer."], [0, 2, 2, ["Circuit bypass", "Signal alignment", "Command authentication", "Control-wire isolation"]]],
        ["TOOLBOX:WIDE", ["Procedure Difficulty", "Shared interaction difficulty profile."], [1, 1, 4, ["Easy", "Standard", "Hard", "Expert"]]],
        ["CHECKBOX", ["Engineer only", "Hide the field-disable action from non-engineers. Disabled by default so public Zeus players can use the objective."], false],
        ["TOOLBOX:WIDE", ["Successful disable result", "Disable keeps the prop and turns the field off; destroy removes it."], [0, 1, 2, ["Disable field", "Destroy emitter"]]]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_radius", "_falloff", "_strengthPct", "_sideIndex", "_bandIndex", "_active", "_arc", "_bearing", "_pulse", "_pulseOn", "_pulseOff", "_jamUAV", "_marker", "_show3D", "_sourceIndex", "_className", "_allowPlayerToggle", "_disableChallenge", "_challengeIndex", "_difficultyIndex", "_engineerOnly", "_resultIndex"];
        _pos params ["_modulePos", "_objectPos", "_sourceValues"];
        private _sideStr = ["ALL", "WEST", "EAST", "IND", "CIV"] param [_sideIndex, "ALL"];
        private _bandsText = ["ALL", "30-88", "225-400", "30-88;225-400"] param [_bandIndex, "ALL"];
        private _source = _sourceValues param [_sourceIndex, "SPAWN"];
        private _challengeId = ["circuit", "radiotune", "commandinput", "wirecut"] param [_challengeIndex, "circuit"];
        private _difficulty = ["easy", "standard", "hard", "expert"] param [_difficultyIndex, "standard"];
        private _resultMode = ["DISABLE", "DESTROY"] param [_resultIndex, "DISABLE"];
        private _existingObject = if (_source isEqualTo "EXISTING") then {_objectPos} else {objNull};
        if (_source isEqualTo "EXISTING" && {isNull _existingObject}) exitWith {
            ["JAMMER NOT PLACED", "The object under the module is no longer available.", 8, "FAILURE"] call Waldo_fnc_JammingNotice;
        };

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
        if (_source isEqualTo "SPAWN" && {!(isClass (configFile >> "CfgVehicles" >> _className))}) exitWith {
            ["JAMMER NOT PLACED", format ["Emitter class does not exist: %1", _className], 8, "FAILURE"] call Waldo_fnc_JammingNotice;
        };

        diag_log format ["[WMP ZEN] jammer dialog confirmed source=%1 requestedClass=%2 existing=%3", _source, _className, if (isNull _existingObject) then {"<none>"} else {format ["%1/%2", netId _existingObject, typeOf _existingObject]}];

        [
            _modulePos,
            [
                ["radius", _radius], ["side", _sideStr], ["bands", _bands],
                ["falloff", _falloff], ["strength", (_strengthPct / 100)], ["active", _active],
                ["marker", _marker], ["sector", _sector], ["duty", _duty],
                ["jamUAV", _jamUAV], ["show3D", _show3D], ["className", _className],
                ["disableChallenge", _disableChallenge], ["challengeId", _challengeId],
                ["difficulty", _difficulty], ["engineerOnly", _engineerOnly],
                ["resultMode", _resultMode], ["allowPlayerToggle", _allowPlayerToggle]
            ],
            player,
            _existingObject
        ] remoteExecCall ["Waldo_fnc_ZenCreateJammerServer", 2];
    },
    {},
    [_modulePos, _objectPos, _sourceValues]
] call zen_dialog_fnc_create;
