/*
 * Author: WaldoTheWarfighter
 * Builds and opens the persistent, multi-tab ZEN "Vehicle Customisation - Editor" dialog for one
 * vehicle - the replacement for the retired one-shot "Configure" / "Copy From Nearby Vehicle" /
 * "Register Component" / "Remove/Restore Component" modules. A curator can queue any number of
 * turret, pylon, appearance, and component changes across four tabs (Turret / Pylon / Appearance /
 * Component) into one permanent Pending Changes RscListbox, visible across every tab, then either
 * apply everything at once or export one ready-to-paste Eden-init-field snippet - the "author here,
 * paste there" beginner workflow.
 *
 * Tab switching: each tab's own controls live inside one RscControlsGroupNoScrollbars container, all
 * four covering the exact same content rectangle. Waldo_fnc_VehCust_setTab changes group visibility
 * after every child exists and deliberately leaves the groups' fitted positions alone. Earlier
 * off-screen positioning polluted the fitter's bounds and later restored an obsolete pre-fit rectangle;
 * the apparent visibility failure was instead caused by stringifying the requested tab name before
 * validating it, which silently forced every request back to Turret.
 *
 * This dialog calls Waldo_fnc_EcoCore_fitPromptDisplay, exactly like every earlier working version -
 * skipping it (tried once) left Waldo_fnc_EcoCore_createZeusPromptDisplay's own background/header chrome
 * stuck at its small unfitted placeholder box, visibly colliding with this dialog's own content, and
 * lost the button font auto-shrink that keeps longer controls readable. The tab widths and visible
 * labels are deliberately sized for the actual text rather than relying on that shrink alone.
 * allControls _disp recurses into every control group's own children, not just this display's
 * direct top-level controls - a group child's ctrlPosition is relative to its own parent group's local
 * origin, not this display's absolute safe-zone coordinates, and treating those small local numbers as
 * absolute corrupted the fit pass's computed bounding box and visibly shifted/clipped this dialog's
 * content. The fitter distinguishes those children with ctrlParentControlsGroup; ctrlParent itself
 * returns the display for ordinary controls and therefore cannot identify nested controls.
 *
 * Reuses Waldo_fnc_EcoCore_createZeusPromptDisplay verbatim for the modal child display's shared
 * chrome/background (it is already generic, no Economy-specific state) and copies control-creation
 * idioms directly from MissionScripts/EconomySystems/Build/promptBuildConfig.sqf. Every Add button
 * routes through its own validation-gated collector (Waldo_fnc_VehCust_collectTurretRow /
 * ..._collectPylonRow / ..._collectAppearanceRow / ..._collectComponentRow) and refuses to push a
 * blank/incomplete row onto Pending - the direct fix for the confirmed root-cause bug in the retired
 * Configure module's Session Action queue (see those files' headers for the full story).
 *
 * Turret/Pylon "Weapon"/"Ordnance" pickers and their pack-wide-catalog population are ported from the
 * retired Zen_vehicleWeaponLoadoutModule.sqf; the Appearance tab's texture-slot discovery is ported
 * from the retired Zen_vehicleAppearanceTextureModule.sqf. The Component tab uses the new
 * Waldo_fnc_VehicleComponentHeuristicScan (live, best-effort auto-discovery) instead of the retired
 * persistent registration catalog.
 *
 * A turret path with no real weapon mount ([-1] on a vehicle whose own CfgVehicles declares no
 * weapons[]) or that is horn-only is excluded from every turret picker entirely (Turret combo, Weapon
 * combo, Component tab's Linked Turret Path combo) - not just labeled - since WMP cannot create a
 * physical mount that doesn't exist and a horn is never a combat weapon. Picking a Weapon repopulates
 * the Magazine combo live from Waldo_fnc_VehicleWeaponLoadoutMagazinesForWeapon (engine compatibility,
 * top-level magazines and named-muzzle magazines), so magazine choices are filtered to what the
 * selected weapon can actually load. The editor only shows controls relevant to the selected action,
 * and solid colour editing uses bounded 0..1 sliders rather than ambiguous free-text values. Every
 * "Type manually" classname edit remains available for exotic modded cases the catalog misses.
 * The shared prompt card is the only outer background; two inset panels and a theme-coloured divider
 * provide hierarchy without drawing a second, mismatched black box over the shared card. Combo-box
 * wheel input is handled and consumed by the combo itself so Zeus cannot also zoom its camera.
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - the vehicle this Editor session edits (the module's placement target).
 *
 * Return Value:
 * DISPLAY - the created dialog display, or displayNull if it could not be created.
 *
 * Example:
 * [_objectPos] call Waldo_fnc_VehCust_promptEditor;
 *
 * Current caller: MissionScripts/ZenModules/Zen_vehicleCustomizationEditorModule.sqf.
 */

params [["_vehicle", objNull, [objNull]]];
if (!hasInterface || {isNull _vehicle}) exitWith {displayNull};

// deferFit=true: this dialog creates far more controls, interleaved with much heavier per-control
// work (catalog scans, a full heuristic component scan), than any Economy prompt Waldo_fnc_EcoCore_
// fitPromptDisplay was tuned against - letting it auto-fit here raced this script's own control
// creation and could snapshot/reposition only a partial control set. Fit explicitly, once, at the
// very end of this file instead, after every control this dialog creates genuinely exists (see this
// file's header for why the fit call itself is still required, not skipped).
private _vehicleDisplayName = getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "displayName");
if (_vehicleDisplayName == "") then {_vehicleDisplayName = typeOf _vehicle};
private _disp = [format ["  WMP  //  VEHICLE CUSTOMISATION  //  %1", toUpperANSI _vehicleDisplayName], true] call Waldo_fnc_EcoCore_createZeusPromptDisplay;
if (isNull _disp) exitWith {displayNull};

_disp setVariable ["WaldoVehCust_Vehicle", _vehicle];
_disp setVariable ["WaldoVehCust_PendingRows", []];

private _isHornWeapon = {
    toLower (getText (configFile >> "CfgWeapons" >> _this >> "displayName")) == "horn"
};
private _maxLabelChars = 64;
private _truncateLabel = {
    params ["_text"];
    if (count _text > _maxLabelChars) then {(_text select [0, _maxLabelChars]) + "…"} else {_text};
};

// ---- Interior hierarchy ----
// The shared card/header created above is the sole outer chrome. These inset panels are created before
// every interactive control so they remain behind the editor content instead of becoming a second
// competing outer box.
private _theme = _disp getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
private _leftPanel = _disp ctrlCreate ["RscText", -1];
_leftPanel ctrlSetPosition [0.09, 0.15, 0.49, 0.66];
_leftPanel ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.035, 0.065, 0.095, 0.99]]);
_leftPanel ctrlCommit 0;

private _rightPanel = _disp ctrlCreate ["RscText", -1];
_rightPanel ctrlSetPosition [0.59, 0.15, 0.32, 0.66];
_rightPanel ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.035, 0.065, 0.095, 0.99]]);
_rightPanel ctrlCommit 0;

private _sectionDivider = _disp ctrlCreate ["RscText", -1];
_sectionDivider ctrlSetPosition [0.09, 0.145, 0.82, 0.004];
_sectionDivider ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.10, 0.46, 0.76, 1]]);
_sectionDivider ctrlCommit 0;

// ---- Tab buttons ----
// Each button is tagged and its ButtonClick handler attached IMMEDIATELY after creation, here, rather
// than in one block at the end of this ~750-line script (as every other button in this dialog still
// is). If anything later in this script throws (a bad config read against an unusual vehicle, for
// instance), every handler that was still waiting to be attached at the end would simply never exist -
// the buttons would still be visibly created and rendered (since they're created early), but would be
// completely inert to every click, which matches exactly what live testing reported: tab buttons that
// visibly exist but do nothing at all when clicked. Attaching tab switching's own handlers this early
// makes it independent of every other line in this file succeeding.
private _tabTurretBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabTurretBtn ctrlSetPosition [0.10, 0.11, 0.105, 0.035];
_tabTurretBtn ctrlSetText "Turret";
_tabTurretBtn ctrlSetFontHeight 0.026;
_tabTurretBtn ctrlCommit 0;
_tabTurretBtn setVariable ["WaldoVehCust_Display", _disp];
_tabTurretBtn setVariable ["WaldoVehCust_TabName", "turret"];
_tabTurretBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    [_disp, _ctrl getVariable ["WaldoVehCust_TabName", "turret"]] call Waldo_fnc_VehCust_setTab;
}];

