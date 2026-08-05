/*
 * Author: WaldoTheWarfighter, Val
 * Determines whether one local player may use the dual-purpose WMP HUD. Accessibility UIDs may
 * always use it without campaign equipment; other players require configured headgear, facewear
 * or NVGs unless the mission deliberately enables unrestricted access. Exclusions win over every
 * other route. This function changes no state and is safe to call from per-frame drawing and ACE
 * interaction conditions.
 * Locality and authority: local read-only eligibility check; it publishes no player or HUD state.
 *
 * Arguments:
 * 0: unit <OBJECT> - player unit to evaluate (default player)
 *
 * Return Value:
 * Boolean - true when the unit currently has an approved WMP HUD access route.
 *
 * Example:
 * [player] call Waldo_fnc_WmpHudEligible;
 * Result: true for an accessibility UID or a player wearing configured campaign HUD equipment.
 * Current callers: Waldo_fnc_WmpHudInit Draw3D handler and WMP HUD self-interaction conditions.
 */

params [["_unit", player, [objNull]]];
if (isNull _unit || {!isPlayer _unit}) exitWith {false};

private _uid = getPlayerUID _unit;
if (_uid in (missionNamespace getVariable ["Waldo_WmpHud_ExcludedUIDs", []])) exitWith {false};
if (_uid in (missionNamespace getVariable ["Waldo_WmpHud_AccessibilityUIDs", []])) exitWith {true};
if (missionNamespace getVariable ["Waldo_WmpHud_AllowEveryone", false]) exitWith {true};

(headgear _unit) in (missionNamespace getVariable ["Waldo_WmpHud_Headgear", []])
|| {(goggles _unit) in (missionNamespace getVariable ["Waldo_WmpHud_Facewear", []])}
|| {(hmd _unit) in (missionNamespace getVariable ["Waldo_WmpHud_NVGs", []])}
