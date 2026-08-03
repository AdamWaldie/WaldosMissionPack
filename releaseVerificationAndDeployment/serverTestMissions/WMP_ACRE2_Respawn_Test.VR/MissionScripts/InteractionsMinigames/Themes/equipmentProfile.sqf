/*
 * Author: WaldoTheWarfighter
 * Returns a validated, accessible equipment presentation profile for a challenge id. Challenge
 * identity supplies labels and procedure content; the global WMP UI theme supplies era styling.
 * Curated skins remain valid content overrides before the global shell style and accessibility
 * contrast pass are applied.
 *
 * Arguments:
 * 0: challenge id <STRING>
 * 1: presentation overrides <ARRAY or HASHMAP> (default [])
 *
 * Return Value: HASHMAP - complete equipment and visual profile.
 *
 * Example: ["repair", [["preset", "fieldGenerator"]]] call Waldo_fnc_MiniGameEquipmentProfile;
 * Current callers: interaction challenge launcher, picker, briefing and QA mission.
 */
params [
    ["_challengeId", "wirecut", [""]],
    ["_overrides", [], [[], createHashMap]]
];

private _profiles = [
    ["wirecut", "eodController", "EOD SYSTEMS GROUP", "EOD-7 FIELD CONTROLLER", "RUGGED EOD CONTROLLER", "Isolate the armed circuit and sever only the identified lead.", "ARM PROBE", [0.76, 0.55, 0.16, 1], [0.16, 0.17, 0.14, 1]],
    ["minesweeper", "ordnanceTablet", "ORDNANCE DIAGNOSTICS", "MX-12 TRIGGER ANALYSER", "EXPLOSIVE CIRCUIT MATRIX", "Probe the matrix and mark every suspected trigger without energising one.", "BEGIN SCAN", [0.32, 0.68, 0.72, 1], [0.12, 0.15, 0.14, 1]],
    ["keypad", "accessTerminal", "SECURE ACCESS SYSTEMS", "IX-4 INDUSTRIAL TERMINAL", "INDUSTRIAL ACCESS TERMINAL", "Authenticate the access code before the controller locks out.", "ENABLE TERMINAL", [0.42, 0.72, 0.48, 1], [0.13, 0.15, 0.16, 1]],
    ["lockpick", "cutawayCylinder", "MECHANICAL SECURITY LAB", "CYLINDER TYPE 6", "CUTAWAY LOCK CYLINDER", "Set each binding pin at the shear line while maintaining tension.", "APPLY TENSION", [0.74, 0.62, 0.32, 1], [0.18, 0.16, 0.13, 1]],
    ["circuit", "generatorBreaker", "NATO FIELD POWER SYSTEMS", "AUX BUS CONTROL UNIT", "BREAKER AND RELAY CABINET", "Route every isolated breaker to its matching distribution bus.", "ENABLE BUS", [0.88, 0.60, 0.16, 1], [0.15, 0.16, 0.16, 1]],
    ["repair", "maintenanceHatch", "FIELD MAINTENANCE DIVISION", "SERVICE HATCH M4", "OPEN MAINTENANCE HATCH", "Torque every fastener to specification without stripping the assembly.", "BEGIN SERVICE", [0.82, 0.56, 0.18, 1], [0.18, 0.18, 0.16, 1]],
    ["radiotune", "natoReceiver", "NATO SIGNAL CORPS", "AN/PRC CALIBRATION UNIT", "TACTICAL COMMUNICATIONS UNIT", "Acquire and hold each assigned carrier frequency until channel lock.", "OPEN CHANNEL", [0.34, 0.72, 0.48, 1], [0.12, 0.16, 0.13, 1]],
    ["pressure", "hydraulicManifold", "MOBILE SYSTEMS ENGINEERING", "HPM-3 MANIFOLD", "HYDRAULIC CONTROL MANIFOLD", "Balance all coupled lines inside their marked operating bands.", "PRESSURISE", [0.86, 0.58, 0.18, 1], [0.15, 0.17, 0.18, 1]],
    ["sequence", "secureConsole", "DEFENCE CONTROL SYSTEMS", "SCU-6 AUTH CONSOLE", "SECURE CONTROL CONSOLE", "Observe and reproduce each authorization signal in exact order.", "BEGIN TEST", [0.56, 0.66, 0.78, 1], [0.14, 0.15, 0.17, 1]],
    ["commandinput", "tacticalUplink", "JOINT SUPPORT NETWORK", "TCU-4 COMMAND UPLINK", "TACTICAL COMMAND UPLINK", "Enter each displayed directional command packet to authorize the support channel.", "OPEN UPLINK", [0.88, 0.64, 0.18, 1], [0.12, 0.15, 0.14, 1]]
];

