/* Gives the local ACE interaction menu temporary draw priority over WMP cards. */
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
