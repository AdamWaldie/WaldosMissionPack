/*
 * Author: WaldoTheWarfighter
 * Applies and profile-persists a personal colour-vision accessibility profile. It immediately
 * restyles every open WMP display and can show symbol-labelled semantic preview cards. No state is
 * broadcast: different players may use different profiles under the same mission-wide era theme.
 *
 * Arguments:
 * 0: profile id <STRING>
 * 1: show preview notifications <BOOL> (default true)
 *
 * Return Value: BOOL - true when a known profile was applied.
 *
 * Example:
 * ["TRITAN", true] call Waldo_fnc_UiColourVisionApplyLocal;
 * Current caller: UiColourVisionOpenLocal selection buttons.
 */

if (!hasInterface) exitWith {false};
params [["_profileId", "STANDARD", [""]], ["_preview", true, [true]]];
_profileId = toUpperANSI _profileId;
private _profile = [_profileId] call Waldo_fnc_UiColourVisionProfile;
if ((_profile getOrDefault ["id", "STANDARD"]) != _profileId) exitWith {false};
profileNamespace setVariable ["Waldo_UI_ColourVisionProfile", _profileId];
saveProfileNamespace;
missionNamespace setVariable ["Waldo_UI_ColourVisionProfileLocal", _profileId];
[missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"], false] call Waldo_fnc_UiThemeApplyLocal;
if (_preview) then {
    private _label = _profile getOrDefault ["label", _profileId];
    ["COLOUR VISION", format ["%1 is active. Every state also retains its word and symbol.", _label], "INFO", 9, "TOP_RIGHT", "ACCESSIBILITY_COLOUR", "ACCESSIBILITY", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["SUCCESS SAMPLE", "[OK] Completed state", "SUCCESS", 9, "TOP_RIGHT", "ACCESSIBILITY_SUCCESS", "ACCESSIBILITY", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["WARNING SAMPLE", "[!] Attention state", "WARNING", 9, "TOP_RIGHT", "ACCESSIBILITY_WARNING", "ACCESSIBILITY", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["ERROR SAMPLE", "[X] Failure state", "ERROR", 9, "TOP_RIGHT", "ACCESSIBILITY_ERROR", "ACCESSIBILITY", "REPLACE"] call Waldo_fnc_ShowUiNotification;
};
true
