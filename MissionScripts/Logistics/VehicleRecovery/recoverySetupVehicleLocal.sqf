/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe local packaging action for a registered recovery vehicle. The feature
 * action always remains present. When the optional preparation procedure is enabled, clicking the
 * same action starts that procedure; otherwise it submits the original immediate package request.
 * The server validates damage, workshop, engineer, occupancy, movement and distance in either route.
 *
 * Arguments:
 * 0: recoverable vehicle <OBJECT>
 * 1: procedure settings <ARRAY> - [] or [challengeId, difficulty]
 *
 * Return Value:
 * Boolean - true when installed or intentionally delegated to a procedure
 *
 * Called by:
 * Waldo_fnc_RecoveryRegisterVehicle through an object-keyed JIP remote execution.
 *
 * Example:
 * [_vehicle] call Waldo_fnc_RecoverySetupVehicleLocal;
 */

params [["_target", objNull, [objNull]], ["_interactionSettings", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (count _interactionSettings >= 2) then {
    [_target, _interactionSettings] call Waldo_fnc_RecoveryInteractionSetup;
};
if (!hasInterface || {isNull _target}) exitWith {false};
{_target removeAction _x} forEach (_target getVariable ["Waldo_Recovery_VehicleActionIds", []]);
_target setVariable ["Waldo_Recovery_VehicleActionIds", []];
private _condition = "_this distance _target < 5 && {vehicle _this == _this} && {count crew _target == 0} && {abs speed _target < 1} && {(damage _target >= ((_target getVariable ['Waldo_Recovery_Config',['MAIN',0.55,true,false,'',true,1]]) select 1)) || {!alive _target}}";
private _id = _target addAction [
    "<t color='#F4C542'>Package for Recovery</t>",
    {
        params ["_target", "_actor"];
        if (_target getVariable ["Waldo_Recovery_InteractionEnabled", false]) then {
            _target call Waldo_fnc_MiniGameInteractionActivate;
        } else {
            [_actor, "PACK", _target] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];
        };
    },
    [], 1.5, true, true, "", _condition, 5
];
_target setVariable ["Waldo_Recovery_VehicleActionIds", [_id]];
_target setVariable ["Waldo_Recovery_VehicleActionInstalled", true];
true
