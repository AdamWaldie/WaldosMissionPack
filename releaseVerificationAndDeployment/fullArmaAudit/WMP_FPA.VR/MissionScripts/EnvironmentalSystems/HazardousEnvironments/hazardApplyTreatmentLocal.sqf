/*
 * Author: WaldoTheWarfighter, Val
 * Applies a validated local exposure reduction to one player. The caller removes the configured
 * treatment item before forwarding this function to the target owner; this function changes only
 * the target client's exposure HashMap and reports the result to patient and giver.
 * Locality and authority: runs on the patient owner's interface client; remote calls are owner-forwarded.
 *
 * Arguments:
 * 0: target <OBJECT>
 * 1: giver <OBJECT>
 * 2: reduction <NUMBER> - amount removed from every positive exposure channel.
 * 3: treatment label <STRING>
 *
 * Return Value: Boolean - true when applied or forwarded.
 *
 * Example:
 * [player, player, 2, "Anti-radiation medication"] call Waldo_fnc_HazardApplyTreatmentLocal;
 * Result: removes up to two exposure units from each active channel and notifies the patient.
 * Current caller: Waldo_fnc_HazardInteractionInit treatment completion callback.
 */

params ["_target", "_giver", ["_reduction", 0, [0]], ["_label", "Hazard treatment", [""]]];
if (isNull _target || {!isPlayer _target} || {_reduction <= 0}) exitWith {false};
if (remoteExecutedOwner > 0 && {isNull _giver || {owner _giver != remoteExecutedOwner}}) exitWith {false};
if (!local _target) exitWith {
    [_target, _giver, _reduction, _label] remoteExecCall ["Waldo_fnc_HazardApplyTreatmentLocal", owner _target];
    true
};
private _exposures = missionNamespace getVariable ["Waldo_Hazard_LocalExposure", createHashMap];
private _before = 0;
private _after = 0;
{
    private _value = _exposures getOrDefault [_x, 0];
    _before = _before + _value;
    private _newValue = (_value - _reduction) max 0;
    _exposures set [_x, _newValue];
    _after = _after + _newValue;
} forEach keys _exposures;
missionNamespace setVariable ["Waldo_Hazard_LocalExposure", _exposures];
private _message = format ["%1 administered to %2. Total exposure reduced from %3 to %4.", _label, name _target, _before toFixed 2, _after toFixed 2];
["HAZARD TREATMENT", _message, "SUCCESS", "HAZARD_TREATMENT", 7] call Waldo_fnc_FeatureNotifyLocal;
if (!isNull _giver && {_giver != _target}) then {
    ["HAZARD TREATMENT", _message, "SUCCESS", "HAZARD_TREATMENT", 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _giver];
};
true
