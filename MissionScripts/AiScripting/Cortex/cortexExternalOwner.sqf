/*
 * Author: WaldoTheWarfighter
 * Identifies AI whose movement, animation or combat state belongs to a supported external system.
 * Cortex uses this one read-only gate before any tactic so WebKnight custom skeletons, zombies,
 * droids, active IMS melee actors and Simple Civilian Behaviour never receive competing commands.
 * Ordinary infantry remains eligible when those addons are merely loaded.
 *
 * Locality / Authority: read-only and callable anywhere. No public state or addon variable is changed.
 * Repeat/JIP: repeat-safe; it reads current config and public runtime markers on every call.
 *
 * Arguments:
 * 0: actor <OBJECT>, default objNull
 *
 * Return Value:
 * String - empty when Cortex may proceed, otherwise WBK, IMS or WBK_CIVILIAN.
 *
 * Current callers: Waldo_fnc_CortexIsEligible and AI diagnostics.
 *
 * Example:
 * private _owner = [_unit] call Waldo_fnc_CortexExternalOwner;
 * Result: "WBK" for a WebKnight droid and "" for an ordinary NATO rifleman.
 */

params [["_unit",objNull,[objNull]]];
if (isNull _unit) exitWith {""};

private _config=configOf _unit;
private _faction=getText (_config >> "faction");
private _moves=getText (_config >> "moves");
private _author=toLowerANSI (getText (_config >> "author"));
private _subcategory=getText (_config >> "editorSubcategory");
private _wbkFactions=[
    "WBK_AI_ZHAMBIES","WBK_AI_StarWars_Droids","WBK_AI","WBK_AI_Melee",
    "WBK_EOO_Secession","WBK_EOO_Vamp","Empires_Of_Old_faction_Vamp",
    "WBK_EOO_FreeCompany","WBK_EOO_Empire","WBK_HL_Aliens","WBK_HL_resistance",
    "WBK_HL_Combines","OPTRE_FC_Covenant","dev_flood","dev_mutants"
];
private _wbkMarker=!(isNil {_unit getVariable "WBK_AI_ISZombie"})
    || {!(isNil {_unit getVariable "Droid_Health"})}
    || {!(isNil {_unit getVariable "WBK_Droids_VoiceType"})}
    || {!(isNil {_unit getVariable "WBK_AI_ZombieMoveSet"})};
if (_wbkMarker || {_faction in _wbkFactions} || {_moves != "" && {_moves != "CfgmovesMaleSdr"}}
    || {_subcategory == "WBK_MeleeAi_SPACE_MARINES"} || {_author find "webknight" >= 0}) exitWith {"WBK"};

// IMS only owns an actor while its melee runtime says so. Loading IMS must not exclude every rifleman.
private _animation=toLowerANSI animationState _unit;
private _imsActive=!(isNil {_unit getVariable "IMS_IsUnitInvicibleScripted"})
    || {!(isNil {_unit getVariable "IMS_ISAI"})}
    || {!(isNil {_unit getVariable "IMS_EventHandler_Hit"})}
    || {_animation find "ims_" == 0}
    || {_animation find "star_wars_fight" == 0};
if (_imsActive) exitWith {"IMS"};

// The installed civilian addon owns all unarmed civilians, including before its scared marker is set.
if (side group _unit == civilian && {primaryWeapon _unit == ""}
    && {secondaryWeapon _unit == ""} && {handgunWeapon _unit == ""}
    && {!(isNil "WBK_CivilianFlee") || {!(isNil {_unit getVariable "WBK_VariableScared"})}}) exitWith {"WBK_CIVILIAN"};
""
