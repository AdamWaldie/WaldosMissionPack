/*
 * Author: WaldoTheWarfighter
 * Measures interaction distance from an actor to the nearest point on an object's
 * bounding box. This avoids rejecting valid ACE interactions on tall, long or offset models
 * merely because their model origin is farther away than the configured interaction range.
 * The calculation is locality-neutral and may be used by clients and the server.
 *
 * Arguments:
 * 0: interacted object <OBJECT>
 * 1: actor <OBJECT>
 *
 * Return Value:
 * Distance to the nearest point on the object's model bounds <NUMBER>; a large value is
 * returned when either object is null.
 *
 * Called by:
 * Waldo_fnc_MiniGameInteraction client-side ACE/vanilla visibility conditions and
 * Waldo_fnc_MiniGameInteractionAcquireServer authoritative request validation.
 *
 * Example:
 * [_equipment, player] call Waldo_fnc_MiniGameInteractionRange;
 */

params [
    ["_object", objNull, [objNull]],
    ["_actor", objNull, [objNull]]
];

if (isNull _object || {isNull _actor}) exitWith {1e10};

private _actorWorld = ASLToAGL (getPosASL _actor);
private _modelPosition = _object worldToModel _actorWorld;
private _bounds = boundingBoxReal _object;
if ((count _bounds) < 2) exitWith {_actor distance _object};

private _minimum = _bounds select 0;
private _maximum = _bounds select 1;
private _nearestModelPosition = [
    ((_modelPosition select 0) max (_minimum select 0)) min (_maximum select 0),
    ((_modelPosition select 1) max (_minimum select 1)) min (_maximum select 1),
    ((_modelPosition select 2) max (_minimum select 2)) min (_maximum select 2)
];

_actorWorld distance (_object modelToWorld _nearestModelPosition)
