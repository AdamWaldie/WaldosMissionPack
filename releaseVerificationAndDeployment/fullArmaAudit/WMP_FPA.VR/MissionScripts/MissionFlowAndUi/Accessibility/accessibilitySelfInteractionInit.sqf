/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe Accessibility category beneath WMP Interface for every player. It owns
 * the personal colour-vision selector. The WMP HUD is a sibling action because it is both campaign
 * equipment and an accessibility aid; its condition grants access through either route. The WMP
 * Interface parent and actions are reinstalled on respawn because the player object changes.
 *
 * Arguments: None.
 * Return Value: BOOL - true when the current player has an ACE or fallback accessibility action.
 *
 * Example:
 * [] call Waldo_fnc_AccessibilitySelfInteractionInit;
 * Current callers: initPlayerLocal.sqf, WMP HUD initialization and player respawn handling.
 */

if (!hasInterface || {isNull player}) exitWith {false};
if (player getVariable ["Waldo_Accessibility_SelfInteractionInstalled", false]) exitWith {true};
private _aceReady = !(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
if (_aceReady) then {
    // This function may be reached from PID runtime state before initPlayerLocal reaches its
    // ordinary interface setup. Ensure the shared parent exists without relying on call order.
    [] call Waldo_fnc_SetupUiCleanupAction;
    private _root = ["Waldo_Accessibility_Root", "Accessibility", "", {}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _root] call ace_interact_menu_fnc_addActionToObject;
    private _colour = ["Waldo_Accessibility_ColourVision", "Colour Vision Settings", "", {[] call Waldo_fnc_UiColourVisionOpenLocal}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_Accessibility_Root"], _colour] call ace_interact_menu_fnc_addActionToObject;
    private _hud = ["Waldo_WmpHud_Toggle", "Toggle WMP HUD", "\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa", {[] call Waldo_fnc_WmpHudToggle}, {
        missionNamespace getVariable ["Waldo_WmpHud_ClientStarted", false]
        && {missionNamespace getVariable ["Waldo_WmpHud_AllowToggle", true]}
        && {[player] call Waldo_fnc_WmpHudEligible}
    }] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _hud] call ace_interact_menu_fnc_addActionToObject;
    player setVariable ["Waldo_Accessibility_InteractionMode", "ACE"];
} else {
    private _id = player addAction ["<t color='#79C7FF'>Accessibility: Colour Vision</t>", {[] call Waldo_fnc_UiColourVisionOpenLocal}, [], -89, false, true, "", "alive _target && {_this isEqualTo _target}"];
    player setVariable ["Waldo_Accessibility_FallbackAction", _id];
    private _hudId = player addAction ["<t color='#79C7FF'>WMP HUD: Show / Hide</t>", {[] call Waldo_fnc_WmpHudToggle}, [], -90, false, true, "", "missionNamespace getVariable ['Waldo_WmpHud_ClientStarted',false] && {missionNamespace getVariable ['Waldo_WmpHud_AllowToggle',true]} && {[player] call Waldo_fnc_WmpHudEligible}"];
    player setVariable ["Waldo_WmpHud_FallbackAction", _hudId];
    player setVariable ["Waldo_Accessibility_InteractionMode", "VANILLA"];
};
player setVariable ["Waldo_Accessibility_SelfInteractionInstalled", true];
if !(missionNamespace getVariable ["Waldo_Accessibility_RespawnInteractionInstalled", false]) then {
    missionNamespace setVariable ["Waldo_Accessibility_RespawnInteractionInstalled", true];
    addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity"];
        if (local _newEntity && {_newEntity isEqualTo player}) then {[] call Waldo_fnc_AccessibilitySelfInteractionInit;};
    }];
};
true