private _tabPylonBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabPylonBtn ctrlSetPosition [0.21, 0.11, 0.10, 0.035];
_tabPylonBtn ctrlSetText "Pylon";
_tabPylonBtn ctrlSetFontHeight 0.026;
_tabPylonBtn ctrlCommit 0;
_tabPylonBtn setVariable ["WaldoVehCust_Display", _disp];
_tabPylonBtn setVariable ["WaldoVehCust_TabName", "pylon"];
_tabPylonBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    [_disp, _ctrl getVariable ["WaldoVehCust_TabName", "turret"]] call Waldo_fnc_VehCust_setTab;
}];

private _tabAppearanceBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabAppearanceBtn ctrlSetPosition [0.32, 0.11, 0.125, 0.035];
_tabAppearanceBtn ctrlSetText "Appearance";
_tabAppearanceBtn ctrlSetFontHeight 0.026;
_tabAppearanceBtn ctrlCommit 0;
_tabAppearanceBtn setVariable ["WaldoVehCust_Display", _disp];
_tabAppearanceBtn setVariable ["WaldoVehCust_TabName", "appearance"];
_tabAppearanceBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    [_disp, _ctrl getVariable ["WaldoVehCust_TabName", "turret"]] call Waldo_fnc_VehCust_setTab;
}];

private _tabComponentBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabComponentBtn ctrlSetPosition [0.45, 0.11, 0.13, 0.035];
_tabComponentBtn ctrlSetText "Component";
_tabComponentBtn ctrlSetFontHeight 0.026;
_tabComponentBtn ctrlCommit 0;
_tabComponentBtn setVariable ["WaldoVehCust_Display", _disp];
_tabComponentBtn setVariable ["WaldoVehCust_TabName", "component"];
_tabComponentBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    [_disp, _ctrl getVariable ["WaldoVehCust_TabName", "turret"]] call Waldo_fnc_VehCust_setTab;
}];

// ---- One content group per tab - all four share the exact same rectangle. Local coordinates below
// are relative to each group's own [0, 0] origin, not the display's absolute safe-zone coordinates
// (confirmed correct: excluding these children from Waldo_fnc_EcoCore_fitPromptDisplay's own scan -
// see that file - fixed a real corrupted-position bug, which only makes sense if children really do
// render relative to their parent group's current position).
//
// Every group remains visible while its children are created. Once construction is complete,
// Waldo_fnc_VehCust_setTab hides the inactive groups without changing their fitted positions.
private _tabContentX = 0.10;
private _tabContentY = 0.16;
private _tabContentW = 0.46;
private _tabContentH = 0.62;
private _turretGroup = _disp ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_turretGroup ctrlSetPosition [_tabContentX, _tabContentY, _tabContentW, _tabContentH];
_turretGroup ctrlShow true;
_turretGroup ctrlCommit 0;

private _pylonGroup = _disp ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_pylonGroup ctrlSetPosition [_tabContentX, _tabContentY, _tabContentW, _tabContentH];
_pylonGroup ctrlShow true;
_pylonGroup ctrlCommit 0;

private _appearanceGroup = _disp ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_appearanceGroup ctrlSetPosition [_tabContentX, _tabContentY, _tabContentW, _tabContentH];
_appearanceGroup ctrlShow true;
_appearanceGroup ctrlCommit 0;

private _componentGroup = _disp ctrlCreate ["RscControlsGroupNoScrollbars", -1];
_componentGroup ctrlSetPosition [_tabContentX, _tabContentY, _tabContentW, _tabContentH];
_componentGroup ctrlShow true;
_componentGroup ctrlCommit 0;

// ==== Turret tab (children of _turretGroup - positions relative to the group's own [0,0]) ====
private _turretLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_turretLabel ctrlSetPosition [0, 0, 0.36, 0.025];
_turretLabel ctrlSetText "Turret";
_turretLabel ctrlCommit 0;

private _turretCombo = _disp ctrlCreate ["RscCombo", -1, _turretGroup];
_turretCombo ctrlSetPosition [0, 0.03, 0.46, 0.035];
_turretCombo ctrlCommit 0;

private _turretActionLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_turretActionLabel ctrlSetPosition [0, 0.08, 0.36, 0.025];
_turretActionLabel ctrlSetText "Action";
_turretActionLabel ctrlCommit 0;

private _turretActionCombo = _disp ctrlCreate ["RscCombo", -1, _turretGroup];
_turretActionCombo ctrlSetPosition [0, 0.11, 0.30, 0.035];
_turretActionCombo ctrlCommit 0;

private _copyWeaponLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_copyWeaponLabel ctrlSetPosition [0, 0.16, 0.46, 0.025];
_copyWeaponLabel ctrlSetText "Weapon";
_copyWeaponLabel ctrlSetTooltip "Pick a weapon already on this vehicle or from the loaded pack-wide catalog.";
_copyWeaponLabel ctrlCommit 0;

private _copyWeaponCombo = _disp ctrlCreate ["RscCombo", -1, _turretGroup];
_copyWeaponCombo ctrlSetPosition [0, 0.19, 0.46, 0.035];
_copyWeaponCombo ctrlCommit 0;

private _turretWeaponLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_turretWeaponLabel ctrlSetPosition [0, 0.24, 0.46, 0.025];
_turretWeaponLabel ctrlSetText "Weapon Classname (manual / advanced)";
_turretWeaponLabel ctrlSetTooltip "Used only when Type manually is selected above.";
_turretWeaponLabel ctrlCommit 0;

private _turretWeaponEdit = _disp ctrlCreate ["RscEdit", -1, _turretGroup];
_turretWeaponEdit ctrlSetPosition [0, 0.27, 0.46, 0.035];
_turretWeaponEdit ctrlCommit 0;

private _copyMagazineLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_copyMagazineLabel ctrlSetPosition [0, 0.32, 0.46, 0.025];
_copyMagazineLabel ctrlSetText "Magazine (compatible with selected weapon)";
_copyMagazineLabel ctrlSetTooltip "Only magazines resolved for the selected weapon are listed.";
_copyMagazineLabel ctrlCommit 0;

private _copyMagazineCombo = _disp ctrlCreate ["RscCombo", -1, _turretGroup];
_copyMagazineCombo ctrlSetPosition [0, 0.35, 0.46, 0.035];
_copyMagazineCombo ctrlCommit 0;

private _turretMagLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_turretMagLabel ctrlSetPosition [0, 0.40, 0.46, 0.025];
_turretMagLabel ctrlSetText "Magazine Classname (manual / advanced)";
_turretMagLabel ctrlSetTooltip "Used only when Type manually is selected above.";
_turretMagLabel ctrlCommit 0;

private _turretMagEdit = _disp ctrlCreate ["RscEdit", -1, _turretGroup];
_turretMagEdit ctrlSetPosition [0, 0.43, 0.46, 0.035];
_turretMagEdit ctrlCommit 0;

private _turretCountLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_turretCountLabel ctrlSetPosition [0, 0.48, 0.22, 0.025];
_turretCountLabel ctrlSetText "Rounds/Magazine";
_turretCountLabel ctrlCommit 0;

private _turretCountEdit = _disp ctrlCreate ["RscEdit", -1, _turretGroup];
_turretCountEdit ctrlSetPosition [0, 0.51, 0.20, 0.035];
_turretCountEdit ctrlSetText "30";
_turretCountEdit ctrlCommit 0;

private _turretQtyLabel = _disp ctrlCreate ["RscText", -1, _turretGroup];
_turretQtyLabel ctrlSetPosition [0.22, 0.48, 0.22, 0.025];
_turretQtyLabel ctrlSetText "Magazine Count";
_turretQtyLabel ctrlCommit 0;

private _turretQtyEdit = _disp ctrlCreate ["RscEdit", -1, _turretGroup];
_turretQtyEdit ctrlSetPosition [0.22, 0.51, 0.20, 0.035];
_turretQtyEdit ctrlSetText "1";
_turretQtyEdit ctrlCommit 0;

