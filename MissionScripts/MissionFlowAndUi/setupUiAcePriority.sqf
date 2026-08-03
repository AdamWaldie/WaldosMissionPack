/*
 * Author: WaldoTheWarfighter
 * Gives the local ACE interaction menu temporary draw priority over all concurrent WMP HUD cards.
 * Installation is client-local, repeat-safe and event driven; closed-menu restoration retains live
 * feature state and drains only still-valid bounded notification requests.
 *
 * Arguments: None.
 *
 * Return Value: BOOL - true when installed/already installed, false when ACE Interact is absent.
 *
 * Example: [] call Waldo_fnc_SetupUiAcePriority;
 * Current caller: initPlayerLocal.sqf after the local WMP interface is ready.
 */
if (!hasInterface) exitWith {false};
if (uiNamespace getVariable ["Waldo_UI_AcePriorityInstalled", false]) exitWith {true};
if !(isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {false};

uiNamespace setVariable ["Waldo_UI_AcePriorityInstalled", true];
uiNamespace setVariable ["Waldo_UI_AceInteractionOpen", false];

["ace_interactMenuOpened", {
    uiNamespace setVariable ["Waldo_UI_AceInteractionOpen", true];
    [true] call Waldo_fnc_SetUiPanelsSuppressed;
}] call CBA_fnc_addEventHandler;

["ace_interactMenuClosed", {
    uiNamespace setVariable ["Waldo_UI_AceInteractionOpen", false];
    [false] call Waldo_fnc_SetUiPanelsSuppressed;
}] call CBA_fnc_addEventHandler;

true
