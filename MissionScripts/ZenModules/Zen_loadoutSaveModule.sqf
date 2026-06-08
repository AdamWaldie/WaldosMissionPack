/*
 * Author: Waldo
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
 */

params ["_modulePos", "_objectPos"];

private _target = objNull;

if (!isNull _objectPos) then {
    _target = _objectPos;
} else {
    private _crateClass = missionNamespace getVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F"];
    _target = _crateClass createVehicle _modulePos;

    [{
        _this call ace_zeus_fnc_addObjectToCurator;
    }, _target] call CBA_fnc_execNextFrame;
};

// Execute on all current clients and re-execute for every JIP player.
// Using _target as the JIP ID ties the entry to the object lifetime.
[_target] remoteExec ["Waldo_fnc_ZenAddLoadoutSaveAction", 0, _target];