private _addTurretBtn = _disp ctrlCreate ["RscButtonMenu", -1, _turretGroup];
_addTurretBtn ctrlSetPosition [0, 0.57, 0.20, 0.04];
_addTurretBtn ctrlSetText "Queue Weapon Change";
_addTurretBtn ctrlCommit 0;

// ==== Pylon tab (children of _pylonGroup) ====
private _pylonLabel = _disp ctrlCreate ["RscText", -1, _pylonGroup];
_pylonLabel ctrlSetPosition [0, 0, 0.36, 0.025];
_pylonLabel ctrlSetText "Pylon";
_pylonLabel ctrlCommit 0;

private _pylonCombo = _disp ctrlCreate ["RscCombo", -1, _pylonGroup];
_pylonCombo ctrlSetPosition [0, 0.03, 0.46, 0.035];
_pylonCombo ctrlCommit 0;

private _pylonActionLabel = _disp ctrlCreate ["RscText", -1, _pylonGroup];
_pylonActionLabel ctrlSetPosition [0, 0.08, 0.36, 0.025];
_pylonActionLabel ctrlSetText "Action";
_pylonActionLabel ctrlCommit 0;

private _pylonActionCombo = _disp ctrlCreate ["RscCombo", -1, _pylonGroup];
_pylonActionCombo ctrlSetPosition [0, 0.11, 0.30, 0.035];
_pylonActionCombo ctrlCommit 0;

private _copyOrdnanceLabel = _disp ctrlCreate ["RscText", -1, _pylonGroup];
_copyOrdnanceLabel ctrlSetPosition [0, 0.16, 0.46, 0.025];
_copyOrdnanceLabel ctrlSetText "Ordnance";
_copyOrdnanceLabel ctrlSetTooltip "Pick ordnance already fitted to this vehicle or from the loaded pack-wide catalog.";
_copyOrdnanceLabel ctrlCommit 0;

private _copyOrdnanceCombo = _disp ctrlCreate ["RscCombo", -1, _pylonGroup];
_copyOrdnanceCombo ctrlSetPosition [0, 0.19, 0.46, 0.035];
_copyOrdnanceCombo ctrlCommit 0;

private _pylonMagLabel = _disp ctrlCreate ["RscText", -1, _pylonGroup];
_pylonMagLabel ctrlSetPosition [0, 0.24, 0.46, 0.025];
_pylonMagLabel ctrlSetText "Ordnance Classname (manual / advanced)";
_pylonMagLabel ctrlCommit 0;

private _pylonMagEdit = _disp ctrlCreate ["RscEdit", -1, _pylonGroup];
_pylonMagEdit ctrlSetPosition [0, 0.27, 0.46, 0.035];
_pylonMagEdit ctrlCommit 0;

private _pylonAmmoLabel = _disp ctrlCreate ["RscText", -1, _pylonGroup];
_pylonAmmoLabel ctrlSetPosition [0, 0.32, 0.46, 0.025];
_pylonAmmoLabel ctrlSetText "Ammo Override (0 = full magazine count)";
_pylonAmmoLabel ctrlCommit 0;

private _pylonAmmoEdit = _disp ctrlCreate ["RscEdit", -1, _pylonGroup];
_pylonAmmoEdit ctrlSetPosition [0, 0.35, 0.20, 0.035];
_pylonAmmoEdit ctrlSetText "0";
_pylonAmmoEdit ctrlCommit 0;

private _addPylonBtn = _disp ctrlCreate ["RscButtonMenu", -1, _pylonGroup];
_addPylonBtn ctrlSetPosition [0, 0.49, 0.20, 0.04];
_addPylonBtn ctrlSetText "Add Pylon Row";
_addPylonBtn ctrlCommit 0;

// ==== Appearance tab (children of _appearanceGroup) ====
private _slotLabel = _disp ctrlCreate ["RscText", -1, _appearanceGroup];
_slotLabel ctrlSetPosition [0, 0, 0.36, 0.025];
_slotLabel ctrlSetText "Texture Slot";
_slotLabel ctrlCommit 0;

private _slotCombo = _disp ctrlCreate ["RscCombo", -1, _appearanceGroup];
_slotCombo ctrlSetPosition [0, 0.03, 0.46, 0.035];
_slotCombo ctrlCommit 0;

private _modeLabel = _disp ctrlCreate ["RscText", -1, _appearanceGroup];
_modeLabel ctrlSetPosition [0, 0.08, 0.36, 0.025];
_modeLabel ctrlSetText "Mode";
_modeLabel ctrlCommit 0;

private _modeCombo = _disp ctrlCreate ["RscCombo", -1, _appearanceGroup];
_modeCombo ctrlSetPosition [0, 0.11, 0.30, 0.035];
_modeCombo ctrlCommit 0;

private _rgbaLabel = _disp ctrlCreate ["RscText", -1, _appearanceGroup];
_rgbaLabel ctrlSetPosition [0, 0.16, 0.46, 0.025];
_rgbaLabel ctrlSetText "Solid Colour (each channel ranges from 0 to 1)";
_rgbaLabel ctrlCommit 0;

private _makeColourSlider = {
    params ["_labelText", "_y", "_initialValue"];
    private _label = _disp ctrlCreate ["RscText", -1, _appearanceGroup];
    _label ctrlSetPosition [0, _y, 0.03, 0.035];
    _label ctrlSetText _labelText;
    _label ctrlCommit 0;

    private _slider = _disp ctrlCreate ["RscXSliderH", -1, _appearanceGroup];
    _slider ctrlSetPosition [0.035, _y, 0.34, 0.035];
    _slider sliderSetRange [0, 1];
    _slider sliderSetSpeed [0.01, 0.1];
    _slider sliderSetPosition _initialValue;
    _slider ctrlCommit 0;

    private _value = _disp ctrlCreate ["RscText", -1, _appearanceGroup];
    _value ctrlSetPosition [0.385, _y, 0.07, 0.035];
    _value ctrlSetText (_initialValue toFixed 2);
    _value ctrlSetTextColor [0.85, 0.9, 0.95, 1];
    _value ctrlCommit 0;
    _slider setVariable ["WaldoVehCust_ValueControl", _value];
    _slider ctrlAddEventHandler ["SliderPosChanged", {
        params ["_control", "_sliderValue"];
        private _valueControl = _control getVariable ["WaldoVehCust_ValueControl", controlNull];
        if (!isNull _valueControl) then {_valueControl ctrlSetText (_sliderValue toFixed 2)};
    }];
    [_label, _slider, _value]
};
private _redControls = ["R", 0.19, 1] call _makeColourSlider;
private _greenControls = ["G", 0.24, 0] call _makeColourSlider;
private _blueControls = ["B", 0.29, 1] call _makeColourSlider;
private _alphaControls = ["A", 0.34, 1] call _makeColourSlider;
private _redSlider = _redControls select 1;
private _greenSlider = _greenControls select 1;
private _blueSlider = _blueControls select 1;
private _alphaSlider = _alphaControls select 1;

private _pathLabel = _disp ctrlCreate ["RscText", -1, _appearanceGroup];
_pathLabel ctrlSetPosition [0, 0.39, 0.46, 0.025];
_pathLabel ctrlSetText "Custom Texture Path";
_pathLabel ctrlSetTooltip "Mission-relative path, mod path, or procedural texture string.";
_pathLabel ctrlCommit 0;

private _pathEdit = _disp ctrlCreate ["RscEdit", -1, _appearanceGroup];
_pathEdit ctrlSetPosition [0, 0.42, 0.46, 0.035];
_pathEdit ctrlCommit 0;

private _addAppearanceBtn = _disp ctrlCreate ["RscButtonMenu", -1, _appearanceGroup];
_addAppearanceBtn ctrlSetPosition [0, 0.49, 0.24, 0.04];
_addAppearanceBtn ctrlSetText "Add Appearance Row";
_addAppearanceBtn ctrlCommit 0;

// ==== Component tab (children of _componentGroup) ====
private _componentPickLabel = _disp ctrlCreate ["RscText", -1, _componentGroup];
_componentPickLabel ctrlSetPosition [0, 0, 0.46, 0.025];
_componentPickLabel ctrlSetText "Heuristic Candidate (best-effort - verify, or type manually below)";
_componentPickLabel ctrlCommit 0;

