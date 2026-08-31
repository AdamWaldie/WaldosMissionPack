/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe local WMP Interface root with emergency UI cleanup and contextual
 * SafeStart acknowledgement. ACE self-interaction is primary; blue vanilla addActions are installed
 * only when ACE interaction is unavailable. Actions are attached to the current player object, so
 * initPlayerLocal.sqf calls this on join and again after respawn. No authoritative or JIP state is
 * changed: cleanup affects WMP-owned local controls and acknowledgement suppresses only this
 * player's current SafeStart presentation phase.
 *
 * Arguments: None.
 * Return Value: BOOL - true when actions are already installed or installation succeeds.
 * Current callers: initPlayerLocal.sqf and accessibilitySelfInteractionInit.sqf.
 * Example: [] call Waldo_fnc_SetupUiCleanupAction;
 */
if (!hasInterface || {isNull player}) exitWith {false};
if (player getVariable ["Waldo_UI_CleanupActionInstalled", false]) exitWith {true};

private _aceAvailable =
    isClass (configFile >> "CfgPatches" >> "ace_interact_menu")
    && {!isNil "ace_interact_menu_fnc_createAction"}
    && {!isNil "ace_interact_menu_fnc_addActionToObject"};

if (_aceAvailable) then {
    private _root = [
        "Waldo_UI_SelfRoot",
        "WMP Interface",
        "",
        {},
        {true}
    ] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _root] call ace_interact_menu_fnc_addActionToObject;

    private _clear = [
        "Waldo_UI_ClearPanels",
        "Clear Stuck WMP UI",
        "",
        {[] call Waldo_fnc_ClearUiPanels;},
        {true}
    ] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _clear] call ace_interact_menu_fnc_addActionToObject;

    private _acknowledge = [
        "Waldo_UI_AcknowledgeSafeStart",
        "Acknowledge SafeStart",
        "",
        {[] call Waldo_fnc_SafeStartAcknowledgeLocal},
        {missionNamespace getVariable ["Waldo_SafeStart_LocalActive", false]}
    ] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _acknowledge] call ace_interact_menu_fnc_addActionToObject;
    player setVariable ["Waldo_UI_CleanupInteractionMode", "ACE"];
} else {
    private _actionId = player addAction [
        "<t color='#79C7FF'>Clear Stuck WMP UI</t>",
        {[] call Waldo_fnc_ClearUiPanels;},
        [],
        -90,
        false,
        true,
        "",
        "alive _target && {_this isEqualTo _target}"
    ];
    player setVariable ["Waldo_UI_CleanupVanillaAction", _actionId];
    private _acknowledgeId = player addAction [
        "<t color='#79C7FF'>Acknowledge SafeStart</t>",
        {[] call Waldo_fnc_SafeStartAcknowledgeLocal},
        [],
        -89,
        false,
        true,
        "",
        "alive _target && {_this isEqualTo _target} && {missionNamespace getVariable ['Waldo_SafeStart_LocalActive', false]}"
    ];
    player setVariable ["Waldo_UI_AcknowledgeSafeStartVanillaAction", _acknowledgeId];
    player setVariable ["Waldo_UI_CleanupInteractionMode", "VANILLA"];
};

player setVariable ["Waldo_UI_CleanupActionInstalled", true];
diag_log format ["[WMP UI] cleanup action installed mode=%1 clientOwner=%2", player getVariable ["Waldo_UI_CleanupInteractionMode", "NONE"], clientOwner];
true
