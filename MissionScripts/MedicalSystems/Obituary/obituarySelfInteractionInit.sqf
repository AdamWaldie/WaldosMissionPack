/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe "Pronounce Dead" ACE_SelfActions submenu for the current player, replacing
 * the earlier per-corpse ACE_MainActions target action. A medic opens their own self-interaction menu
 * and gets one dynamically built row per eligible corpse (Waldo_fnc_ObituaryChildrenLocal) within
 * Waldo_Obituary_Radius, nearest first - fixing the original design's real accessibility problem
 * (a medic had to be within 3m of, and looking directly at, one exact corpse) while keeping its other
 * real strength (unambiguous per-corpse acknowledgement, never a blind "nearest body" guess that could
 * pronounce the wrong casualty in a pile-up) by giving every corpse in range its own named row instead
 * of collapsing them into one action.
 * ACE is a required WMP dependency and Waldo_fnc_ObituaryInit already gates entirely on
 * ace_interact_menu being loaded before this ever runs, so unlike most WMP self-actions there is no
 * vanilla addAction fallback here - there never was one for Obituary's ACE_MainActions predecessor
 * either.
 * The self-action root lives on the player OBJECT (ACE_SelfActions is per-object, not per-class), so
 * it must be reinstalled every time Arma replaces the player object - the same
 * EntityRespawned-registers-itself-once idiom already used by
 * Waldo_fnc_AccessibilitySelfInteractionInit.
 *
 * Arguments: None.
 * Return Value: BOOL - true when the current player has the self-action installed (or ACE interaction
 * is unavailable, in which case there is nothing to install and this still returns true).
 *
 * Example:
 * [] call Waldo_fnc_ObituarySelfInteractionInit;
 * Current callers: Waldo_fnc_ObituaryInit, and this function's own respawn re-installer.
 */

if (!hasInterface || {isNull player}) exitWith {false};
if (player getVariable ["Waldo_Obituary_SelfInteractionInstalled", false]) exitWith {true};
if (isNil "ace_interact_menu_fnc_createAction" || {isNil "ace_interact_menu_fnc_addActionToObject"}) exitWith {false};

private _root = ["Waldo_Obituary_Root", "Pronounce Dead", "a3\ui_f\data\igui\cfg\actions\heal_ca.paa", {}, {
    (_this select 1) getUnitTrait "Medic"
}, {
    params ["_target", "_player"];
    [_player] call Waldo_fnc_ObituaryChildrenLocal
}] call ace_interact_menu_fnc_createAction;
[player, 1, ["ACE_SelfActions"], _root] call ace_interact_menu_fnc_addActionToObject;

player setVariable ["Waldo_Obituary_SelfInteractionInstalled", true];
if !(missionNamespace getVariable ["Waldo_Obituary_RespawnInteractionInstalled", false]) then {
    missionNamespace setVariable ["Waldo_Obituary_RespawnInteractionInstalled", true];
    addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity"];
        if (local _newEntity && {_newEntity isEqualTo player}) then {[] call Waldo_fnc_ObituarySelfInteractionInit;};
    }];
};
true
