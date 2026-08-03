/*
 * Author: WaldoTheWarfighter
 * Create zeus prompt display.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_createZeusPromptDisplay;
 *
 * Current callers: Economy Zeus authoring modules before their controls are populated.
 */

    if (!hasInterface) exitWith {displayNull};

    private _existing = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    if (!isNull _existing) then {
        [_existing] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;
    };

    private _zeusDisplay = call Waldo_fnc_EcoCore_getZeusDisplay;
    private _parent = _zeusDisplay;
    if (isNull _parent) then {_parent = findDisplay 46;};
    if (isNull _parent) exitWith {
        diag_log format ["[WMP ECO UI] prompt creation failed: no Zeus or main display clientOwner=%1", clientOwner];
        displayNull
    };
    // Every authoring prompt owns a modal child display. Attaching controls to
    // Display #312 leaves Zeus' map, shortcuts and mouse handlers active beneath
    // the form, so clicks and keyboard focus can escape into the curator UI.
    // A transparent child preserves the visible Zeus context while giving the
    // prompt exclusive input ownership until it closes.
    private _disp = _parent createDisplay "RscDisplayEmpty";
    if (isNull _disp) exitWith {
        diag_log format ["[WMP ECO UI] prompt creation failed: child display unavailable clientOwner=%1", clientOwner];
        displayNull
    };
    _disp setVariable ["WaldoEcoCore_IsDedicatedZeusPromptDisplay", true];
    _disp setVariable ["Waldo_UI_ThemedDisplay", true];
    _disp setVariable ["WaldoEcoCore_PromptParentDisplay", _parent];
    _disp setVariable ["WaldoEcoCore_PromptOpenedFromZeus", !isNull _zeusDisplay];
    _disp setVariable ["WaldoEcoCore_PromptBaselineControls", +(allControls _disp)];
    private _maxCardBounds = [
        safeZoneX + (safeZoneW * 0.055),
        safeZoneY + (safeZoneH * 0.065),
        safeZoneW * 0.89,
        safeZoneH * 0.87
    ];
    private _theme = [] call Waldo_fnc_UiTheme;

    // Create the chrome before the prompt creates its controls. This keeps the
    // background behind the form while giving every Economy prompt the same
    // protected outer margin, header and inner content padding.
    private _dimmer = _disp ctrlCreate ["RscText", -1];
    _dimmer ctrlSetPosition [safeZoneX, safeZoneY, safeZoneW, safeZoneH];
    _dimmer ctrlSetBackgroundColor (_theme getOrDefault ["shade", [0, 0, 0, 0.44]]);
    _dimmer ctrlCommit 0;
    private _card = _disp ctrlCreate ["RscText", -1];
    _card ctrlSetPosition [safeZoneX + safeZoneW * 0.35, safeZoneY + safeZoneH * 0.30, safeZoneW * 0.30, safeZoneH * 0.40];
    _card ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.015, 0.02, 0.025, 0.96]]);
    _card ctrlCommit 0;
    private _header = _disp ctrlCreate ["RscText", -1];
    _header ctrlSetPosition [safeZoneX + safeZoneW * 0.35, safeZoneY + safeZoneH * 0.30, safeZoneW * 0.30, safeZoneH * 0.055];
    _header ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.025, 0.20, 0.36, 0.99]]);
    _header ctrlSetTextColor (_theme getOrDefault ["text", [0.90, 0.96, 1, 1]]);
    _header ctrlSetFont (_theme getOrDefault ["fontBold", "RobotoCondensedBold"]);
    _header ctrlSetText "  WALDOS MISSION PACK  |  ECONOMY AUTHORING";
    _header ctrlSetFontHeight ((safeZoneH * 0.027) min 0.034);
    _header ctrlCommit 0;
    private _chrome = [_dimmer, _card, _header];
    _disp setVariable ["WaldoEcoCore_PromptChromeControls", _chrome];
    _disp setVariable ["WaldoEcoCore_PromptTheme", _theme];
    _disp setVariable ["WaldoEcoCore_PromptCardControl", _card];
    _disp setVariable ["WaldoEcoCore_PromptHeaderControl", _header];
    _disp setVariable ["WaldoEcoCore_PromptMaxCardBounds", _maxCardBounds];
    _disp setVariable ["WaldoEcoCore_PromptOwnedControls", +_chrome];
    _disp setVariable ["WaldoEcoCore_PromptToken", format ["%1_%2", diag_tickTime, random 1e9]];
    uiNamespace setVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", _disp];
    [_disp] call Waldo_fnc_EcoCore_fitPromptDisplay;
    diag_log format ["[WMP ECO UI] prompt controls attached display=%1 clientOwner=%2", _disp, clientOwner];
    _disp