private _componentPickCombo = _disp ctrlCreate ["RscCombo", -1, _componentGroup];
_componentPickCombo ctrlSetPosition [0, 0.03, 0.46, 0.035];
_componentPickCombo ctrlCommit 0;

private _componentSelLabel = _disp ctrlCreate ["RscText", -1, _componentGroup];
_componentSelLabel ctrlSetPosition [0, 0.08, 0.36, 0.025];
_componentSelLabel ctrlSetText "Selection Name";
_componentSelLabel ctrlCommit 0;

private _componentSelEdit = _disp ctrlCreate ["RscEdit", -1, _componentGroup];
_componentSelEdit ctrlSetPosition [0, 0.11, 0.46, 0.035];
_componentSelEdit ctrlCommit 0;

private _componentTurretPickLabel = _disp ctrlCreate ["RscText", -1, _componentGroup];
_componentTurretPickLabel ctrlSetPosition [0, 0.16, 0.46, 0.025];
_componentTurretPickLabel ctrlSetText "Linked Turret Path (optional - pick, or type manually below)";
_componentTurretPickLabel ctrlCommit 0;

private _componentTurretPickCombo = _disp ctrlCreate ["RscCombo", -1, _componentGroup];
_componentTurretPickCombo ctrlSetPosition [0, 0.19, 0.46, 0.035];
_componentTurretPickCombo ctrlCommit 0;

private _componentTurretLabel = _disp ctrlCreate ["RscText", -1, _componentGroup];
_componentTurretLabel ctrlSetPosition [0, 0.24, 0.46, 0.025];
_componentTurretLabel ctrlSetText "Linked Turret Path Classname (advanced, e.g. [0] or [-1])";
_componentTurretLabel ctrlCommit 0;

private _componentTurretEdit = _disp ctrlCreate ["RscEdit", -1, _componentGroup];
_componentTurretEdit ctrlSetPosition [0, 0.27, 0.46, 0.035];
_componentTurretEdit ctrlCommit 0;

private _componentActionLabel = _disp ctrlCreate ["RscText", -1, _componentGroup];
_componentActionLabel ctrlSetPosition [0, 0.32, 0.36, 0.025];
_componentActionLabel ctrlSetText "Action";
_componentActionLabel ctrlCommit 0;

private _componentActionCombo = _disp ctrlCreate ["RscCombo", -1, _componentGroup];
_componentActionCombo ctrlSetPosition [0, 0.35, 0.30, 0.035];
_componentActionCombo ctrlCommit 0;

private _addComponentBtn = _disp ctrlCreate ["RscButtonMenu", -1, _componentGroup];
_addComponentBtn ctrlSetPosition [0, 0.49, 0.24, 0.04];
_addComponentBtn ctrlSetText "Add Component Row";
_addComponentBtn ctrlCommit 0;

// ==== Permanent Pending Changes panel (right side, all tabs - stays top-level on _disp, outside
// every tab group, since it must remain visible regardless of which tab is active) ====
private _pendingLabel = _disp ctrlCreate ["RscText", -1];
_pendingLabel ctrlSetPosition [0.60, 0.16, 0.30, 0.025];
_pendingLabel ctrlSetText "Pending Changes";
_pendingLabel ctrlCommit 0;

private _pendingList = _disp ctrlCreate ["RscListbox", -1];
_pendingList ctrlSetPosition [0.60, 0.19, 0.30, 0.42];
_pendingList ctrlCommit 0;

private _removeSelectedBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_removeSelectedBtn ctrlSetPosition [0.60, 0.62, 0.30, 0.035];
_removeSelectedBtn ctrlSetText "Remove Selected";
_removeSelectedBtn ctrlSetTooltip "Remove the selected row from Pending Changes without applying it.";
_removeSelectedBtn ctrlCommit 0;

private _copyFromBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_copyFromBtn ctrlSetPosition [0.60, 0.66, 0.30, 0.035];
_copyFromBtn ctrlSetText "Copy From Nearby";
_copyFromBtn ctrlCommit 0;

private _applyAllBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_applyAllBtn ctrlSetPosition [0.60, 0.70, 0.30, 0.035];
_applyAllBtn ctrlSetText "Apply Pending Changes";
_applyAllBtn ctrlCommit 0;

private _exportBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_exportBtn ctrlSetPosition [0.60, 0.74, 0.30, 0.035];
_exportBtn ctrlSetText "Export Setup";
_exportBtn ctrlSetTooltip "Copy every pending row as a ready-to-paste Eden init call.";
_exportBtn ctrlCommit 0;

private _clearAllBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_clearAllBtn ctrlSetPosition [0.60, 0.78, 0.30, 0.035];
_clearAllBtn ctrlSetText "Clear Pending Changes";
_clearAllBtn ctrlCommit 0;

private _okBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_okBtn ctrlSetPosition [0.60, 0.87, 0.30, 0.04];
_okBtn ctrlSetText "Ok / Close";
_okBtn ctrlCommit 0;

// ==== Hidden "Copy From Nearby Vehicle" overlay ====
private _copyOverlayBg = _disp ctrlCreate ["RscText", -1];
_copyOverlayBg ctrlSetPosition [0.28, 0.30, 0.44, 0.42];
_copyOverlayBg ctrlSetBackgroundColor [0, 0, 0, 0.95];
_copyOverlayBg ctrlShow false;
_copyOverlayBg ctrlCommit 0;

private _copyOverlayLabel = _disp ctrlCreate ["RscText", -1];
_copyOverlayLabel ctrlSetPosition [0.30, 0.32, 0.40, 0.03];
_copyOverlayLabel ctrlSetText "Pick a nearby vehicle to copy its turret/pylon loadout from:";
_copyOverlayLabel ctrlShow false;
_copyOverlayLabel ctrlCommit 0;

private _copyOverlayList = _disp ctrlCreate ["RscListbox", -1];
_copyOverlayList ctrlSetPosition [0.30, 0.36, 0.40, 0.28];
_copyOverlayList ctrlShow false;
_copyOverlayList ctrlCommit 0;

private _copyOverlayPickBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_copyOverlayPickBtn ctrlSetPosition [0.30, 0.65, 0.19, 0.04];
_copyOverlayPickBtn ctrlSetText "Copy Into Pending";
_copyOverlayPickBtn ctrlShow false;
_copyOverlayPickBtn ctrlCommit 0;

private _copyOverlayCancelBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_copyOverlayCancelBtn ctrlSetPosition [0.51, 0.65, 0.19, 0.04];
_copyOverlayCancelBtn ctrlSetText "Cancel";
_copyOverlayCancelBtn ctrlShow false;
_copyOverlayCancelBtn ctrlCommit 0;

// ---- Store control refs for cross-file/handler lookup ----
_disp setVariable ["WaldoVehCust_TurretCombo", _turretCombo];
_disp setVariable ["WaldoVehCust_TurretActionCombo", _turretActionCombo];
_disp setVariable ["WaldoVehCust_CopyWeaponCombo", _copyWeaponCombo];
_disp setVariable ["WaldoVehCust_TurretWeaponEdit", _turretWeaponEdit];
_disp setVariable ["WaldoVehCust_CopyMagazineCombo", _copyMagazineCombo];
_disp setVariable ["WaldoVehCust_TurretMagazineEdit", _turretMagEdit];
_disp setVariable ["WaldoVehCust_TurretCountEdit", _turretCountEdit];
_disp setVariable ["WaldoVehCust_TurretQuantityEdit", _turretQtyEdit];

_disp setVariable ["WaldoVehCust_PylonCombo", _pylonCombo];
_disp setVariable ["WaldoVehCust_PylonActionCombo", _pylonActionCombo];
_disp setVariable ["WaldoVehCust_CopyOrdnanceCombo", _copyOrdnanceCombo];
_disp setVariable ["WaldoVehCust_PylonMagazineEdit", _pylonMagEdit];
_disp setVariable ["WaldoVehCust_PylonAmmoEdit", _pylonAmmoEdit];

_disp setVariable ["WaldoVehCust_TextureSlotCombo", _slotCombo];
_disp setVariable ["WaldoVehCust_TextureModeCombo", _modeCombo];
_disp setVariable ["WaldoVehCust_TextureRedSlider", _redSlider];
_disp setVariable ["WaldoVehCust_TextureGreenSlider", _greenSlider];
_disp setVariable ["WaldoVehCust_TextureBlueSlider", _blueSlider];
_disp setVariable ["WaldoVehCust_TextureAlphaSlider", _alphaSlider];
_disp setVariable ["WaldoVehCust_TexturePathEdit", _pathEdit];

