/*
 * Author: WaldoTheWarfighter
 * Mission-maker-friendly preset wrapper for Waldo_fnc_MiniGameInteraction. One Eden init line
 * attaches any built-in challenge with a suitable action title, icon and balanced default config.
 * State/result and legacy success/failure booleans are broadcast before optional callbacks run.
 *
 * Arguments:
 * _object      - Object - object receiving the interaction
 * _challengeId - String - wirecut/minesweeper/keypad/lockpick/circuit/repair/radiotune/pressure/sequence/commandinput
 * _options     - Array/HashMap - optional named settings. Legacy arrays retain "title" as
 *                  the action label; hashmaps use "actionTitle" and reserve "title" for
 *                  the equipment faceplate.
 *                  "config"          Array  - complete challenge config override
 *                  "difficulty"      String - easy/standard/hard/expert (default standard);
 *                                             ignored when config is supplied
 *                  "successVariable" String - broadcast object variable set true on success
 *                  "failureVariable" String - broadcast object variable set true on failure
 *                  "retryOnFailure"  Bool   - keep action after failure (default true)
 *                  "repeatable"      Bool   - keep action after success (default false)
 *                  "distance"        Number - vanilla addAction distance (default 4)
 *                  "lockTimeout"     Number - exclusive lock expiry in seconds (default 600)
 *                  "condition"       Code   - additional interaction condition (default {true})
 *                  "icon"            String - ACE action icon override
 *                  "preset"          String - curated equipment identity
 *                  "skin"            String - olive/charcoal/sand/naval/hazard
 *                  "title"           String - equipment faceplate title (hashmap only)
 *                  "objective"       String - operating objective
 *                  "briefing"        String - procedure-card heading
 *                  "controls"        String - control reminder override
 *                  "hint"            String - contextual help text override
 *                  "statusText"      String - initial active-state message
 *                  "soundProfile"    String - equipment/silent
 *                  "texturePreset"   String - none/olive/charcoal/naval/sand (default none)
 *                  "texture"         String - opt-in mission/vanilla texture path
 *                  "textureOpacity"  Number - decorative overlay opacity, clamped 0..0.32
 *                  "onSuccess"       Code   - server callback after variables are set
 *                  "onFailure"       Code   - server callback after variables are set
 *
 * Return Value:
 * Boolean - true when a known preset was attached
 *
 * Example:
 * [this, "repair"] call Waldo_fnc_MiniGameInteractionSetup;
 * [this, "radiotune", [["title", "Align Antenna"], ["config", [4, 0.04, 1, 40]]]]
 *     call Waldo_fnc_MiniGameInteractionSetup;
 */

params [
    ["_object", objNull, [objNull]],
    ["_challengeId", "repair", [""]],
    ["_options", [], [[], createHashMap]]
];
if (isNull _object) exitWith { false };

private _presets = [
    ["wirecut", "Inspect EOD Controller", [5, 30, "EOD CONTROLLER", 2], "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"],
    ["minesweeper", "Inspect Trigger Analyser", [5, 5, 0, "TRIGGER ANALYSER"], "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"],
    ["keypad", "Inspect Access Terminal", [4, 6, 0, "ACCESS TERMINAL"], "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"],
    ["lockpick", "Inspect Lock Cylinder", [3, 2.8, 0.16, 0, "LOCK CYLINDER"], "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"],
    ["circuit", "Inspect Breaker Cabinet", [4, 3, 0, "BREAKER CABINET"], "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa"],
    ["repair", "Open Maintenance Hatch", [4, 2, 3, 30, "MAINTENANCE HATCH"], "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa"],
    ["radiotune", "Inspect Communications Unit", [3, 0.05, 1, 30, "COMMUNICATIONS UNIT"], "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"],
    ["pressure", "Inspect Hydraulic Manifold", [3, 1, 2, 45, "HYDRAULIC MANIFOLD"], "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa"],
    ["sequence", "Inspect Control Console", [4, 4, 0.85, 0, "CONTROL CONSOLE"], "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"],
    ["commandinput", "Access Tactical Uplink", [4, 3, 3, 45, "TACTICAL UPLINK"], "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"]
];
private _preset = [];
{
    if ((_x select 0) == _challengeId) exitWith { _preset = _x; };
} forEach _presets;
if (_preset isEqualTo []) exitWith {
    systemChat format ["Field Equipment: unknown procedure '%1'.", _challengeId];
    false
};

