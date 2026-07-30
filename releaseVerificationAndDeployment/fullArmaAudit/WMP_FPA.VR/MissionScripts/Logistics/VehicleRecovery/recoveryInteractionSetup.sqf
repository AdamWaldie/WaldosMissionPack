/*
 * Author: WaldoTheWarfighter
 * Attaches an optional shared recovery-preparation procedure to a registered vehicle. Successful
 * completion submits the ordinary PACK operation to the authoritative recovery handler, which
 * revalidates all recovery constraints before hiding or replacing the vehicle. Failed or stale
 * conditions therefore never bypass the existing recovery safety checks.
 *
 * Arguments:
 * 0: recoverable vehicle <OBJECT>
 * 1: settings <ARRAY> - [challengeId, difficulty]
 *
 * Return Value:
 * Boolean - true when a valid setup was submitted
 *
 * Called by:
 * Waldo_fnc_RecoveryRegisterVehicle through an object-keyed JIP remote execution.
 *
 * Example:
 * [_vehicle, ["repair", "standard"]] call Waldo_fnc_RecoveryInteractionSetup;
 */

params [["_vehicle", objNull, [objNull]], ["_settings", [], [[]]]];
if (isNull _vehicle || {count _settings < 2}) exitWith {false};
_settings params ["_challengeId", "_difficulty"];
[
    _vehicle,
    _challengeId,
    createHashMapFromArray [
        ["actionTitle", "Prepare Vehicle for Recovery"],
        ["difficulty", _difficulty],
        ["retryOnFailure", true],
        ["repeatable", false],
        ["distance", 5],
        ["condition", {
            private _config = _this getVariable ["Waldo_Recovery_Config", ["MAIN", 0.55, true, false, "", true, 1]];
            _this getVariable ["Waldo_Recovery_Registered", false]
            && {_this getVariable ["Waldo_Recovery_InteractionEnabled", false]}
            && {count crew _this == 0}
            && {abs speed _this < 1}
            && {(damage _this >= (_config select 1)) || {!alive _this}}
        }],
        ["actorCondition", {
            params ["_target", "_actor"];
            private _config = _target getVariable ["Waldo_Recovery_Config", ["MAIN", 0.55, true, false, "", true, 1]];
            !(_config select 3) || {_actor getUnitTrait "engineer"}
        }],
        ["onSuccess", {params ["_target", "_actor"]; [_actor, "PACK", _target] call Waldo_fnc_RecoveryRequestServer}],
        ["preset", "vehicle-recovery-preparation"],
        ["title", "VEHICLE RECOVERY RIGGING"],
        ["objective", "Stabilise and prepare the vehicle for safe recovery transport."],
        ["briefing", "RECOVERY PREPARATION"],
        ["successText", "VEHICLE PREPARED FOR RECOVERY"],
        ["skin", "hazard"]
    ]
] call Waldo_fnc_MiniGameInteractionSetup;
true
