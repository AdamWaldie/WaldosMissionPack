/*
 * Author: WaldoTheWarfighter, Val
 * Plays local radiation feedback for one hazard profile. audioEnabled/coughEnabled default true (a
 * profile opts OUT with an explicit false, not in) so a mission maker's own hazard profile still gets
 * Geiger/cough feedback without remembering to ask for it; a profile with no geiger/cough sound pools
 * configured still plays nothing, since the sound lookups below no-op on an empty array either way.
 * Geiger cadence increases with current zone intensity; low/high pools are independently configurable.
 * Injury coughs require actual damaging exposure and use a separate cooldown. All timing state is
 * local and keyed by zone, preventing JIP traffic or notification spam.
 * Locality and authority: interface-client audio only; no sound cadence or exposure state is broadcast.
 *
 * Arguments:
 * 0: hazard key <STRING>
 * 1: profile <HASHMAP>
 * 2: inside <BOOL>
 * 3: intensity <NUMBER 0-1>
 * 4: exposure <NUMBER>
 * 5: current tick damage <NUMBER>
 * 6: hazard-aware <BOOL> - detector/awareness result for this player.
 *
 * Return Value: Nothing.
 *
 * Example:
 * ["REACTOR", _profile, true, 0.8, 24, 0.02, true] call Waldo_fnc_HazardAudioFeedback;
 * Result: selects a high-intensity Geiger sound and may cough if the injury cooldown is clear.
 * Current caller: Waldo_fnc_HazardTick after exposure and damage have been evaluated locally.
 */

params ["_key", "_profile", "_inside", "_intensity", "_exposure", "_damage", "_aware"];
if (!hasInterface || {!(_profile getOrDefault ["audioEnabled", true])}) exitWith {};
if ((_profile getOrDefault ["audioRequiresAwareness", false]) && {!_aware}) exitWith {};

private _timers = missionNamespace getVariable ["Waldo_Hazard_LocalAudioTimers", createHashMap];
private _now = diag_tickTime;
if (_inside && {_intensity > 0}) then {
    private _nextGeiger = _timers getOrDefault [format ["GEIGER_%1", _key], 0];
    if (_now >= _nextGeiger) then {
        private _split = (_profile getOrDefault ["geigerHighIntensity", 0.5]) max 0 min 1;
        private _sounds = _profile getOrDefault [
            if (_intensity >= _split) then {"geigerHighSounds"} else {"geigerLowSounds"},
            []
        ];
        if !(_sounds isEqualTo []) then {playSound (selectRandom _sounds)};
        private _slow = (_profile getOrDefault ["geigerMaximumInterval", 2.5]) max 0.1;
        private _fast = ((_profile getOrDefault ["geigerMinimumInterval", 0.45]) max 0.1) min _slow;
        _timers set [format ["GEIGER_%1", _key], _now + linearConversion [0, 1, _intensity, _slow, _fast, true]];
    };
};

if (_damage > 0 && {_profile getOrDefault ["coughEnabled", true]}) then {
    private _nextCough = _timers getOrDefault ["COUGH", 0];
    if (_now >= _nextCough) then {
        private _sounds = _profile getOrDefault ["coughSounds", []];
        if !(_sounds isEqualTo []) then {player say (selectRandom _sounds)};
        _timers set ["COUGH", _now + ((_profile getOrDefault ["coughCooldown", 12]) max 1)];
    };
};
missionNamespace setVariable ["Waldo_Hazard_LocalAudioTimers", _timers];
