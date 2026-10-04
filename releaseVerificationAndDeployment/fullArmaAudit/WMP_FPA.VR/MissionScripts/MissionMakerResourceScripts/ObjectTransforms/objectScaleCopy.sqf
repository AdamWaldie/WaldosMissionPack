/*
 * Author: WaldoTheWarfighter
 * Copies the source object's actual engine render scale to a target object.
 * Locality and authority: Reads the source scale where called and delegates target validation
 * and mutation to server-authoritative Waldo_fnc_ObjectScale.
 * Repeat/JIP: Each call reapplies the current source scale. The resulting world-object state is
 * shared with JIP; callers must retain a replacement target after conversion.
 *
 * The operation is server-authoritative through Waldo_fnc_ObjectScale. By default an unsupported
 * ordinary target is converted to a Simple Object, so this is intended for grounded decorative
 * props only. The returned replacement must be retained. Currently called by the full-pack audit
 * station and available as Waldo_fnc_ObjectScaleCopy to mission scripts.
 *
 * Arguments:
 * 0: source <OBJECT>
 * 1: target <OBJECT>
 * 2: convertTargetToSimpleObject <BOOLEAN> (default: true)
 *
 * Return Value:
 * Object - scaled target or objNull
 *
 * Example:
 * private _scaledTarget = [sourceProp, targetProp, true] call Waldo_fnc_ObjectScaleCopy;
 * Result: The server returns the scaled target Object or objNull. A forwarded client call does
 * not confirm the later server result.
 * Current callers: Mission scripts using Waldo_fnc_ObjectScaleCopy and the full-pack audit station.
 */

params [["_source", objNull, [objNull]], ["_target", objNull, [objNull]], ["_asSimple", true, [false]]];
if (isNull _source || {isNull _target}) exitWith {objNull};
[_target, getObjectScale _source, _asSimple] call Waldo_fnc_ObjectScale
