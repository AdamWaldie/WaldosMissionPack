/*
 * Author: WaldoTheWarfighter
 * Applies one server-approved ZEN Field Equipment definition on every machine. Interface clients
 * install the ACE/vanilla action; the server stores the callbacks and authoritative state. Object-
 * keyed JIP replacement and the shared interaction installer make reconfiguration repeat-safe.
 *
 * Arguments:
 * 0 object <OBJECT>; 1 mode <STRING>; 2 procedure <STRING>; 3 action title <STRING>;
 * 4 difficulty <STRING>; 5 outcome <STRING>; 6 repeat after success <BOOL>;
 * 7 retry after failure <BOOL>; 8 direct ACE action <BOOL>; 9 EOD detonate on failure <BOOL>.
 * Return Value: Boolean.
 * Current caller: FIELD_EQUIPMENT action in Waldo_fnc_FeatureRuntimeApply via JIP remote execution.
 * Example: [this,"STANDARD","repair","Repair Controller","standard","ACTIVATE",false,true,false,false] call Waldo_fnc_FieldEquipmentZenSetupLocal;
 */
params [
    ["_object", objNull, [objNull]], ["_mode", "STANDARD", [""]], ["_procedure", "repair", [""]],
    ["_title", "Operate Equipment", [""]], ["_difficulty", "standard", [""]],
    ["_outcome", "COMPLETE", [""]], ["_repeat", false, [true]], ["_retry", true, [true]],
    ["_direct", false, [true]], ["_detonate", true, [true]]
];
if (isNull _object) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {false};
_object setVariable ["Waldo_FieldEquipment_Outcome", toUpperANSI _outcome, isServer];
_object setVariable ["Waldo_FieldEquipment_ZenConfigured", true, isServer];
if (toUpperANSI _mode == "EOD") then {
    [_object, createHashMapFromArray [
        ["challengeId", _procedure], ["actionTitle", _title], ["difficulty", _difficulty],
        ["detonateOnFailure", _detonate], ["oneShot", !_repeat], ["repeatable", _repeat], ["retryOnFailure", _retry],
        ["directAceAction", _direct],
        ["onSuccess", {params ["_target", "_actor"]; [_target, _actor] call Waldo_fnc_FieldEquipmentOutcomeServer;}]
    ]] call Waldo_fnc_BombDefuseSetup;
} else {
    [_object, _procedure, createHashMapFromArray [
        ["actionTitle", _title], ["difficulty", _difficulty], ["repeatable", _repeat],
        ["retryOnFailure", _retry], ["oneShot", false], ["directAceAction", _direct],
        ["onSuccess", {params ["_target", "_actor"]; [_target, _actor] call Waldo_fnc_FieldEquipmentOutcomeServer;}]
    ]] call Waldo_fnc_MiniGameInteractionSetup;
};
true
