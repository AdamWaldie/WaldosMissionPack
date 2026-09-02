/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe WMP Options launchers for Notification UI, WMP HUD and cross-interface
 * Accessibility settings. ACE provides the preferred hierarchy and retains rapid conditional HUD
 * Enable/Disable actions; vanilla addAction is the documented fallback. HUD action conditions keep
 * mission enablement, toggle policy and eligibility authoritative. Personal presentation survives
 * profile reload; actions are reinstalled for the new local player object after respawn/JIP.
 *
 * Arguments: None.
 * Return Value: BOOL - true when the current player has ACE or fallback WMP Options actions.
 * Current callers: initPlayerLocal.sqf, WMP HUD initialization and player respawn handling.
 * Example: [] call Waldo_fnc_AccessibilitySelfInteractionInit;
 */

if (!hasInterface || {isNull player}) exitWith {false};
if (player getVariable ["Waldo_Accessibility_SelfInteractionInstalled", false]) exitWith {true};
private _aceReady = !(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
if (_aceReady) then {
    [] call Waldo_fnc_SetupUiCleanupAction;
    private _notification = ["Waldo_UI_NotificationSettings", "Notification UI Settings", "", {[] call Waldo_fnc_UiNotificationSettingsOpenLocal}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _notification] call ace_interact_menu_fnc_addActionToObject;
    private _hudRoot = ["Waldo_WmpHud_Root", "WMP HUD", "\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _hudRoot] call ace_interact_menu_fnc_addActionToObject;
    private _hudEnable = ["Waldo_WmpHud_EnableLocal", "Enable WMP HUD", "", {[true] call Waldo_fnc_WmpHudToggle}, {
        missionNamespace getVariable ["Waldo_WmpHud_ClientStarted", false]
        && {missionNamespace getVariable ["Waldo_WmpHud_AllowToggle", true]}
        && {!(missionNamespace getVariable ["Waldo_WmpHud_Visible", false])}
        && {[player] call Waldo_fnc_WmpHudEligible}
    }] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_WmpHud_Root"], _hudEnable] call ace_interact_menu_fnc_addActionToObject;
    private _hudDisable = ["Waldo_WmpHud_DisableLocal", "Disable WMP HUD", "", {[false] call Waldo_fnc_WmpHudToggle}, {
        missionNamespace getVariable ["Waldo_WmpHud_ClientStarted", false]
        && {missionNamespace getVariable ["Waldo_WmpHud_AllowToggle", true]}
        && {missionNamespace getVariable ["Waldo_WmpHud_Visible", false]}
    }] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_WmpHud_Root"], _hudDisable] call ace_interact_menu_fnc_addActionToObject;
    private _hudSettings = ["Waldo_WmpHud_Settings", "WMP HUD Settings", "", {[] call Waldo_fnc_WmpHudSettingsOpenLocal}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_WmpHud_Root"], _hudSettings] call ace_interact_menu_fnc_addActionToObject;
    private _accessibility = ["Waldo_Accessibility_Settings", "Accessibility Settings", "", {[] call Waldo_fnc_UiColourVisionOpenLocal}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _accessibility] call ace_interact_menu_fnc_addActionToObject;
    player setVariable ["Waldo_Accessibility_InteractionMode", "ACE"];
} else {
    private _actions = [];
    _actions pushBack (player addAction ["<t color='#79C7FF'>WMP: Notification UI Settings</t>", {[] call Waldo_fnc_UiNotificationSettingsOpenLocal}, [], -89, false, true, "", "alive _target && {_this isEqualTo _target}"]);
    _actions pushBack (player addAction ["<t color='#79C7FF'>WMP HUD: Enable</t>", {[true] call Waldo_fnc_WmpHudToggle}, [], -90, false, true, "", "missionNamespace getVariable ['Waldo_WmpHud_ClientStarted',false] && {missionNamespace getVariable ['Waldo_WmpHud_AllowToggle',true]} && {!(missionNamespace getVariable ['Waldo_WmpHud_Visible',false])} && {[player] call Waldo_fnc_WmpHudEligible}"]);
    _actions pushBack (player addAction ["<t color='#79C7FF'>WMP HUD: Disable</t>", {[false] call Waldo_fnc_WmpHudToggle}, [], -91, false, true, "", "missionNamespace getVariable ['Waldo_WmpHud_ClientStarted',false] && {missionNamespace getVariable ['Waldo_WmpHud_AllowToggle',true]} && {missionNamespace getVariable ['Waldo_WmpHud_Visible',false]}"]);
    _actions pushBack (player addAction ["<t color='#79C7FF'>WMP HUD: Settings</t>", {[] call Waldo_fnc_WmpHudSettingsOpenLocal}, [], -92, false, true, "", "alive _target && {_this isEqualTo _target}"]);
    _actions pushBack (player addAction ["<t color='#79C7FF'>WMP: Accessibility Settings</t>", {[] call Waldo_fnc_UiColourVisionOpenLocal}, [], -93, false, true, "", "alive _target && {_this isEqualTo _target}"]);
    player setVariable ["Waldo_Accessibility_FallbackActions", _actions];
    player setVariable ["Waldo_Accessibility_InteractionMode", "VANILLA"];
};
player setVariable ["Waldo_Accessibility_SelfInteractionInstalled", true];
if !(missionNamespace getVariable ["Waldo_Accessibility_RespawnInteractionInstalled", false]) then {
    missionNamespace setVariable ["Waldo_Accessibility_RespawnInteractionInstalled", true];
    addMissionEventHandler ["EntityRespawned", {params ["_newEntity"]; if (local _newEntity && {_newEntity isEqualTo player}) then {[] call Waldo_fnc_AccessibilitySelfInteractionInit;};}];
};
true