private _row = _profiles select 0;
{ if ((_x select 0) == toLower _challengeId) exitWith {_row = _x;}; } forEach _profiles;
private _profile = createHashMapFromArray [
    ["challengeId", _row select 0], ["preset", _row select 1],
    ["manufacturer", _row select 2], ["model", _row select 3],
    ["title", _row select 4], ["objective", _row select 5],
    ["activation", _row select 6], ["accent", _row select 7],
    ["casing", _row select 8], ["successText", "PROCEDURE COMPLETE"],
    ["failureText", "PROCEDURE FAILED"], ["timeoutText", "OPERATING WINDOW EXPIRED"],
    ["abortText", "ABORTING COUNTS AS A FAILED PROCEDURE"],
    ["briefing", "FIELD OPERATING PROCEDURE"],
    ["controls", ""], ["hint", ""],
    ["statusText", "[ACTIVE] FOLLOW THE OPERATING PROCEDURE"],
    ["skin", "default"], ["soundProfile", "equipment"],
    ["texture", ""], ["texturePreset", "none"], ["textureOpacity", 0.14],
    ["actionTitle", format ["Inspect %1", toLower (_row select 4)]],
    ["icon", "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"]
];
_profile set ["customTitle", false];

private _pairs = [];
if (typeName _overrides == "HASHMAP") then {
    { _pairs pushBack [_x, _overrides get _x]; } forEach keys _overrides;
} else {
    _pairs = _overrides;
};
private _allowed = ["preset", "manufacturer", "model", "title", "objective", "activation", "briefing", "controls", "hint", "statusText", "successText", "failureText", "timeoutText", "abortText", "actionTitle", "icon", "texture", "texturePreset", "soundProfile", "skin", "textureOpacity"];
private _stringKeys = _allowed - ["textureOpacity"];
private _textureCustomized = ({(_x select 0) == "texture" && {typeName (_x select 1) == "STRING"}} count _pairs) > 0;

private _requestedPreset = _profile getOrDefault ["preset", _row select 1];
{ if ((_x select 0) == "preset") exitWith {_requestedPreset = _x select 1;}; } forEach _pairs;
if (typeName _requestedPreset != "STRING") then {_requestedPreset = _row select 1;};
private _variants = [
    ["vehicleCharge", "ARMOURED ENGINEERING GROUP", "VDC-2 DEMOLITION CONTROL", "VEHICLE DEMOLITION UNIT", "Trace the firing loom and isolate the armed initiator.", "ARM TEST PROBE"],
    ["navalCharge", "NAVAL EOD COMMAND", "SUBMERSIBLE CHARGE PANEL", "NAVAL CHARGE CONTROLLER", "Isolate the live detonator lead without disturbing the anti-tamper circuit.", "BEGIN ISOLATION"],
    ["mineDetector", "COMBAT ENGINEER SYSTEMS", "MD-8 GROUND SCANNER", "ORDNANCE DETECTOR DISPLAY", "Survey the grid and flag every suspected explosive return.", "START SURVEY"],
    ["safeController", "HARDENED STORAGE SYSTEMS", "VAULT CONTROL MK II", "INDUSTRIAL SAFE CONTROLLER", "Recover the vault authorization code before security lockout.", "WAKE CONTROLLER"],
    ["bunkerTerminal", "FACILITY SECURITY COMMAND", "BUNKER ACCESS NODE", "BUNKER SECURITY TERMINAL", "Authenticate the protected access sequence.", "ENABLE NODE"],
    ["safeLock", "HARDENED STORAGE SYSTEMS", "CUTAWAY VAULT CYLINDER", "SAFE LOCK MECHANISM", "Set the binding pins and rotate the protected cylinder.", "APPLY TORQUE"],
    ["vehicleIgnition", "MOTOR TRANSPORT WORKSHOP", "IGNITION BARREL TYPE 3", "VEHICLE IGNITION CYLINDER", "Set each wafer at the shear line while maintaining tension.", "INSERT PICK"],
    ["communicationsRelay", "NATO SIGNAL CORPS", "REMOTE RELAY JUNCTION", "COMMUNICATIONS RELAY CABINET", "Route each isolated relay to its matching signal bus.", "ENERGISE RELAYS"],
    ["facilityFusePanel", "FACILITY POWER SERVICES", "DISTRIBUTION PANEL F-12", "FACILITY FUSE PANEL", "Reconnect each protected circuit to its labelled fuse block.", "ENABLE PANEL"],
    ["armourPlate", "ARMOURED SUPPORT GROUP", "ACCESS PLATE TYPE 6", "ARMOURED ACCESS PLATE", "Torque every retaining bolt without stripping the captive threads.", "BEGIN FIELD REPAIR"],
    ["fieldGenerator", "NATO FIELD POWER SYSTEMS", "GENSET SERVICE BAY", "FIELD GENERATOR SERVICE HATCH", "Secure the generator assembly to its specified torque.", "BEGIN SERVICE"],
    ["antennaController", "NATO SIGNAL CORPS", "ATU-9 MATCHING UNIT", "ANTENNA TUNING CONTROLLER", "Match and hold every assigned carrier against the antenna response.", "OPEN CARRIER"],
    ["distressBeacon", "COMBAT RECOVERY SYSTEMS", "SAR BEACON CALIBRATOR", "DISTRESS BEACON RECEIVER", "Acquire each beacon component and hold a stable rescue fix.", "BEGIN SEARCH"],
    ["fuelRegulator", "AVIATION FUEL SYSTEMS", "FPM-4 REGULATOR", "FUEL PRESSURE REGULATOR", "Balance all coupled fuel lines inside their operating bands.", "CHARGE LINES"],
    ["coolantControl", "FIELD POWER SERVICES", "THERMAL LOOP MANIFOLD", "COOLANT CONTROL ASSEMBLY", "Stabilize every coolant loop inside its marked safe band.", "START PUMPS"],
    ["authorizationConsole", "DEFENCE CONTROL SYSTEMS", "AUTH STATION SCU-6", "SECURE AUTHORIZATION CONSOLE", "Verify the illuminated authorization signals in exact order.", "BEGIN AUTHORIZATION"],
    ["supportTerminal", "JOINT FIRES NETWORK", "JTAC UPLINK TCU-4", "TACTICAL SUPPORT TERMINAL", "Enter the authenticated directional command packets to open the support channel.", "REQUEST LINK"]
];
{
    if ((_x select 0) == _requestedPreset) exitWith {
        _profile set ["preset", _x select 0];
        _profile set ["manufacturer", _x select 1];
        _profile set ["model", _x select 2];
        _profile set ["title", _x select 3];
        _profile set ["customTitle", true];
        _profile set ["objective", _x select 4];
        _profile set ["activation", _x select 5];
        _profile set ["actionTitle", format ["Inspect %1", toLower (_x select 3)]];
    };
} forEach _variants;
{
    _x params ["_key", "_value"];
    if (_key in _stringKeys && {typeName _value == "STRING"}) then {
        _profile set [_key, _value];
        if (_key == "title") then {_profile set ["customTitle", true];};
    };
    if (_key == "textureOpacity" && {typeName _value == "SCALAR"}) then {
        _profile set ["textureOpacity", (_value max 0) min 0.32];
    };
} forEach _pairs;

