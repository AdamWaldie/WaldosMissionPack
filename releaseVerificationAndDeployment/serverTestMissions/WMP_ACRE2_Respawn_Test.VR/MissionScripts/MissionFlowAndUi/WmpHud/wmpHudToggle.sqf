/*
 * Author: WaldoTheWarfighter, Val
 * Toggles the local WMP HUD without changing mission-wide configuration. Eligibility is checked
 * before enabling so removing campaign HUD equipment immediately prevents ordinary users from
 * bypassing its requirement; configured accessibility UIDs remain eligible without equipment.
 * Locality and authority: interface-client visibility only; remote callers are rejected.
 *
 * Arguments:
 * 0: state <BOOLEAN> - optional explicit state; omitted toggles the current local state.
 *
 * Return Value:
 * Boolean - resulting local visibility state.
 *
 * Example:
 * [true] call Waldo_fnc_WmpHudToggle;
 * Result: enables the HUD locally when the player has an approved access route.
 * Current caller: WMP Interface > WMP HUD self-interaction.
 */

if !(hasInterface) exitWith {false};
if (remoteExecutedOwner > 0) exitWith {false};
private _state = if (count _this > 0) then {_this select 0} else {
    !(missionNamespace getVariable ["Waldo_WmpHud_Visible", false])
};
if !(_state isEqualType true) exitWith {false};
if (_state && {!([player] call Waldo_fnc_WmpHudEligible)}) exitWith {
    ["WMP HUD", "Configured HUD equipment is required.", "WARNING", "WMP_HUD"] call Waldo_fnc_FeatureNotifyLocal;
    false
};
missionNamespace setVariable ["Waldo_WmpHud_Visible", _state];
["WMP HUD", format ["%1 %2.", missionNamespace getVariable ["Waldo_WmpHud_SystemName", "WMP HUD"], ["disabled", "enabled"] select _state], "INFO", "WMP_HUD"] call Waldo_fnc_FeatureNotifyLocal;
_state