// Control families used by Waldo_fnc_VehCust_refreshRelevantControls. Keeping these groups here,
// next to their actual controls, makes mode/action visibility explicit and repeat-safe.
_disp setVariable ["WaldoVehCust_TurretWeaponPickerControls", [_copyWeaponLabel, _copyWeaponCombo]];
_disp setVariable ["WaldoVehCust_TurretManualWeaponControls", [_turretWeaponLabel, _turretWeaponEdit]];
_disp setVariable ["WaldoVehCust_TurretMagazinePickerControls", [_copyMagazineLabel, _copyMagazineCombo]];
_disp setVariable ["WaldoVehCust_TurretManualMagazineControls", [_turretMagLabel, _turretMagEdit]];
_disp setVariable ["WaldoVehCust_TurretAmmoControls", [_turretCountLabel, _turretCountEdit, _turretQtyLabel, _turretQtyEdit]];
_disp setVariable ["WaldoVehCust_PylonPickerControls", [_copyOrdnanceLabel, _copyOrdnanceCombo]];
_disp setVariable ["WaldoVehCust_PylonManualControls", [_pylonMagLabel, _pylonMagEdit]];
_disp setVariable ["WaldoVehCust_PylonAmmoControls", [_pylonAmmoLabel, _pylonAmmoEdit]];
_disp setVariable ["WaldoVehCust_ColourControls", [_rgbaLabel] + _redControls + _greenControls + _blueControls + _alphaControls];
_disp setVariable ["WaldoVehCust_TexturePathControls", [_pathLabel, _pathEdit]];
_disp setVariable ["WaldoVehCust_ComponentTurretControls", [_componentTurretPickLabel, _componentTurretPickCombo, _componentTurretLabel, _componentTurretEdit]];

_disp setVariable ["WaldoVehCust_ComponentPickCombo", _componentPickCombo];
_disp setVariable ["WaldoVehCust_ComponentSelectionEdit", _componentSelEdit];
_disp setVariable ["WaldoVehCust_ComponentTurretPickCombo", _componentTurretPickCombo];
_disp setVariable ["WaldoVehCust_ComponentTurretEdit", _componentTurretEdit];
_disp setVariable ["WaldoVehCust_ComponentActionCombo", _componentActionCombo];

_disp setVariable ["WaldoVehCust_PendingList", _pendingList];
_disp setVariable ["WaldoVehCust_TabTurretBtn", _tabTurretBtn];
_disp setVariable ["WaldoVehCust_TabPylonBtn", _tabPylonBtn];
_disp setVariable ["WaldoVehCust_TabAppearanceBtn", _tabAppearanceBtn];
_disp setVariable ["WaldoVehCust_TabComponentBtn", _tabComponentBtn];

// Tab content groups - Waldo_fnc_VehCust_setTab toggles visibility on exactly these four controls.
_disp setVariable ["WaldoVehCust_TurretGroup", _turretGroup];
_disp setVariable ["WaldoVehCust_PylonGroup", _pylonGroup];
_disp setVariable ["WaldoVehCust_AppearanceGroup", _appearanceGroup];
_disp setVariable ["WaldoVehCust_ComponentGroup", _componentGroup];

_disp setVariable ["WaldoVehCust_CopyOverlayBg", _copyOverlayBg];
_disp setVariable ["WaldoVehCust_CopyOverlayLabel", _copyOverlayLabel];
_disp setVariable ["WaldoVehCust_CopyOverlayList", _copyOverlayList];
_disp setVariable ["WaldoVehCust_CopyOverlayPickBtn", _copyOverlayPickBtn];
_disp setVariable ["WaldoVehCust_CopyOverlayCancelBtn", _copyOverlayCancelBtn];

// Tab buttons are already tagged and their ButtonClick handlers already attached at creation time
// above - not included in this list.
{
    _x setVariable ["WaldoVehCust_Display", _disp];
} forEach [
    _addTurretBtn, _addPylonBtn, _addAppearanceBtn, _addComponentBtn,
    _removeSelectedBtn, _copyFromBtn, _applyAllBtn, _exportBtn, _clearAllBtn, _okBtn,
    _turretActionCombo, _pylonActionCombo, _modeCombo, _componentActionCombo,
    _copyWeaponCombo, _copyMagazineCombo, _copyOrdnanceCombo,
    _componentPickCombo, _componentTurretPickCombo,
    _copyOverlayPickBtn, _copyOverlayCancelBtn
];

// ---- Populate Turret tab live data ----
// Mount-less ([-1] with no real weapons[] entry on this vehicle's own root config) and horn-only
// turret paths are excluded from selection entirely, not just labeled - WMP cannot create a physical
// weapon mount that doesn't exist, and a horn is never a combat weapon a curator means to touch.
// Matches the exact exclusion Waldo_fnc_VehicleComponentHeuristicScan already performs.
private _allTurretPaths = [[-1]] + (allTurrets [_vehicle, true]);
private _mainSlotHasMount = count (getArray (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "weapons")) > 0;
private _turretPaths = _allTurretPaths select {
    private _path = _x;
    private _current = _vehicle weaponsTurret _path;
    private _isHornOnly = count _current > 0 && {(_current select {!(_x call _isHornWeapon)}) isEqualTo []};
    private _isMountless = _path isEqualTo [-1] && {!_mainSlotHasMount};
    !_isHornOnly && {!_isMountless}
};
_disp setVariable ["WaldoVehCust_EditableTurretPaths", _turretPaths];
if (count _turretPaths > 0) then {
    {
        private _path = _x;
        private _current = _vehicle weaponsTurret _path;
        private _currentText = if (count _current > 0) then {
            (_current apply {getText (configFile >> "CfgWeapons" >> _x >> "displayName")}) joinString ", "
        } else {"empty"};
        private _label = [format ["Turret %1 - %2", _path, _currentText]] call _truncateLabel;
        private _index = _turretCombo lbAdd _label;
        _turretCombo lbSetData [_index, str _path];
    } forEach _turretPaths;
} else {
    private _index = _turretCombo lbAdd "No editable turret positions on this vehicle";
    _turretCombo lbSetData [_index, "-1"];
};
_turretCombo lbSetCurSel 0;

{
    _turretActionCombo lbAdd _x;
} forEach ["Add Weapon", "Replace Turret", "Remove Weapon", "Clear Turret"];
_turretActionCombo lbSetCurSel 0;

