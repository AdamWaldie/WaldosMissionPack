/*
 * Author: WaldoTheWarfighter
 * Shared eligibility check for the Obituary "Pronounce Dead" self-interaction: true for a unit with
 * the vanilla "Medic" unit trait (the plain ACE-absent case) OR an ACE Advanced Medical role of
 * Medic or Doctor (ACE_medical_medicClass 1 or 2 - the same variable/value convention already read
 * by MissionInit/BriefingDocuments/GeneralInfo.sqf for the player's briefing text). A unit can hold
 * an ACE Medical role without the vanilla trait ever being set, so checking the trait alone excluded
 * legitimate ACE medics/doctors from ever seeing the menu.
 * Locality and authority: side-effect-free reader, safe to call on any machine; both current callers
 * are interface-client display filtering only, matching the rest of Obituary's client-local gating.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Boolean - true when the unit may pronounce corpses dead.
 *
 * Example:
 * [player] call Waldo_fnc_ObituaryIsQualifiedMedic;
 * Result: true if the unit has the vanilla Medic trait or an ACE Medic/Doctor role, false otherwise.
 * Current callers: Waldo_fnc_ObituarySelfInteractionInit (root action condition) and
 * Waldo_fnc_ObituaryChildrenLocal (child-list gate).
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {false};

(_unit getUnitTrait "Medic") || {(_unit getVariable ["ACE_medical_medicClass", 0]) > 0}
