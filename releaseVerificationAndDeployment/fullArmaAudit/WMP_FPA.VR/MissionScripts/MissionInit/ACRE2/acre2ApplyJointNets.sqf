/*
 * Author: WaldoTheWarfighter
 * Programs each side's own preset with the shared TX/RX frequency of every configured joint radio
 * net (MissionConfig\acreConfig.sqf's "jointNets" key), so specific radio channels can deliberately
 * bridge chosen sides for an operation without touching WMP's ordinary per-side net isolation
 * everywhere else. Channel numbers stay per-side - each side programs whichever of its own free
 * channels was assigned to the net - only the frequency actually shared is common across sides.
 * Follows the exact verified-write pattern Waldo_fnc_ACRE2ApplyPresetNames already uses (per-client,
 * every relevant side's preset, immediate read-back verification) rather than a new one.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 *
 * Return Value: BOOL - true when every configured joint net channel was written and verified
 * (also true when jointNets is empty or ACRE is absent).
 *
 * Example: [_config] call Waldo_fnc_ACRE2ApplyJointNets;
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2SchedulePlayerRefresh's lazy gate.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE-2-Long-Range-Radio-Presetting
 */
params [["_config", missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap], [createHashMap]]];
if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {missionNamespace setVariable ["Waldo_ACRE2_JointNetsReady", true]; true};
private _jointNets = _config getOrDefault ["jointNets", []];
if (count _jointNets == 0) exitWith {missionNamespace setVariable ["Waldo_ACRE2_JointNetsReady", true]; true};
private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
private _ok = true;
{
    if (count _x != 4) then {diag_log format ["[WMP ACRE][JOINT_NETS] Skipping malformed joint net row %1.", _x];} else {
        _x params ["_netId", "_family", "_frequency", "_sideChannels"];
        private _upperFamily = toUpper _family;
        private _familyProfiles = _profiles select {toUpper (_x select 5) == _upperFamily};
        {
            _x params ["_sideKey", "_channel"];
            private _presetMap = [_config, _sideKey] call Waldo_fnc_ACRE2ResolveSidePresetMap;
            {
                private _radioClass = _x select 0;
                private _preset = _x select 1;
                private _profileIndex = _familyProfiles findIf {toUpper (_x select 0) == toUpper _radioClass};
                if (_profileIndex >= 0 && {_channel isEqualType 0} && {_channel >= 1} && {_channel <= ((_familyProfiles select _profileIndex) select 3)}) then {
                    private _writtenTx = [_radioClass, _preset, _channel, "frequencyTX", _frequency] call acre_api_fnc_setPresetChannelField;
                    private _writtenRx = [_radioClass, _preset, _channel, "frequencyRX", _frequency] call acre_api_fnc_setPresetChannelField;
                    private _readTx = [_radioClass, _preset, _channel, "frequencyTX"] call acre_api_fnc_getPresetChannelField;
                    private _readRx = [_radioClass, _preset, _channel, "frequencyRX"] call acre_api_fnc_getPresetChannelField;
                    if (!_writtenTx || {!_writtenRx} || {!(_readTx isEqualTo _frequency)} || {!(_readRx isEqualTo _frequency)}) then {
                        _ok = false;
                        diag_log format ["[WMP ACRE][JOINT_NETS] Failed to program %1 %2/%3 channel %4 for joint net %5.", _radioClass, _preset, _sideKey, _channel, _netId];
                    };
                };
            } forEach _presetMap;
        } forEach _sideChannels;
    };
} forEach _jointNets;
missionNamespace setVariable ["Waldo_ACRE2_JointNetsReady", _ok];
_ok