private _turretCatalog = missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_TurretCatalog", []];
private _catalogDisplayCap = 150;
private _pickupKeys = ["MANUAL"];
private _pickupLabels = ["Manual / advanced entry"];
private _pickupTooltips = ["Enter weapon and magazine classnames yourself."];
{
    private _path = _x;
    private _weapons = _vehicle weaponsTurret _path;
    private _rawMagazines = _vehicle magazinesTurret _path;
    private _magazines = _rawMagazines arrayIntersect _rawMagazines;
    {
        private _weaponClass = _x;
        private _allowedMagazines = ([_weaponClass] call Waldo_fnc_VehicleWeaponLoadoutMagazinesForWeapon) apply {_x select 0};
        private _compatible = _magazines select {_x in _allowedMagazines};
        private _magForPickup = _compatible param [0, _allowedMagazines param [0, ""]];
        private _magCount = if (_magForPickup == "") then {1} else {getNumber (configFile >> "CfgMagazines" >> _magForPickup >> "count")};
        private _magQuantity = ({_x == _magForPickup} count _rawMagazines) max 1;
        private _key = str [_weaponClass, _magForPickup, _magCount, _magQuantity];
        if !(_key in _pickupKeys) then {
            private _weaponName = getText (configFile >> "CfgWeapons" >> _weaponClass >> "displayName");
            if (_weaponName == "") then {_weaponName = _weaponClass};
            private _magazineName = if (_magForPickup == "") then {"No magazine"} else {getText (configFile >> "CfgMagazines" >> _magForPickup >> "displayName")};
            if (_magazineName == "") then {_magazineName = _magForPickup};
            _pickupKeys pushBack _key;
            _pickupLabels pushBack ([format ["%1  |  %2x %3", _weaponName, _magQuantity, _magazineName]] call _truncateLabel);
            _pickupTooltips pushBack format ["Weapon: %1 | Magazine: %2 | Turret: %3", _weaponClass, if (_magForPickup == "") then {"none"} else {_magForPickup}, _path];
        };
    } forEach _weapons;
} forEach _turretPaths;
{
    _x params ["_weaponClass", "_displayName"];
    private _resolvedMagazines = ([_weaponClass] call Waldo_fnc_VehicleWeaponLoadoutMagazinesForWeapon) apply {_x select 0};
    private _magForPickup = _resolvedMagazines param [0, ""];
    private _magCount = if (_magForPickup == "") then {1} else {getNumber (configFile >> "CfgMagazines" >> _magForPickup >> "count")};
    private _key = str [_weaponClass, _magForPickup, _magCount, 1];
    if !(_key in _pickupKeys) then {
        _pickupKeys pushBack _key;
        _pickupLabels pushBack ([format ["%1  |  Pack-wide", _displayName]] call _truncateLabel);
        _pickupTooltips pushBack format ["Weapon: %1 | Default compatible magazine: %2", _weaponClass, if (_magForPickup == "") then {"none"} else {_magForPickup}];
    };
} forEach (_turretCatalog select [0, _catalogDisplayCap min (count _turretCatalog)]);
if (count _turretCatalog == 0) then {
    _pickupLabels set [0, "Manual / advanced (catalog building)"];
};
{
    private _index = _copyWeaponCombo lbAdd (_pickupLabels select _forEachIndex);
    _copyWeaponCombo lbSetData [_index, _x];
    _copyWeaponCombo lbSetTooltip [_index, _pickupTooltips param [_forEachIndex, _x]];
} forEach _pickupKeys;
_copyWeaponCombo lbSetCurSel 0;

// Magazine combo starts with only "Type manually" - it is (re)populated live from the currently
// selected Weapon via Waldo_fnc_VehicleWeaponLoadoutMagazinesForWeapon (a pure CfgWeapons >>
// "magazines" config read, so it works even for a weapon typed by hand, as long as that weapon
// class is real). See the Weapon combo's LBSelChanged handler below.
_copyMagazineCombo lbAdd "Manual / advanced entry";
_copyMagazineCombo lbSetData [0, "MANUAL"];
_copyMagazineCombo lbSetCurSel 0;

// ---- Populate Pylon tab live data ----
private _pylonCount = count (getPylonMagazines _vehicle);
private _currentPylonMags = [];
if (_pylonCount > 0) then {
    private _pylonClasses = (configProperties [
        configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "Components" >> "TransportPylonsComponent" >> "Pylons",
        "isClass _x"
    ]) apply {configName _x};
    _currentPylonMags = getPylonMagazines _vehicle;
    for "_i" from 0 to (_pylonCount - 1) do {
        private _pylonName = if (_i < count _pylonClasses) then {
            getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> (_pylonClasses select _i) >> "displayName")
        } else {""};
        if (_pylonName == "") then {_pylonName = format ["Pylon %1", _i + 1];};
        private _current = _currentPylonMags param [_i, ""];
        private _label = [format ["%1 - %2", _pylonName, if (_current == "") then {"empty"} else {_current}]] call _truncateLabel;
        private _index = _pylonCombo lbAdd _label;
        _pylonCombo lbSetData [_index, str (_i + 1)];
    };
    _pylonCombo lbSetCurSel 0;
} else {
    private _index = _pylonCombo lbAdd "No pylons on this vehicle";
    _pylonCombo lbSetData [_index, "-1"];
};

{
    _pylonActionCombo lbAdd _x;
} forEach ["Set Ordnance", "Clear Pylon"];
_pylonActionCombo lbSetCurSel 0;

private _pylonCatalog = missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_PylonCatalog", []];
private _ordnanceKeys = ["MANUAL"];
private _ordnanceLabels = ["Manual / advanced entry"];
{
    if (_x != "" && {!(_x in _ordnanceKeys)}) then {
        _ordnanceKeys pushBack _x;
        _ordnanceLabels pushBack ([format ["%1 (currently mounted)", _x]] call _truncateLabel);
    };
} forEach _currentPylonMags;
{
    _x params ["_magazineClass", "_displayName"];
    if !(_magazineClass in _ordnanceKeys) then {
        _ordnanceKeys pushBack _magazineClass;
        _ordnanceLabels pushBack ([format ["%1 (%2) [pack-wide]", _displayName, _magazineClass]] call _truncateLabel);
    };
} forEach (_pylonCatalog select [0, _catalogDisplayCap min (count _pylonCatalog)]);
if (count _pylonCatalog == 0 && {count _currentPylonMags == 0}) then {
    _ordnanceLabels set [0, "Type manually (pack-wide catalog still building - reopen shortly)"];
};
{
    private _index = _copyOrdnanceCombo lbAdd (_ordnanceLabels select _forEachIndex);
    _copyOrdnanceCombo lbSetData [_index, _x];
} forEach _ordnanceKeys;
_copyOrdnanceCombo lbSetCurSel 0;

// ---- Populate Appearance tab live data ----
private _hiddenSelections = getArray (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "hiddenSelections");
if (count _hiddenSelections > 0) then {
    // Arma 3 2.20+ accepts an index array here and returns the requested texture slots in that order.
    private _currentTextures = _vehicle getObjectTextures (_hiddenSelections apply {_forEachIndex});
    for "_i" from 0 to ((count _hiddenSelections) - 1) do {
        private _current = _currentTextures param [_i, ""];
        private _label = format ["Slot %1 (%2) - %3", _i, _hiddenSelections select _i, if (_current == "") then {"default"} else {_current}];
        private _index = _slotCombo lbAdd _label;
        _slotCombo lbSetData [_index, str _i];
    };
    _slotCombo lbSetCurSel 0;
} else {
    private _index = _slotCombo lbAdd "This vehicle has no texture slots (hiddenSelections[])";
    _slotCombo lbSetData [_index, "-1"];
};
{
    _modeCombo lbAdd _x;
} forEach ["Solid Color", "Custom Texture Path", "Restore Default"];
_modeCombo lbSetCurSel 0;

// ---- Populate Component tab live data (heuristic scan) ----
private _componentCandidates = [_vehicle] call Waldo_fnc_VehicleComponentHeuristicScan;
_disp setVariable ["WaldoVehCust_ComponentCandidates", _componentCandidates];
private _pickIndex0 = _componentPickCombo lbAdd (if (count _componentCandidates > 0) then {
    "Manual / advanced entry"
} else {
    "Manual / advanced (no candidates found)"
});
_componentPickCombo lbSetData [_pickIndex0, "-1"];
{
    _x params ["_selectionName", "_linkedPath", "_candidateLabel"];
    private _index = _componentPickCombo lbAdd _candidateLabel;
    _componentPickCombo lbSetData [_index, str _forEachIndex];
} forEach _componentCandidates;
_componentPickCombo lbSetCurSel 0;
{
    _componentActionCombo lbAdd _x;
} forEach ["Remove", "Restore"];
_componentActionCombo lbSetCurSel 0;

// Linked Turret Path picker - reuses the same mount-less/horn-excluded turret path list the Turret
// tab already computed, so a curator never has to hand-type an array here either.
_componentTurretPickCombo lbAdd "None / type manually below";
_componentTurretPickCombo lbSetData [0, "-1"];
{
    private _index = _componentTurretPickCombo lbAdd (format ["Turret %1", _x]);
    _componentTurretPickCombo lbSetData [_index, str _x];
} forEach _turretPaths;
_componentTurretPickCombo lbSetCurSel 0;

// Zeus still listens for mouse-wheel input behind a child prompt. Give every combo deterministic
// one-row wheel navigation and return true from MouseZChanged so the same wheel step cannot also zoom
// the curator camera. This applies to both collapsed and expanded dropdowns.
private _installComboWheelGuard = {
    params ["_combo"];
    _combo ctrlAddEventHandler ["MouseZChanged", {
        params ["_control", "_wheelDelta"];
        private _rowCount = lbSize _control;
        if (_rowCount <= 0 || {_wheelDelta == 0}) exitWith {true};
        private _current = lbCurSel _control;
        if (_current < 0) then {_current = 0};
        private _step = if (_wheelDelta > 0) then {-1} else {1};
        _control lbSetCurSel (((_current + _step) max 0) min (_rowCount - 1));
        true
    }];
};
{
    [_x] call _installComboWheelGuard;
} forEach [
    _turretCombo, _turretActionCombo, _copyWeaponCombo, _copyMagazineCombo,
    _pylonCombo, _pylonActionCombo, _copyOrdnanceCombo,
    _slotCombo, _modeCombo,
    _componentPickCombo, _componentTurretPickCombo, _componentActionCombo
];