private _optionPairs = [];
if (typeName _options == "HASHMAP") then {
    { _optionPairs pushBack [_x, _options get _x]; } forEach keys _options;
} else {
    _optionPairs = _options;
};
private _opt = {
    params ["_key", "_default"];
    private _result = _default;
    { if ((_x select 0) == _key) exitWith { _result = _x select 1; }; } forEach _optionPairs;
    _result
};
private _presentationPairs = [];
private _presentationKeys = ["preset", "manufacturer", "model", "objective", "activation", "briefing", "controls", "hint", "statusText", "successText", "failureText", "timeoutText", "abortText", "texture", "texturePreset", "textureOpacity", "soundProfile", "skin"];
{
    if ((_x select 0) in _presentationKeys) then {_presentationPairs pushBack _x;};
} forEach _optionPairs;
private _embeddedPresentation = ["presentation", []] call _opt;
if (typeName _embeddedPresentation == "HASHMAP") then {
    { _presentationPairs pushBack [_x, _embeddedPresentation get _x]; } forEach keys _embeddedPresentation;
} else {
    { _presentationPairs pushBack _x; } forEach _embeddedPresentation;
};
if (typeName _options == "HASHMAP" && {!(isNil {_options get "title"})}) then {
    _presentationPairs pushBack ["title", _options get "title"];
};
private _profile = [_challengeId, _presentationPairs] call Waldo_fnc_MiniGameEquipmentProfile;
private _title = if (typeName _options == "HASHMAP") then {
    ["actionTitle", _profile getOrDefault ["actionTitle", _preset select 1]] call _opt
} else {
    ["title", _preset select 1] call _opt
};
private _difficultyValue = ["difficulty", "standard"] call _opt;
private _difficulty = if (typeName _difficultyValue == "STRING") then {toLower _difficultyValue} else {"standard"};
if !(_difficulty in ["easy", "standard", "hard", "expert"]) then {
    systemChat format ["Field Equipment: unknown difficulty '%1'; using standard.", _difficulty];
    _difficulty = "standard";
};
private _difficultyConfig = [_challengeId, _difficulty] call Waldo_fnc_MiniGameEquipmentDifficultyConfig;
if (_difficultyConfig isEqualTo []) then {_difficultyConfig = +(_preset select 2);};
private _hasConfigOverride = false;
{
    if ((_x param [0, ""]) == "config") exitWith {_hasConfigOverride = true;};
} forEach _optionPairs;
private _config = if (_hasConfigOverride) then {["config", _difficultyConfig] call _opt} else {_difficultyConfig};
private _icon = ["icon", _preset select 3] call _opt;
private _successVariable = ["successVariable", "Waldo_MG_InteractionComplete"] call _opt;
private _failureVariable = ["failureVariable", "Waldo_MG_InteractionFailed"] call _opt;
private _retryOnFailure = ["retryOnFailure", true] call _opt;
private _repeatable = ["repeatable", false] call _opt;
private _distance = ["distance", 4] call _opt;
private _lockTimeout = ["lockTimeout", 600] call _opt;
private _condition = ["condition", {true}] call _opt;
private _onSuccess = ["onSuccess", {}] call _opt;
private _onFailure = ["onFailure", {}] call _opt;

// Setup runs from an Eden object init on every machine. Clients need the same
// values for presentation and local action conditions, but only the server may
// publish authoritative configuration to the network.
private _publishPreset = isServer;
_object setVariable ["Waldo_MG_Preset_SuccessVariable", _successVariable, _publishPreset];
_object setVariable ["Waldo_MG_Preset_FailureVariable", _failureVariable, _publishPreset];
_object setVariable ["Waldo_MG_Preset_RetryOnFailure", _retryOnFailure, _publishPreset];
_object setVariable ["Waldo_MG_Preset_Repeatable", _repeatable, _publishPreset];
_object setVariable ["Waldo_MG_Preset_ChallengeId", _challengeId, _publishPreset];
_object setVariable ["Waldo_MG_Preset_Difficulty", (if (_hasConfigOverride) then {"custom"} else {_difficulty}), _publishPreset];
_object setVariable ["Waldo_MG_Preset_OnSuccess", _onSuccess];
_object setVariable ["Waldo_MG_Preset_OnFailure", _onFailure];

private _success = {
    params ["_obj", "_actor", "_success", ["_interactionResult", []]];
    [_obj, _actor, _success, _interactionResult] call (_obj getVariable ["Waldo_MG_Preset_OnSuccess", {}]);
};
private _failure = {
    params ["_obj", "_actor", "_success", ["_interactionResult", []]];
    [_obj, _actor, _success, _interactionResult] call (_obj getVariable ["Waldo_MG_Preset_OnFailure", {}]);
};

[
    _object,
    _challengeId,
    _config,
    _success,
    _failure,
    [
        ["title", _title],
        ["icon", _icon],
        ["condition", _condition],
        ["oneShot", false],
        ["distance", _distance],
        ["lockTimeout", _lockTimeout],
        ["presentation", _presentationPairs]
    ]
] call Waldo_fnc_MiniGameInteraction;

true
