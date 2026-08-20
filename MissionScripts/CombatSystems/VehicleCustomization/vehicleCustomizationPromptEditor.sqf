/*
 * Author: WaldoTheWarfighter
 * Builds and opens the persistent, multi-tab ZEN "Vehicle Customisation - Editor" dialog for one
 * vehicle - the replacement for the retired one-shot "Configure" / "Copy From Nearby Vehicle" /
 * "Register Component" / "Remove/Restore Component" modules. A curator can queue any number of
 * turret, pylon, appearance, and component changes across four tabs (Turret / Pylon / Appearance /
 * Component, toggled via RscButtonMenu + ctrlShow, matching
 * MissionScripts/EconomySystems/Build/setBuildConfigTab.sqf's pattern) into one permanent Pending
 * Changes RscListbox, visible across every tab, then either apply everything at once or export one
 * ready-to-paste Eden-init-field snippet - the "author here, paste there" beginner workflow.
 *
 * Reuses Waldo_fnc_EcoCore_createZeusPromptDisplay verbatim for the modal child display (it is already
 * generic, no Economy-specific state) and copies control-creation idioms directly from
 * MissionScripts/EconomySystems/Build/promptBuildConfig.sqf. Every Add button routes through its own
 * validation-gated collector (Waldo_fnc_VehCust_collectTurretRow / ..._collectPylonRow /
 * ..._collectAppearanceRow / ..._collectComponentRow) and refuses to push a blank/incomplete row onto
 * Pending - the direct fix for the confirmed root-cause bug in the retired Configure module's
 * Session Action queue (see those files' headers for the full story).
 *
 * Turret/Pylon "Copy Weapon/Ordnance From" pickers and their labels/horn-only/no-mount handling are
 * ported from the retired Zen_vehicleWeaponLoadoutModule.sqf; the Appearance tab's texture-slot
 * discovery is ported from the retired Zen_vehicleAppearanceTextureModule.sqf. The Component tab uses
 * the new Waldo_fnc_VehicleComponentHeuristicScan (live, best-effort auto-discovery) instead of the
 * retired persistent registration catalog.
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

private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
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

// ---- Chrome ----
private _bg = _disp ctrlCreate ["RscText", -1];
_bg ctrlSetPosition [0.08, 0.05, 0.84, 0.90];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
_bg ctrlCommit 0;

private _title = _disp ctrlCreate ["RscText", -1];
_title ctrlSetPosition [0.10, 0.07, 0.50, 0.03];
_title ctrlSetText format ["Vehicle Customisation - Editor: %1", getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "displayName")];
_title ctrlCommit 0;

// ---- Tab buttons ----
private _tabTurretBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabTurretBtn ctrlSetPosition [0.10, 0.11, 0.11, 0.035];
_tabTurretBtn ctrlSetText "Turret";
_tabTurretBtn ctrlCommit 0;

private _tabPylonBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabPylonBtn ctrlSetPosition [0.215, 0.11, 0.11, 0.035];
_tabPylonBtn ctrlSetText "Pylon";
_tabPylonBtn ctrlCommit 0;

private _tabAppearanceBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabAppearanceBtn ctrlSetPosition [0.33, 0.11, 0.13, 0.035];
_tabAppearanceBtn ctrlSetText "Appearance";
_tabAppearanceBtn ctrlCommit 0;

private _tabComponentBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_tabComponentBtn ctrlSetPosition [0.465, 0.11, 0.13, 0.035];
_tabComponentBtn ctrlSetText "Component";
_tabComponentBtn ctrlCommit 0;

// ==== Turret tab ====
private _turretLabel = _disp ctrlCreate ["RscText", -1];
_turretLabel ctrlSetPosition [0.10, 0.16, 0.36, 0.025];
_turretLabel ctrlSetText "Turret";
_turretLabel ctrlCommit 0;

private _turretCombo = _disp ctrlCreate ["RscCombo", -1];
_turretCombo ctrlSetPosition [0.10, 0.19, 0.46, 0.035];
_turretCombo ctrlCommit 0;

private _turretActionLabel = _disp ctrlCreate ["RscText", -1];
_turretActionLabel ctrlSetPosition [0.10, 0.24, 0.36, 0.025];
_turretActionLabel ctrlSetText "Action";
_turretActionLabel ctrlCommit 0;

private _turretActionCombo = _disp ctrlCreate ["RscCombo", -1];
_turretActionCombo ctrlSetPosition [0.10, 0.27, 0.30, 0.035];
_turretActionCombo ctrlCommit 0;

private _copyWeaponLabel = _disp ctrlCreate ["RscText", -1];
_copyWeaponLabel ctrlSetPosition [0.10, 0.32, 0.46, 0.025];
_copyWeaponLabel ctrlSetText "Copy Weapon From (overrides fields below)";
_copyWeaponLabel ctrlCommit 0;

private _copyWeaponCombo = _disp ctrlCreate ["RscCombo", -1];
_copyWeaponCombo ctrlSetPosition [0.10, 0.35, 0.46, 0.035];
_copyWeaponCombo ctrlCommit 0;

private _turretWeaponLabel = _disp ctrlCreate ["RscText", -1];
_turretWeaponLabel ctrlSetPosition [0.10, 0.40, 0.36, 0.025];
_turretWeaponLabel ctrlSetText "Weapon Classname";
_turretWeaponLabel ctrlCommit 0;

private _turretWeaponEdit = _disp ctrlCreate ["RscEdit", -1];
_turretWeaponEdit ctrlSetPosition [0.10, 0.43, 0.46, 0.035];
_turretWeaponEdit ctrlCommit 0;

private _turretMagLabel = _disp ctrlCreate ["RscText", -1];
_turretMagLabel ctrlSetPosition [0.10, 0.48, 0.36, 0.025];
_turretMagLabel ctrlSetText "Magazine Classname";
_turretMagLabel ctrlCommit 0;

private _turretMagEdit = _disp ctrlCreate ["RscEdit", -1];
_turretMagEdit ctrlSetPosition [0.10, 0.51, 0.46, 0.035];
_turretMagEdit ctrlCommit 0;

private _turretCountLabel = _disp ctrlCreate ["RscText", -1];
_turretCountLabel ctrlSetPosition [0.10, 0.56, 0.22, 0.025];
_turretCountLabel ctrlSetText "Rounds/Magazine";
_turretCountLabel ctrlCommit 0;

private _turretCountEdit = _disp ctrlCreate ["RscEdit", -1];
_turretCountEdit ctrlSetPosition [0.10, 0.59, 0.20, 0.035];
_turretCountEdit ctrlSetText "30";
_turretCountEdit ctrlCommit 0;

private _turretQtyLabel = _disp ctrlCreate ["RscText", -1];
_turretQtyLabel ctrlSetPosition [0.32, 0.56, 0.22, 0.025];
_turretQtyLabel ctrlSetText "Magazine Count";
_turretQtyLabel ctrlCommit 0;

private _turretQtyEdit = _disp ctrlCreate ["RscEdit", -1];
_turretQtyEdit ctrlSetPosition [0.32, 0.59, 0.20, 0.035];
_turretQtyEdit ctrlSetText "1";
_turretQtyEdit ctrlCommit 0;

private _addTurretBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_addTurretBtn ctrlSetPosition [0.10, 0.65, 0.20, 0.04];
_addTurretBtn ctrlSetText "Add Turret Row";
_addTurretBtn ctrlCommit 0;

// ==== Pylon tab ====
private _pylonLabel = _disp ctrlCreate ["RscText", -1];
_pylonLabel ctrlSetPosition [0.10, 0.16, 0.36, 0.025];
_pylonLabel ctrlSetText "Pylon";
_pylonLabel ctrlCommit 0;

private _pylonCombo = _disp ctrlCreate ["RscCombo", -1];
_pylonCombo ctrlSetPosition [0.10, 0.19, 0.46, 0.035];
_pylonCombo ctrlCommit 0;

private _pylonActionLabel = _disp ctrlCreate ["RscText", -1];
_pylonActionLabel ctrlSetPosition [0.10, 0.24, 0.36, 0.025];
_pylonActionLabel ctrlSetText "Action";
_pylonActionLabel ctrlCommit 0;

private _pylonActionCombo = _disp ctrlCreate ["RscCombo", -1];
_pylonActionCombo ctrlSetPosition [0.10, 0.27, 0.30, 0.035];
_pylonActionCombo ctrlCommit 0;

private _copyOrdnanceLabel = _disp ctrlCreate ["RscText", -1];
_copyOrdnanceLabel ctrlSetPosition [0.10, 0.32, 0.46, 0.025];
_copyOrdnanceLabel ctrlSetText "Copy Ordnance From (overrides field below)";
_copyOrdnanceLabel ctrlCommit 0;

private _copyOrdnanceCombo = _disp ctrlCreate ["RscCombo", -1];
_copyOrdnanceCombo ctrlSetPosition [0.10, 0.35, 0.46, 0.035];
_copyOrdnanceCombo ctrlCommit 0;

private _pylonMagLabel = _disp ctrlCreate ["RscText", -1];
_pylonMagLabel ctrlSetPosition [0.10, 0.40, 0.36, 0.025];
_pylonMagLabel ctrlSetText "Ordnance/Magazine Classname";
_pylonMagLabel ctrlCommit 0;

private _pylonMagEdit = _disp ctrlCreate ["RscEdit", -1];
_pylonMagEdit ctrlSetPosition [0.10, 0.43, 0.46, 0.035];
_pylonMagEdit ctrlCommit 0;

private _pylonAmmoLabel = _disp ctrlCreate ["RscText", -1];
_pylonAmmoLabel ctrlSetPosition [0.10, 0.48, 0.36, 0.025];
_pylonAmmoLabel ctrlSetText "Ammo Override (0 = full magazine count)";
_pylonAmmoLabel ctrlCommit 0;

private _pylonAmmoEdit = _disp ctrlCreate ["RscEdit", -1];
_pylonAmmoEdit ctrlSetPosition [0.10, 0.51, 0.20, 0.035];
_pylonAmmoEdit ctrlSetText "0";
_pylonAmmoEdit ctrlCommit 0;

private _addPylonBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_addPylonBtn ctrlSetPosition [0.10, 0.65, 0.20, 0.04];
_addPylonBtn ctrlSetText "Add Pylon Row";
_addPylonBtn ctrlCommit 0;

// ==== Appearance tab ====
private _slotLabel = _disp ctrlCreate ["RscText", -1];
_slotLabel ctrlSetPosition [0.10, 0.16, 0.36, 0.025];
_slotLabel ctrlSetText "Texture Slot";
_slotLabel ctrlCommit 0;

private _slotCombo = _disp ctrlCreate ["RscCombo", -1];
_slotCombo ctrlSetPosition [0.10, 0.19, 0.46, 0.035];
_slotCombo ctrlCommit 0;

private _modeLabel = _disp ctrlCreate ["RscText", -1];
_modeLabel ctrlSetPosition [0.10, 0.24, 0.36, 0.025];
_modeLabel ctrlSetText "Mode";
_modeLabel ctrlCommit 0;

private _modeCombo = _disp ctrlCreate ["RscCombo", -1];
_modeCombo ctrlSetPosition [0.10, 0.27, 0.30, 0.035];
_modeCombo ctrlCommit 0;

private _rgbaLabel = _disp ctrlCreate ["RscText", -1];
_rgbaLabel ctrlSetPosition [0.10, 0.32, 0.46, 0.025];
_rgbaLabel ctrlSetText "Solid Color R / G / B / A (0..1, used in Solid Color mode)";
_rgbaLabel ctrlCommit 0;

private _redEdit = _disp ctrlCreate ["RscEdit", -1];
_redEdit ctrlSetPosition [0.10, 0.35, 0.10, 0.035];
_redEdit ctrlSetText "1";
_redEdit ctrlCommit 0;

private _greenEdit = _disp ctrlCreate ["RscEdit", -1];
_greenEdit ctrlSetPosition [0.21, 0.35, 0.10, 0.035];
_greenEdit ctrlSetText "0";
_greenEdit ctrlCommit 0;

private _blueEdit = _disp ctrlCreate ["RscEdit", -1];
_blueEdit ctrlSetPosition [0.32, 0.35, 0.10, 0.035];
_blueEdit ctrlSetText "1";
_blueEdit ctrlCommit 0;

private _alphaEdit = _disp ctrlCreate ["RscEdit", -1];
_alphaEdit ctrlSetPosition [0.43, 0.35, 0.10, 0.035];
_alphaEdit ctrlSetText "1";
_alphaEdit ctrlCommit 0;

private _pathLabel = _disp ctrlCreate ["RscText", -1];
_pathLabel ctrlSetPosition [0.10, 0.40, 0.46, 0.025];
_pathLabel ctrlSetText "Custom Texture Path (used in Custom Texture Path mode)";
_pathLabel ctrlCommit 0;

private _pathEdit = _disp ctrlCreate ["RscEdit", -1];
_pathEdit ctrlSetPosition [0.10, 0.43, 0.46, 0.035];
_pathEdit ctrlCommit 0;

private _addAppearanceBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_addAppearanceBtn ctrlSetPosition [0.10, 0.65, 0.24, 0.04];
_addAppearanceBtn ctrlSetText "Add Appearance Row";
_addAppearanceBtn ctrlCommit 0;

// ==== Component tab ====
private _componentPickLabel = _disp ctrlCreate ["RscText", -1];
_componentPickLabel ctrlSetPosition [0.10, 0.16, 0.46, 0.025];
_componentPickLabel ctrlSetText "Heuristic Candidate (best-effort - verify, or type manually below)";
_componentPickLabel ctrlCommit 0;

private _componentPickCombo = _disp ctrlCreate ["RscCombo", -1];
_componentPickCombo ctrlSetPosition [0.10, 0.19, 0.46, 0.035];
_componentPickCombo ctrlCommit 0;

private _componentSelLabel = _disp ctrlCreate ["RscText", -1];
_componentSelLabel ctrlSetPosition [0.10, 0.24, 0.36, 0.025];
_componentSelLabel ctrlSetText "Selection Name";
_componentSelLabel ctrlCommit 0;

private _componentSelEdit = _disp ctrlCreate ["RscEdit", -1];
_componentSelEdit ctrlSetPosition [0.10, 0.27, 0.46, 0.035];
_componentSelEdit ctrlCommit 0;

private _componentTurretLabel = _disp ctrlCreate ["RscText", -1];
_componentTurretLabel ctrlSetPosition [0.10, 0.32, 0.46, 0.025];
_componentTurretLabel ctrlSetText "Linked Turret Path (optional, e.g. [0] or [-1])";
_componentTurretLabel ctrlCommit 0;

private _componentTurretEdit = _disp ctrlCreate ["RscEdit", -1];
_componentTurretEdit ctrlSetPosition [0.10, 0.35, 0.46, 0.035];
_componentTurretEdit ctrlCommit 0;

private _componentActionLabel = _disp ctrlCreate ["RscText", -1];
_componentActionLabel ctrlSetPosition [0.10, 0.40, 0.36, 0.025];
_componentActionLabel ctrlSetText "Action";
_componentActionLabel ctrlCommit 0;

private _componentActionCombo = _disp ctrlCreate ["RscCombo", -1];
_componentActionCombo ctrlSetPosition [0.10, 0.43, 0.30, 0.035];
_componentActionCombo ctrlCommit 0;

private _addComponentBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_addComponentBtn ctrlSetPosition [0.10, 0.65, 0.24, 0.04];
_addComponentBtn ctrlSetText "Add Component Row";
_addComponentBtn ctrlCommit 0;

// ==== Permanent Pending Changes panel (right side, all tabs) ====
private _pendingLabel = _disp ctrlCreate ["RscText", -1];
_pendingLabel ctrlSetPosition [0.60, 0.16, 0.30, 0.025];
_pendingLabel ctrlSetText "Pending Changes";
_pendingLabel ctrlCommit 0;

private _pendingList = _disp ctrlCreate ["RscListbox", -1];
_pendingList ctrlSetPosition [0.60, 0.19, 0.30, 0.42];
_pendingList ctrlCommit 0;

private _removeSelectedBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_removeSelectedBtn ctrlSetPosition [0.60, 0.62, 0.30, 0.035];
_removeSelectedBtn ctrlSetText "Remove Selected Pending Row";
_removeSelectedBtn ctrlCommit 0;

private _copyFromBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_copyFromBtn ctrlSetPosition [0.60, 0.66, 0.30, 0.035];
_copyFromBtn ctrlSetText "Copy From Nearby Vehicle...";
_copyFromBtn ctrlCommit 0;

private _applyAllBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_applyAllBtn ctrlSetPosition [0.60, 0.70, 0.30, 0.035];
_applyAllBtn ctrlSetText "Apply All Pending";
_applyAllBtn ctrlCommit 0;

private _exportBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_exportBtn ctrlSetPosition [0.60, 0.74, 0.30, 0.035];
_exportBtn ctrlSetText "Export All Pending To Clipboard";
_exportBtn ctrlCommit 0;

private _clearAllBtn = _disp ctrlCreate ["RscButtonMenu", -1];
_clearAllBtn ctrlSetPosition [0.60, 0.78, 0.30, 0.035];
_clearAllBtn ctrlSetText "Clear All Pending";
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
_disp setVariable ["WaldoVehCust_TextureRedEdit", _redEdit];
_disp setVariable ["WaldoVehCust_TextureGreenEdit", _greenEdit];
_disp setVariable ["WaldoVehCust_TextureBlueEdit", _blueEdit];
_disp setVariable ["WaldoVehCust_TextureAlphaEdit", _alphaEdit];
_disp setVariable ["WaldoVehCust_TexturePathEdit", _pathEdit];

_disp setVariable ["WaldoVehCust_ComponentPickCombo", _componentPickCombo];
_disp setVariable ["WaldoVehCust_ComponentSelectionEdit", _componentSelEdit];
_disp setVariable ["WaldoVehCust_ComponentTurretEdit", _componentTurretEdit];
_disp setVariable ["WaldoVehCust_ComponentActionCombo", _componentActionCombo];

_disp setVariable ["WaldoVehCust_PendingList", _pendingList];
_disp setVariable ["WaldoVehCust_TabTurretBtn", _tabTurretBtn];
_disp setVariable ["WaldoVehCust_TabPylonBtn", _tabPylonBtn];
_disp setVariable ["WaldoVehCust_TabAppearanceBtn", _tabAppearanceBtn];
_disp setVariable ["WaldoVehCust_TabComponentBtn", _tabComponentBtn];

_disp setVariable ["WaldoVehCust_CopyOverlayBg", _copyOverlayBg];
_disp setVariable ["WaldoVehCust_CopyOverlayLabel", _copyOverlayLabel];
_disp setVariable ["WaldoVehCust_CopyOverlayList", _copyOverlayList];
_disp setVariable ["WaldoVehCust_CopyOverlayPickBtn", _copyOverlayPickBtn];
_disp setVariable ["WaldoVehCust_CopyOverlayCancelBtn", _copyOverlayCancelBtn];

_disp setVariable ["WaldoVehCust_TurretTabControls", [
    _turretLabel, _turretCombo, _turretActionLabel, _turretActionCombo,
    _copyWeaponLabel, _copyWeaponCombo, _turretWeaponLabel, _turretWeaponEdit,
    _turretMagLabel, _turretMagEdit, _turretCountLabel, _turretCountEdit,
    _turretQtyLabel, _turretQtyEdit, _addTurretBtn
]];
_disp setVariable ["WaldoVehCust_PylonTabControls", [
    _pylonLabel, _pylonCombo, _pylonActionLabel, _pylonActionCombo,
    _copyOrdnanceLabel, _copyOrdnanceCombo, _pylonMagLabel, _pylonMagEdit,
    _pylonAmmoLabel, _pylonAmmoEdit, _addPylonBtn
]];
_disp setVariable ["WaldoVehCust_AppearanceTabControls", [
    _slotLabel, _slotCombo, _modeLabel, _modeCombo, _rgbaLabel,
    _redEdit, _greenEdit, _blueEdit, _alphaEdit, _pathLabel, _pathEdit, _addAppearanceBtn
]];
_disp setVariable ["WaldoVehCust_ComponentTabControls", [
    _componentPickLabel, _componentPickCombo, _componentSelLabel, _componentSelEdit,
    _componentTurretLabel, _componentTurretEdit, _componentActionLabel, _componentActionCombo,
    _addComponentBtn
]];

{
    _x setVariable ["WaldoVehCust_Display", _disp];
} forEach [
    _tabTurretBtn, _tabPylonBtn, _tabAppearanceBtn, _tabComponentBtn,
    _addTurretBtn, _addPylonBtn, _addAppearanceBtn, _addComponentBtn,
    _removeSelectedBtn, _copyFromBtn, _applyAllBtn, _exportBtn, _clearAllBtn, _okBtn,
    _copyWeaponCombo, _copyOrdnanceCombo, _componentPickCombo,
    _copyOverlayPickBtn, _copyOverlayCancelBtn
];

_tabTurretBtn setVariable ["WaldoVehCust_TabName", "turret"];
_tabPylonBtn setVariable ["WaldoVehCust_TabName", "pylon"];
_tabAppearanceBtn setVariable ["WaldoVehCust_TabName", "appearance"];
_tabComponentBtn setVariable ["WaldoVehCust_TabName", "component"];

// ---- Populate Turret tab live data ----
private _turretPaths = [[-1]] + (allTurrets [_vehicle, true]);
private _mainSlotHasMount = count (getArray (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "weapons")) > 0;
{
    private _path = _x;
    private _current = _vehicle weaponsTurret _path;
    private _isHornOnly = count _current > 0 && {(_current select {!(_x call _isHornWeapon)}) isEqualTo []};
    private _isMountless = _path isEqualTo [-1] && {!_mainSlotHasMount};
    private _currentText = if (count _current > 0) then {
        (_current apply {getText (configFile >> "CfgWeapons" >> _x >> "displayName")}) joinString ", "
    } else {"empty"};
    private _suffix = if (_isHornOnly) then {" (horn - not editable here)"} else {
        if (_isMountless) then {" (no weapon mount on this vehicle)"} else {""}
    };
    private _label = [format ["Turret %1 - %2%3", _path, _currentText, _suffix]] call _truncateLabel;
    private _index = _turretCombo lbAdd _label;
    _turretCombo lbSetData [_index, str _path];
} forEach _turretPaths;
_turretCombo lbSetCurSel 0;

{
    _turretActionCombo lbAdd _x;
} forEach ["Add Weapon", "Replace Turret", "Remove Weapon", "Clear Turret"];
_turretActionCombo lbSetCurSel 0;

private _turretCatalog = missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_TurretCatalog", []];
private _catalogDisplayCap = 150;
private _pickupKeys = ["MANUAL"];
private _pickupLabels = ["Type manually (use the fields below)"];
{
    private _path = _x;
    private _current = _vehicle weaponsTurret _path;
    private _isHornOnly = count _current > 0 && {(_current select {!(_x call _isHornWeapon)}) isEqualTo []};
    if !(_isHornOnly) then {
        private _weapons = _vehicle weaponsTurret _path;
        private _rawMagazines = _vehicle magazinesTurret _path;
        private _magazines = _rawMagazines arrayIntersect _rawMagazines;
        {
            private _weaponClass = _x;
            private _compatible = _magazines select {_x in (compatibleMagazines _weaponClass)};
            private _magForPickup = if (count _compatible > 0) then {_compatible select 0} else {_magazines param [0, ""]};
            private _magCount = if (_magForPickup == "") then {1} else {getNumber (configFile >> "CfgMagazines" >> _magForPickup >> "count")};
            private _magQuantity = ({_x == _magForPickup} count _rawMagazines) max 1;
            private _key = str [_weaponClass, _magForPickup, _magCount, _magQuantity];
            if !(_key in _pickupKeys) then {
                _pickupKeys pushBack _key;
                _pickupLabels pushBack ([format ["%1 + %2x %3 (from Turret %4)", _weaponClass, _magQuantity, if (_magForPickup == "") then {"no magazine"} else {_magForPickup}, _path]] call _truncateLabel);
            };
        } forEach _weapons;
    };
} forEach _turretPaths;
{
    _x params ["_weaponClass", "_displayName", "_catalogMagazines"];
    private _magForPickup = _catalogMagazines param [0, ""];
    private _magCount = if (_magForPickup == "") then {1} else {getNumber (configFile >> "CfgMagazines" >> _magForPickup >> "count")};
    private _key = str [_weaponClass, _magForPickup, _magCount, 1];
    if !(_key in _pickupKeys) then {
        _pickupKeys pushBack _key;
        _pickupLabels pushBack ([format ["%1 (%2) [pack-wide]", _displayName, _weaponClass]] call _truncateLabel);
    };
} forEach (_turretCatalog select [0, _catalogDisplayCap min (count _turretCatalog)]);
if (count _turretCatalog == 0) then {
    _pickupLabels set [0, "Type manually (catalog still building - reopen shortly)"];
};
{
    private _index = _copyWeaponCombo lbAdd (_pickupLabels select _forEachIndex);
    _copyWeaponCombo lbSetData [_index, _x];
} forEach _pickupKeys;
_copyWeaponCombo lbSetCurSel 0;

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
private _ordnanceLabels = ["Type manually (use the field above)"];
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
    "Type manually (ignore heuristic candidates below)"
} else {
    "Type manually (no candidates found on this vehicle)"
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

// ---- Event handlers: tabs ----
{
    _x ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
        if (isNull _disp) exitWith {};
        [_disp, _ctrl getVariable ["WaldoVehCust_TabName", "turret"]] call Waldo_fnc_VehCust_setTab;
    }];
} forEach [_tabTurretBtn, _tabPylonBtn, _tabAppearanceBtn, _tabComponentBtn];

// ---- Event handlers: "Copy Weapon From" / "Copy Ordnance From" auto-fill fields ----
_copyWeaponCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    if (_index <= 0) exitWith {};
    private _key = _ctrl lbData _index;
    private _pickup = parseSimpleArray _key;
    if !(_pickup isEqualType [] && {count _pickup == 4}) exitWith {};
    _pickup params ["_pickupWeapon", "_pickupMag", "_pickupCount", "_pickupQuantity"];
    (_disp getVariable ["WaldoVehCust_TurretWeaponEdit", controlNull]) ctrlSetText _pickupWeapon;
    (_disp getVariable ["WaldoVehCust_TurretMagazineEdit", controlNull]) ctrlSetText _pickupMag;
    (_disp getVariable ["WaldoVehCust_TurretCountEdit", controlNull]) ctrlSetText (str _pickupCount);
    (_disp getVariable ["WaldoVehCust_TurretQuantityEdit", controlNull]) ctrlSetText (str _pickupQuantity);
}];

_copyOrdnanceCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    private _disp = _ctrl getVariable ["WaldoVehCust_Display", displayNull];
    if (isNull _disp) exitWith {};
    if (_index <= 0) exitWith {};
    private _key = _ctrl lbData _index;
    if (_key == "" || {_key == "MANUAL"}) exitWith {};
    (_disp getVariable ["WaldoVehCust_PylonMagazineEdit", controlNull]) ctrlSetText _key;
}];

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
        _overlayList lbSetData [_index, str (netId _veh)];
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

[_disp, "turret"] call Waldo_fnc_VehCust_setTab;
[_disp] call Waldo_fnc_VehCust_refreshPendingList;

_disp
