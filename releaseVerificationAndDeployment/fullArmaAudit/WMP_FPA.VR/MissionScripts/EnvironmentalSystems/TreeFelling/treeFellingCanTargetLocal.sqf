/*
 * Author: WaldoTheWarfighter
 * Performs the cheap, cached interface-local eligibility check used by the Tree Felling action and
 * optional IMS swing hook. Expensive model-path inspection runs only when the cursor target or the
 * runtime Tree Felling configuration epoch changes.
 * Locality/authority: interface-local presentation predicate only; it never changes world state.
 * Repeat/JIP behaviour: repeat-safe, JIP-safe and inert while Tree Felling is disabled. The cache is
 * local to the interface client and is invalidated by runtime configuration changes and cleanup.
 * Arguments: target OBJECT (default cursorObject), unit OBJECT (default player).
 * Return Value: BOOL - true when the current target can be submitted as a cutting/brush target.
 * Current callers: TreeFellingInit addAction condition and TreeFellingSwing.
 * Example: [cursorObject, player] call Waldo_fnc_TreeFellingCanTargetLocal;
 */
params [
    ["_target", cursorObject, [objNull]],
    ["_unit", player, [objNull]]
];
if (!hasInterface || {isNull _unit} || {!local _unit}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_TreeFelling_Enable", false]) exitWith {false};
if (vehicle _unit != _unit || {isNull _target}) exitWith {false};
if (_unit distance _target > (missionNamespace getVariable ["Waldo_TreeFelling_Range", 3])) exitWith {false};

private _epoch = missionNamespace getVariable ["Waldo_TreeFelling_ConfigEpoch", 0];
private _cache = uiNamespace getVariable ["Waldo_TreeFelling_TargetCache", []];
if (count _cache == 3 && {(_cache select 0) isEqualTo _target} && {(_cache select 1) == _epoch}) exitWith {_cache select 2};

private _model = toLowerANSI ((getModelInfo _target) param [1, ""]);
private _valid = _model find "tree" >= 0
    || {typeOf _target in (missionNamespace getVariable ["Waldo_TreeFelling_AllowedClasses", []])}
    || {(missionNamespace getVariable ["Waldo_TreeFelling_ClearBushes", false]) && {_model find "bush" >= 0}};
uiNamespace setVariable ["Waldo_TreeFelling_TargetCache", [_target, _epoch, _valid]];
_valid