// ---- Event handlers: "Weapon" auto-fill fields + live-filtered "Magazine" repopulation ----
_copyWeaponCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _magazineCombo = _disp getVariable ["WaldoVehCust_CopyMagazineCombo", controlNull];
    private _pickupWeapon = "";
    private _requestedMagazine = "";
    private _requestedMagazineCount = 1;
    private _requestedMagazineQuantity = 1;
    if (_index > 0) then {
        private _key = _ctrl lbData _index;
        private _pickup = parseSimpleArray _key;
        if (_pickup isEqualType [] && {count _pickup == 4}) then {
            _pickup params ["_wpn", "_pickupMag", "_pickupCount", "_pickupQuantity"];
            _pickupWeapon = _wpn;
            _requestedMagazine = _pickupMag;
            _requestedMagazineCount = _pickupCount;
            _requestedMagazineQuantity = _pickupQuantity;
            (_disp getVariable ["WaldoVehCust_TurretWeaponEdit", controlNull]) ctrlSetText _pickupWeapon;
        };
    };
    // Rebuild from the selected weapon's own resolved list. A requested catalog/live-vehicle default
    // is retained only when it is genuinely present in that list; otherwise the first compatible
    // magazine is selected. Never fall back to another weapon's magazine from the same turret.
    if (!isNull _magazineCombo) then {
        lbClear _magazineCombo;
        _magazineCombo lbAdd "Manual / advanced entry";
        _magazineCombo lbSetData [0, "MANUAL"];
        private _magazineRows = [];
        if (_pickupWeapon != "") then {
            _magazineRows = [_pickupWeapon] call Waldo_fnc_VehicleWeaponLoadoutMagazinesForWeapon;
            {
                _x params ["_magClass", "_magDisplayName"];
                private _idx = _magazineCombo lbAdd _magDisplayName;
                _magazineCombo lbSetData [_idx, _magClass];
            } forEach _magazineRows;
        };
        private _magazineClasses = _magazineRows apply {_x select 0};
        private _requestedIndex = _magazineClasses find _requestedMagazine;
        private _selection = if (_requestedIndex >= 0) then {_requestedIndex + 1} else {if (count _magazineRows > 0) then {1} else {0}};
        _magazineCombo lbSetCurSel _selection;

        if (_selection <= 0) then {
            (_disp getVariable ["WaldoVehCust_TurretMagazineEdit", controlNull]) ctrlSetText "";
            (_disp getVariable ["WaldoVehCust_TurretCountEdit", controlNull]) ctrlSetText "1";
        } else {
            private _selectedMagazine = _magazineCombo lbData _selection;
            (_disp getVariable ["WaldoVehCust_TurretMagazineEdit", controlNull]) ctrlSetText _selectedMagazine;
            private _selectedCount = getNumber (configFile >> "CfgMagazines" >> _selectedMagazine >> "count");
            if (_selectedMagazine == _requestedMagazine && {_requestedMagazineCount > 0}) then {
                _selectedCount = _requestedMagazineCount;
            };
            (_disp getVariable ["WaldoVehCust_TurretCountEdit", controlNull]) ctrlSetText (str (_selectedCount max 1));
        };
        (_disp getVariable ["WaldoVehCust_TurretQuantityEdit", controlNull]) ctrlSetText (str (if (_requestedIndex >= 0) then {_requestedMagazineQuantity max 1} else {1}));
    };
    [_disp] call Waldo_fnc_VehCust_refreshRelevantControls;
}];

_copyMagazineCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    if (_index <= 0) exitWith {[_disp] call Waldo_fnc_VehCust_refreshRelevantControls};
    private _magClass = _ctrl lbData _index;
    if (_magClass == "" || {_magClass == "MANUAL"}) exitWith {[_disp] call Waldo_fnc_VehCust_refreshRelevantControls};
    (_disp getVariable ["WaldoVehCust_TurretMagazineEdit", controlNull]) ctrlSetText _magClass;
    private _count = getNumber (configFile >> "CfgMagazines" >> _magClass >> "count");
    if (_count > 0) then {
        (_disp getVariable ["WaldoVehCust_TurretCountEdit", controlNull]) ctrlSetText (str _count);
    };
    [_disp] call Waldo_fnc_VehCust_refreshRelevantControls;
}];

_copyOrdnanceCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    if (_index <= 0) exitWith {[_disp] call Waldo_fnc_VehCust_refreshRelevantControls};
    private _key = _ctrl lbData _index;
    if (_key == "" || {_key == "MANUAL"}) exitWith {[_disp] call Waldo_fnc_VehCust_refreshRelevantControls};
    (_disp getVariable ["WaldoVehCust_PylonMagazineEdit", controlNull]) ctrlSetText _key;
    [_disp] call Waldo_fnc_VehCust_refreshRelevantControls;
}];

// These selections change which fields have meaning; refresh immediately instead of leaving stale,
// misleading controls visible until another action is taken.
{
    _x ctrlAddEventHandler ["LBSelChanged", {
        params ["_control"];
        private _disp = _control getVariable ["WaldoVehCust_Display", displayNull];
        if (!isNull _disp) then {[_disp] call Waldo_fnc_VehCust_refreshRelevantControls};
    }];
} forEach [_turretActionCombo, _pylonActionCombo, _modeCombo, _componentActionCombo];

// ---- Event handler: Component heuristic pick auto-fill ----
_componentPickCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _dataIndex = parseNumber (_ctrl lbData _index);
    if (_dataIndex < 0) exitWith {};
    private _candidates = _disp getVariable ["WaldoVehCust_ComponentCandidates", []];
    if (_dataIndex >= count _candidates) exitWith {};
    private _entry = _candidates select _dataIndex;
    _entry params ["_selectionName", "_linkedPath", "_label"];
    (_disp getVariable ["WaldoVehCust_ComponentSelectionEdit", controlNull]) ctrlSetText _selectionName;
    (_disp getVariable ["WaldoVehCust_ComponentTurretEdit", controlNull]) ctrlSetText (str _linkedPath);
}];

// ---- Event handler: Component Linked Turret Path picker ----
_componentTurretPickCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    if (_index <= 0) exitWith {};
    private _key = _ctrl lbData _index;
    if (_key == "" || {_key == "-1"}) exitWith {};
    (_disp getVariable ["WaldoVehCust_ComponentTurretEdit", controlNull]) ctrlSetText _key;
}];

// ---- Event handlers: Add buttons (each routes through its own validation-gated collector) ----
_addTurretBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _row = [_disp] call Waldo_fnc_VehCust_collectTurretRow;
    if (_row isEqualTo []) exitWith {
        ["VEHICLE CUSTOMISATION", "That turret row is incomplete or invalid - check the weapon/magazine classname. Nothing was added.", "WARNING", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
    };
    [_disp, "TURRET", _row] call Waldo_fnc_VehCust_pushPendingRow;
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
}];

_addPylonBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _row = [_disp] call Waldo_fnc_VehCust_collectPylonRow;
    if (_row isEqualTo []) exitWith {
        ["VEHICLE CUSTOMISATION", "That pylon row is incomplete or invalid - check the ordnance classname. Nothing was added.", "WARNING", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
    };
    [_disp, "PYLON", _row] call Waldo_fnc_VehCust_pushPendingRow;
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
}];

_addAppearanceBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _row = [_disp] call Waldo_fnc_VehCust_collectAppearanceRow;
    if (_row isEqualTo []) exitWith {
        ["VEHICLE CUSTOMISATION", "That appearance row is incomplete or invalid - check the texture path in Custom Texture Path mode. Nothing was added.", "WARNING", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
    };
    [_disp, "APPEARANCE", _row] call Waldo_fnc_VehCust_pushPendingRow;
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
}];

_addComponentBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _row = [_disp] call Waldo_fnc_VehCust_collectComponentRow;
    if (_row isEqualTo []) exitWith {
        ["VEHICLE CUSTOMISATION", "That component row is incomplete - a Selection Name is required. Nothing was added.", "WARNING", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
    };
    [_disp, "COMPONENT", _row] call Waldo_fnc_VehCust_pushPendingRow;
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
}];

// ---- Event handlers: Pending panel buttons ----
_removeSelectedBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _list = _disp getVariable ["WaldoVehCust_PendingList", controlNull];
    if (isNull _list) exitWith {};
    private _sel = lbCurSel _list;
    if (_sel < 0) exitWith {};
    private _uid = _list lbData _sel;
    [_disp, _uid] call Waldo_fnc_VehCust_removePendingRow;
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
}];

_applyAllBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _vehicle = _disp getVariable ["WaldoVehCust_Vehicle", objNull];
    if (isNull _vehicle) exitWith {
        ["VEHICLE CUSTOMISATION", "That vehicle no longer exists.", "WARNING", "VEHCUST_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
    };
    private _rows = _disp getVariable ["WaldoVehCust_PendingRows", []];
    if (_rows isEqualTo []) exitWith {
        ["VEHICLE CUSTOMISATION", "Nothing pending to apply.", "WARNING", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
    };
    private _serverRows = _rows apply {[_x select 1, _x select 2]};
    diag_log format ["[WMP ZEN] invoked module=Vehicle Customisation - Editor curator=%1 vehicle=%2 rowCount=%3", name player, typeOf _vehicle, count _serverRows];
    [_vehicle, _serverRows, player] remoteExecCall ["Waldo_fnc_ZenVehicleCustomizationServer", 2];
    _disp setVariable ["WaldoVehCust_PendingRows", []];
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
}];

_exportBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _ok = [_disp] call Waldo_fnc_VehCust_exportClipboard;
    if (_ok) then {
        ["VEHICLE CUSTOMISATION", "Copied pending changes to clipboard - paste into the target unit's Eden init field. Nothing was applied and the pending list was kept.", "SUCCESS", "VEHCUST_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
    } else {
        ["VEHICLE CUSTOMISATION", "Nothing pending to export.", "WARNING", "VEHCUST_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
    };
}];

_clearAllBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    _disp setVariable ["WaldoVehCust_PendingRows", []];
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
    ["VEHICLE CUSTOMISATION", "Pending list cleared. Nothing was applied.", "INFO", "VEHCUST_ZEN", 5] call Waldo_fnc_FeatureNotifyLocal;
}];

_okBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (!isNull _disp) then {
        [_disp] call Waldo_fnc_VehCust_cleanupEditorPrompt;
    };
}];

// ---- Event handlers: Copy From Nearby Vehicle overlay ----
_copyFromBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _vehicle = _disp getVariable ["WaldoVehCust_Vehicle", objNull];
    if (isNull _vehicle) exitWith {};
    private _nearby = (nearestObjects [_vehicle, ["AllVehicles"], 100]) select {
        _x != _vehicle && {!(_x isKindOf "Man")}
    };
    _nearby = _nearby apply {[_x, _vehicle distance _x]};
    _nearby = [_nearby, [], {_x select 1}, "ASCEND"] call BIS_fnc_sortBy;
    _nearby = _nearby select [0, 10 min (count _nearby)];
    private _overlayList = _disp getVariable ["WaldoVehCust_CopyOverlayList", controlNull];
    if (isNull _overlayList) exitWith {};
    if (_nearby isEqualTo []) exitWith {
        ["VEHICLE CUSTOMISATION", "No other vehicle was found within 100m to copy a loadout from.", "WARNING", "VEHCUST_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
    };
    lbClear _overlayList;
    {
        _x params ["_veh", "_dist"];
        private _label = format ["%1 (%2) - %3m", getText (configFile >> "CfgVehicles" >> (typeOf _veh) >> "displayName"), typeOf _veh, round _dist];
        private _index = _overlayList lbAdd _label;
        // lbData already stores STRING data. Stringifying netId adds literal quote characters and
        // makes objectFromNetId unable to resolve the selected source vehicle.
        _overlayList lbSetData [_index, netId _veh];
    } forEach _nearby;
    {
        private _overlayCtrl = _disp getVariable [_x, controlNull];
        if (!isNull _overlayCtrl) then {_overlayCtrl ctrlShow true;};
    } forEach ["WaldoVehCust_CopyOverlayBg", "WaldoVehCust_CopyOverlayLabel", "WaldoVehCust_CopyOverlayList", "WaldoVehCust_CopyOverlayPickBtn", "WaldoVehCust_CopyOverlayCancelBtn"];
}];

_copyOverlayCancelBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    {
        private _overlayCtrl = _disp getVariable [_x, controlNull];
        if (!isNull _overlayCtrl) then {_overlayCtrl ctrlShow false;};
    } forEach ["WaldoVehCust_CopyOverlayBg", "WaldoVehCust_CopyOverlayLabel", "WaldoVehCust_CopyOverlayList", "WaldoVehCust_CopyOverlayPickBtn", "WaldoVehCust_CopyOverlayCancelBtn"];
}];

_copyOverlayPickBtn ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    private _overlayList = _disp getVariable ["WaldoVehCust_CopyOverlayList", controlNull];
    private _vehicle = _disp getVariable ["WaldoVehCust_Vehicle", objNull];
    if (isNull _overlayList || {isNull _vehicle}) exitWith {};
    private _sel = lbCurSel _overlayList;
    if (_sel < 0) exitWith {};
    private _source = objectFromNetId (_overlayList lbData _sel);
    if (isNull _source) exitWith {};
    private _preview = [_source, _vehicle] call Waldo_fnc_VehicleWeaponLoadoutCopyPreview;
    _preview params [["_rows", []]];
    {
        private _rowType = if ((_x select 0) == "PYLON") then {"PYLON"} else {"TURRET"};
        [_disp, _rowType, _x] call Waldo_fnc_VehCust_pushPendingRow;
    } forEach _rows;
    [_disp] call Waldo_fnc_VehCust_refreshPendingList;
    {
        private _overlayCtrl = _disp getVariable [_x, controlNull];
        if (!isNull _overlayCtrl) then {_overlayCtrl ctrlShow false;};
    } forEach ["WaldoVehCust_CopyOverlayBg", "WaldoVehCust_CopyOverlayLabel", "WaldoVehCust_CopyOverlayList", "WaldoVehCust_CopyOverlayPickBtn", "WaldoVehCust_CopyOverlayCancelBtn"];
    ["VEHICLE CUSTOMISATION", format ["%1 row(s) copied into Pending Changes - review and Apply All Pending, or remove any you don't want first.", count _rows], "SUCCESS", "VEHCUST_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
}];

// Prefer the first real, validated choice when one exists. Manual/advanced remains entry zero, but
// making it the initial screen forced every advanced classname field open and obscured the normal
// beginner workflow. These selections happen after handlers are attached so their dependent fields
// and magazine filters are populated normally.
if ((lbSize _copyWeaponCombo) > 1) then {_copyWeaponCombo lbSetCurSel 1};
if ((lbSize _copyOrdnanceCombo) > 1) then {_copyOrdnanceCombo lbSetCurSel 1};

[_disp, "turret"] call Waldo_fnc_VehCust_setTab;
[_disp] call Waldo_fnc_VehCust_refreshRelevantControls;
[_disp] call Waldo_fnc_VehCust_refreshPendingList;

// Fit explicitly now that every control this dialog creates genuinely exists (deferFit=true was
// passed to Waldo_fnc_EcoCore_createZeusPromptDisplay above specifically so this call is the first
// time fitPromptDisplay runs for this dialog. The fit is synchronous, so the completed geometry is
// applied before this function returns. This is also what moves the shared chrome's background
// card/header out of their small placeholder box into their real, correct position - required, not
// optional, see this file's header for the regression this closes.
[_disp] call Waldo_fnc_EcoCore_fitPromptDisplay;

// The editor-specific group pass and tab repaint are synchronous as well, avoiding a second visible
// resize or theme jump after the shared card has appeared.
[_disp] call Waldo_fnc_VehCust_finalizeLayout;
[_disp, _disp getVariable ["WaldoVehCust_CurrentTab", "turret"]] call Waldo_fnc_VehCust_setTab;

_disp
