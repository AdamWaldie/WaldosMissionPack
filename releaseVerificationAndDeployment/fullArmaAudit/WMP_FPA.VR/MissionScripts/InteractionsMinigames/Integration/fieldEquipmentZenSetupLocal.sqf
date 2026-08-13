/*
 * Author: WaldoTheWarfighter
 * Applies one server-approved ZEN Field Equipment definition on every machine. Interface clients
 * install the ACE/vanilla action; the server stores the callbacks and authoritative state. Object-
 * keyed JIP replacement and the shared interaction installer make reconfiguration repeat-safe.
 *
 * Arguments:
 * 0 object <OBJECT>; 1 mode <STRING>; 2 procedure <STRING>; 3 action title <STRING>;
 * 4 difficulty <STRING>; 5 repeat after success <BOOL>; 6 retry after failure <BOOL>;
 * 7 direct ACE action <BOOL>; 8 EOD detonate on failure <BOOL>. Result presets and custom callback
 * code are retained only by the authoritative server; clients receive this presentation/action
 * definition but never compile or execute curator-supplied code.
 * Return Value: Boolean.
 * Current caller: FIELD_EQUIPMENT action in Waldo_fnc_FeatureRuntimeApply via JIP remote execution.
 * Example: [this,"STANDARD","repair","Repair Controller","standard",false,true,false,false] call Waldo_fnc_FieldEquipmentZenSetupLocal;
 */
params [
    ["_object", objNull, [objNull]], ["_mode", "STANDARD", [""]], ["_procedure", "repair", [""]],
    ["_title", "Operate Equipment", [""]], ["_difficulty", "standard", [""]],
    ["_repeat", false, [true]], ["_retry", true, [true]],
    ["_direct", false, [true]], ["_detonate", true, [true]]
];
if (isNull _object) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {false};
if (toUpperANSI _mode == "EOD") then {
    [_object, createHashMapFromArray [
        ["challengeId", _procedure], ["actionTitle", _title], ["difficulty", _difficulty],
        ["detonateOnFailure", _detonate], ["oneShot", !_repeat], ["repeatable", _repeat], ["retryOnFailure", _retry],
        ["directAceAction", _direct],
        ["onSuccess", {params ["_target", "_actor", "_success", ["_result", []]]; [_target, _actor, true, _result] call Waldo_fnc_FieldEquipmentOutcomeServer;}],
        ["onFailure", {params ["_target", "_actor", "_success", ["_result", []]]; [_target, _actor, false, _result] call Waldo_fnc_FieldEquipmentOutcomeServer;}]
    ]] call Waldo_fnc_BombDefuseSetup;
} else {
    [_object, _procedure, createHashMapFromArray [
        ["actionTitle", _title], ["difficulty", _difficulty], ["repeatable", _repeat],
        ["retryOnFailure", _retry], ["oneShot", false], ["directAceAction", _direct],
        ["onSuccess", {params ["_target", "_actor", "_success", ["_result", []]]; [_target, _actor, true, _result] call Waldo_fnc_FieldEquipmentOutcomeServer;}],
        ["onFailure", {params ["_target", "_actor", "_success", ["_result", []]]; [_target, _actor, false, _result] call Waldo_fnc_FieldEquipmentOutcomeServer;}]
    ]] call Waldo_fnc_MiniGameInteractionSetup;
};
true
