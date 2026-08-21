/*
 * Author: WaldoTheWarfighter
 * Shows only the controls relevant to the currently selected Vehicle Customisation Editor action.
 * This keeps the dense Zeus dialog readable: CLEAR/REMOVE actions do not leave ammunition fields on
 * screen, Appearance shows either colour sliders or a texture path, and Restore Component does not
 * imply that a removed turret weapon will also be restored.
 *
 * Locality and repeat/JIP behaviour:
 * Interface-client local. It only changes controls on the caller's open display, is safe to call after
 * every selection change, creates no persistent state and therefore needs no JIP replay.
 *
 * Arguments:
 * 0: editor display <DISPLAY> (default displayNull)
 *
 * Return Value:
 * BOOL - true when a live editor display was refreshed, otherwise false.
 *
 * Current callers:
 * vehicleCustomizationPromptEditor.sqf after setup and from its action/mode/picker event handlers.
 *
 * Example:
 * [_display] call Waldo_fnc_VehCust_refreshRelevantControls;
 */
params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {false};

private _showControls = {
    params ["_controls", "_show"];
    {
        if (!isNull _x) then {_x ctrlShow _show};
    } forEach _controls;
};
private _selection = {
    params ["_variable"];
    private _control = _display getVariable [_variable, controlNull];
    if (isNull _control) exitWith {-1};
    lbCurSel _control
};

private _turretAction = ["WaldoVehCust_TurretActionCombo"] call _selection;
private _turretNeedsWeapon = _turretAction in [0, 1, 2];
private _turretNeedsMagazine = _turretAction in [0, 1];
private _manualWeapon = (["WaldoVehCust_CopyWeaponCombo"] call _selection) <= 0;
private _manualMagazine = (["WaldoVehCust_CopyMagazineCombo"] call _selection) <= 0;
[_display getVariable ["WaldoVehCust_TurretWeaponPickerControls", []], _turretNeedsWeapon] call _showControls;
[_display getVariable ["WaldoVehCust_TurretManualWeaponControls", []], _turretNeedsWeapon && {_manualWeapon}] call _showControls;
[_display getVariable ["WaldoVehCust_TurretMagazinePickerControls", []], _turretNeedsMagazine] call _showControls;
[_display getVariable ["WaldoVehCust_TurretManualMagazineControls", []], _turretNeedsMagazine && {_manualMagazine}] call _showControls;
[_display getVariable ["WaldoVehCust_TurretAmmoControls", []], _turretNeedsMagazine] call _showControls;

private _pylonSet = (["WaldoVehCust_PylonActionCombo"] call _selection) == 0;
private _manualOrdnance = (["WaldoVehCust_CopyOrdnanceCombo"] call _selection) <= 0;
[_display getVariable ["WaldoVehCust_PylonPickerControls", []], _pylonSet] call _showControls;
[_display getVariable ["WaldoVehCust_PylonManualControls", []], _pylonSet && {_manualOrdnance}] call _showControls;
[_display getVariable ["WaldoVehCust_PylonAmmoControls", []], _pylonSet] call _showControls;

private _appearanceMode = ["WaldoVehCust_TextureModeCombo"] call _selection;
[_display getVariable ["WaldoVehCust_ColourControls", []], _appearanceMode == 0] call _showControls;
[_display getVariable ["WaldoVehCust_TexturePathControls", []], _appearanceMode == 1] call _showControls;

private _componentRemove = (["WaldoVehCust_ComponentActionCombo"] call _selection) == 0;
[_display getVariable ["WaldoVehCust_ComponentTurretControls", []], _componentRemove] call _showControls;
true