// Skins are curated palettes rather than arbitrary colours, preserving contrast and state meaning.
private _skins = createHashMapFromArray [
    ["olive", [[0.16, 0.17, 0.14, 1], [0.76, 0.55, 0.16, 1]]],
    ["charcoal", [[0.10, 0.11, 0.12, 1], [0.48, 0.70, 0.82, 1]]],
    ["sand", [[0.25, 0.23, 0.17, 1], [0.92, 0.72, 0.28, 1]]],
    ["naval", [[0.10, 0.15, 0.18, 1], [0.34, 0.72, 0.78, 1]]],
    ["hazard", [[0.13, 0.13, 0.11, 1], [0.96, 0.70, 0.16, 1]]]
];
private _skin = toLower (_profile getOrDefault ["skin", "default"]);
if (_skin != "default" && {isNil {_skins get _skin}}) then {_skin = "default";};
_profile set ["skin", _skin];
if (_skin != "default") then {
    private _skinColours = _skins get _skin;
    _profile set ["casing", _skinColours select 0];
    _profile set ["accent", _skinColours select 1];
};
// Bitmap materials are strictly opt-in. Procedural controls are always the primary presentation.
private _texturePresets = createHashMapFromArray [
    ["olive", "MissionScripts\InteractionsMinigames\Themes\Textures\equipment_olive.jpg"],
    ["charcoal", "MissionScripts\InteractionsMinigames\Themes\Textures\equipment_charcoal.jpg"],
    ["naval", "MissionScripts\InteractionsMinigames\Themes\Textures\equipment_naval.jpg"],
    ["sand", "MissionScripts\InteractionsMinigames\Themes\Textures\equipment_sand.jpg"]
];
private _texturePreset = toLower (_profile getOrDefault ["texturePreset", "none"]);
if (_texturePreset != "none" && {isNil {_texturePresets get _texturePreset}}) then {_texturePreset = "none";};
_profile set ["texturePreset", _texturePreset];
if (!_textureCustomized && {_texturePreset != "none"}) then {
    _profile set ["texture", _texturePresets get _texturePreset];
};
private _soundProfile = toLower (_profile getOrDefault ["soundProfile", "equipment"]);
if !(_soundProfile in ["equipment", "silent"]) then {_soundProfile = "equipment";};
_profile set ["soundProfile", _soundProfile];

// Accent and semantic colours are template-owned: arbitrary overrides cannot break contrast.
private _uiTheme = [] call Waldo_fnc_UiTheme;
_profile set ["uiTheme", _uiTheme];
_profile set ["casing", _uiTheme getOrDefault ["casing", _profile getOrDefault ["casing", [0.16, 0.17, 0.14, 1]]]];
_profile set ["accent", _uiTheme getOrDefault ["accent", _profile getOrDefault ["accent", [0.76, 0.55, 0.16, 1]]]];
private _access = [] call Waldo_fnc_MiniGameAccessibility;
if (_access getOrDefault ["highContrast", false]) then {
    _profile set ["casing", [0.035, 0.04, 0.04, 1]];
    _profile set ["accent", [0.96, 0.78, 0.20, 1]];
};
_profile set ["accessibility", _access];
_profile
