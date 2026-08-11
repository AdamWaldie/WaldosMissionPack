/*
 * Author: WaldoTheWarfighter
 * Installed as the body of the CBA "CAManBase" "Killed" class handler. Fires on every machine
 * (Killed is a global-effect event handler), redundantly computing and broadcasting the same
 * deterministic values to the same corpse object - harmless, since nothing here touches shared
 * registry state. Its purpose is to fix a real bug in the reference script this feature replaces:
 * every name-dependent value (victim name, instigator name) and the full cause-of-death
 * classification are computed HERE, synchronously, while _unit/_killer/_instigator are still
 * guaranteed valid - not deferred to whatever later moment a medic performs the Pronounce Dead
 * action, by which time the relevant player may have disconnected and `name` on their stale
 * object reference could resolve incorrectly. Everything downstream (Waldo_fnc_ObituaryPronounce)
 * reads only the cached plain-data fields this writes, never re-deriving a name from an object.
 * Also flags friendly fire immediately via a systemChat broadcast, suppressing that flag when the
 * instigator is a Zeus curator remote-controlling a unit (getAssignedCuratorLogic is the only
 * mechanism in this codebase that distinguishes a real human player from a curator possessing a
 * unit, since both make isPlayer true).
 * Locality and authority: runs on whichever machine the Killed event fires on for the dying unit;
 * only ever writes to that unit's own object variables, never shared/registry state, so no
 * server-authority or self-forwarding is needed here.
 *
 * Arguments:
 * 0: Event args <ARRAY> - the raw CBA class-handler event args: [unit, killer, instigator,
 *    useEffects, shot, real]
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["CAManBase", "Killed", { [_this] call Waldo_fnc_ObituaryRecordDeath; }] call CBA_fnc_addClassEventHandler;
 * Result: a dead player's corpse carries a cached Waldo_Obituary_DeathInfo record ready for pronounce.
 * Current caller: Waldo_fnc_ObituaryInit, installing the class handler.
 */

params ["_eventArgs"];
_eventArgs params ["_unit", "_killer", "_instigator", "_useEffects", "_shot", "_real"];
if !(isPlayer [_unit]) exitWith {};

private _side = side group _unit;
if (isNull _instigator) then { _instigator = _killer; };

private _isCurator = !(isNull (getAssignedCuratorLogic _instigator));
private _isFriendlyFire = isPlayer _instigator && {!isNull _instigator} && {_instigator != _unit}
    && {side group _instigator == _side} && {!_isCurator};
private _instigatorName = if (isPlayer _instigator) then {name _instigator} else {""};
private _causeText = [_unit, _killer, _instigator, _shot, _isFriendlyFire, _instigatorName]
    call Waldo_fnc_ObituaryClassifyCause;

if (_isFriendlyFire) then {
    [format ["%1 was killed by %2 (Friendly Fire)", name _unit, _instigatorName]] remoteExec ["systemChat", 0];
};

private _cardinals = ["N","NE","E","SE","S","SW","W","NW"];
private _direction = if (isNull _killer) then {""} else {
    _cardinals select (floor ((([_unit, _killer] call BIS_fnc_dirTo) + 22.5) / 45) % 8)
};

private _deathInfo = [
    date,             // 0: time of death
    name _unit,       // 1: victim name, cached
    _causeText,       // 2: fully resolved cause text, cached
    _isFriendlyFire,  // 3
    _instigatorName,  // 4: cached, "" if not applicable
    _direction,       // 5
    getPos _unit,     // 6
    _side             // 7
];
_unit setVariable ["Waldo_Obituary_DeathInfo", _deathInfo, true];
_unit setVariable ["Waldo_Obituary_Complete", false, true];
