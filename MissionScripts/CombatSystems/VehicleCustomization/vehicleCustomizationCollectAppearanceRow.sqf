/*
 * Author: WaldoTheWarfighter
 * Validation-gated reader for the ZEN "Vehicle Customisation - Editor" dialog's Appearance tab. Reads
 * the currently selected texture slot/mode/color/path controls and returns a ready-to-queue
 * Waldo_fnc_VehicleAppearanceApply TEXTURE row, or an empty array on ANY invalid or incomplete input -
 * same "never let a blank/garbage row reach the pending list" contract as
 * Waldo_fnc_VehCust_collectTurretRow.
 *
 * Never mutates anything and never touches the pending list itself - purely reads controls off _disp.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 *
 * Return Value:
 * Array - a Waldo_fnc_VehicleAppearanceApply TEXTURE row [ "TEXTURE", slotIndex, action, value ], or
 * [] when the current Appearance tab selection/fields are invalid or incomplete.
 *
 * Example:
 * private _row = [_disp] call Waldo_fnc_VehCust_collectAppearanceRow;
 * if (_row isEqualTo []) exitWith {};
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (Appearance tab's Add Appearance Row button).
 */

params [["_disp", displayNull]];
if (isNull _disp) exitWith {[]};

private _slotCombo = _disp getVariable ["WaldoVehCust_TextureSlotCombo", controlNull];
private _modeCombo = _disp getVariable ["WaldoVehCust_TextureModeCombo", controlNull];
private _rEdit = _disp getVariable ["WaldoVehCust_TextureRedEdit", controlNull];
private _gEdit = _disp getVariable ["WaldoVehCust_TextureGreenEdit", controlNull];
private _bEdit = _disp getVariable ["WaldoVehCust_TextureBlueEdit", controlNull];
private _aEdit = _disp getVariable ["WaldoVehCust_TextureAlphaEdit", controlNull];
private _pathEdit = _disp getVariable ["WaldoVehCust_TexturePathEdit", controlNull];
if (isNull _slotCombo || {isNull _modeCombo} || {isNull _rEdit} || {isNull _gEdit} || {isNull _bEdit} || {isNull _aEdit} || {isNull _pathEdit}) exitWith {[]};

private _slotIndexSel = lbCurSel _slotCombo;
if (_slotIndexSel < 0) exitWith {[]};
private _slotIndex = parseNumber (_slotCombo lbData _slotIndexSel);
if (_slotIndex < 0) exitWith {[]};

private _modeIndex = lbCurSel _modeCombo;
if (_modeIndex < 0) exitWith {[]};

// Mode 2 = Restore Default.
if (_modeIndex == 2) exitWith {
    ["TEXTURE", _slotIndex, "CLEAR", ""]
};

// Mode 0 = Solid Color - no texture asset needed, built via a plain [R,G,B,A] array that
// Waldo_fnc_VehicleAppearanceApply auto-converts with BIS_fnc_colorRGBAtoTexture.
if (_modeIndex == 0) exitWith {
    private _r = parseNumber (ctrlText _rEdit);
    private _g = parseNumber (ctrlText _gEdit);
    private _b = parseNumber (ctrlText _bEdit);
    private _a = parseNumber (ctrlText _aEdit);
    ["TEXTURE", _slotIndex, "SET", [_r, _g, _b, _a]]
};

// Mode 1 = Custom Texture Path - requires a non-blank path/procedural string.
private _path = trim (ctrlText _pathEdit);
if (_path == "") exitWith {[]};
["TEXTURE", _slotIndex, "SET", _path]
