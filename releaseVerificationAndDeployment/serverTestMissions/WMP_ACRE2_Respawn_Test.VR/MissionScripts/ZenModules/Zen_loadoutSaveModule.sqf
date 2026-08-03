/*
 * Author: WaldoTheWarfighter
 * Zeus module to add a "Save Respawn Loadout" action to a target object.
 * If no object is selected a default supply box is spawned at the module position.
 * JIP compatible — action is re-applied automatically to players who join late.
 *
 * Arguments:
 * 0: modulePos <POSITION>
 * 1: objectPos <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [getPos logic, cursorObject] call Waldo_fnc_ZenLoadoutSaveModule;
 *
 * Current caller: the ZEN "Respawn: Create Loadout Save Point" module under WMP Logistics.
 */

params ["_modulePos", "_objectPos", ["_actor", objNull]];

if (!isServer) exitWith {
    [_modulePos, _objectPos, player] remoteExecCall ["Waldo_fnc_ZenLoadoutSaveModule", 2];
};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isRemoteExecuted && {
    isNull _actor
    || {_requestOwner != owner _actor}
    || {isNull (getAssignedCuratorLogic _actor)}
}) exitWith {
    diag_log format ["[WMP ZEN] rejected loadout save-point request owner=%1 actor=%2", _requestOwner, _actor];
};

private _target = objNull;

if (!isNull _objectPos) then {
    _target = _objectPos;
} else {
    private _crateClass = missionNamespace getVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F"];
    _target = _crateClass createVehicle _modulePos;

    // Only the fallback crate created by this module is emptied. Existing
    // vehicles, crates and other selected targets retain their full inventory.
    clearWeaponCargoGlobal _target;
    clearMagazineCargoGlobal _target;
    clearItemCargoGlobal _target;
    clearBackpackCargoGlobal _target;

    [_target, _requestOwner, false, false] call Waldo_fnc_ZenAssignObjectOwnerServer;
};

// Execute on all current clients and re-execute for every JIP player.
// Using _target as the JIP ID ties the entry to the object lifetime.
[_target] remoteExec ["Waldo_fnc_ZenAddLoadoutSaveAction", 0, _target];
diag_log format ["[WMP ZEN] loadout save point configured target=%1 actor=%2 owner=%3", netId _target, if (isNull _actor) then {"<server>"} else {name _actor}, _requestOwner];
