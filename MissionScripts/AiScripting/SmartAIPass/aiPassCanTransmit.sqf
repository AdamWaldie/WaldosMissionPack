/*
 * Author: WaldoTheWarfighter
 * Decides whether a soldier can pass information or call for support by radio.
 *
 * AI communications do not require an inventory radio item.
 * Radio jamming always applies: a soldier standing where Waldo_fnc_JammingFactor reports 0.5 or more
 * for his side cannot transmit, so a placed jammer cuts AI reports, reinforcement calls and
 * artillery requests exactly as it does for players.
 * Locality and authority: read-only; callable anywhere.
 *
 * Arguments:
 * 0: unit <OBJECT>
 *
 * Return Value:
 * Boolean - true when the unit can transmit
 *
 * Example:
 * if ([leader _group] call Waldo_fnc_AIPassCanTransmit) then {...};
 * Result: a jammed squad leader cannot call for help.
 *
 * Current callers: Waldo_fnc_AIPassContactReport, Waldo_fnc_AIPassReinforce and Waldo_fnc_AIPassArtilleryRequest.
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit || {!alive _unit}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Jamming_Enable", true]) exitWith {true};
([getPosASL _unit, side group _unit] call Waldo_fnc_JammingFactor) < 0.5
