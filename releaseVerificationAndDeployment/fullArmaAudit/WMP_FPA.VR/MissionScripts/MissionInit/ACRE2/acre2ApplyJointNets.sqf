/*
 * Author: WaldoTheWarfighter
 * Programs each side's own preset with the shared TX/RX frequency of every configured joint radio
 * net (MissionConfig\acreConfig.sqf's "jointNets" key), so specific radio channels can deliberately
 * bridge chosen sides for an operation without touching WMP's ordinary per-side net isolation
 * everywhere else. Channel numbers stay per-side - each side programs whichever of its own free
 * channels was assigned to the net - only the frequency actually shared is common across sides.
 * Follows the exact verified-write pattern Waldo_fnc_ACRE2ApplyPresetNames already uses (per-client,
 * every relevant side's preset, immediate read-back verification) rather than a new one. Row shape
 * deliberately mirrors an ordinary named net's [key, label, family, value] - label sits right after
 * the id, same position, same meaning - with the per-side channel list appended after, since a joint
 * net needs to say where on EACH side's preset the shared frequency lands. "" means no label, written
 * to the physical PRC-148/152/117F channel display with the exact same sanitisation/truncation and
 * verification Waldo_fnc_ACRE2ApplyPresetNames already uses for ordinary named nets - so a joint net
 * can visibly read as "COALITION" (or similar) on the radio itself, rather than only appearing as a
 * plain channel number.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 *
 * Return Value: BOOL - true when every configured joint net channel (and label, if present) was
 * written and verified (also true when jointNets is empty or ACRE is absent).
 *
 * Example: [_config] call Waldo_fnc_ACRE2ApplyJointNets;
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2SchedulePlayerRefresh's lazy gate.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/ACRE-2-Long-Range-Radio-Presetting
 */
params [["_config", missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap], [createHashMap]]];
if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {missionNamespace setVariable ["Waldo_ACRE2_JointNetsReady", true]; true};
private _jointNets = _config getOrDefault ["jointNets", []];
if (count _jointNets == 0) exitWith {missionNamespace setVariable ["Waldo_ACRE2_JointNetsReady", true]; true};
private _namedDisplays = _config getOrDefault ["namedDisplays", true];
private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
private _ok = true;
{
    if !(_x isEqualType [] && {count _x == 5}) then {diag_log format ["[WMP ACRE][JOINT_NETS] Skipping malformed joint net row %1.", _x];} else {
        _x params ["_netId", "_label", "_family", "_frequency", "_sideChannels"];
        private _upperFamily = toUpper _family;
        private _familyProfiles = _profiles select {toUpper (_x select 5) == _upperFamily};
        // Same sanitisation/12-char truncation Waldo_fnc_ACRE2ApplyPresetNames already uses for
        // ordinary named nets, so a joint net's physical display looks identical in style.
        private _safeLabel = "";
        {if (_x in (toArray "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_/")) then {_safeLabel = _safeLabel + toString [_x]}} forEach toArray (toUpper _label);
        if (count _safeLabel > 12) then {_safeLabel = _safeLabel select [0, 12]};
        // Only CHANNEL-mode families (PRC_LR, BF888, SEM52) use a per-side channel-index slot; skip
        // anything else defensively (Waldo_fnc_ACRE2ValidateConfig already rejects it at config load,
        // so this should never actually trigger, but a plain channel number silently mis-programming a
        // FREQUENCY-mode preset - or writing nothing at all, since those profiles report a maximum
        // channel of 0 - is exactly the failure mode worth guarding against here too).
        if (count _familyProfiles > 0 && {(_familyProfiles select 0) select 1 != "CHANNEL"}) then {
            diag_log format ["[WMP ACRE][JOINT_NETS] Skipping joint net %1: radio family %2 is not CHANNEL-mode.", _netId, _family];
        } else {
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
                    // Display label is PRC_LR-only, matching Waldo_fnc_ACRE2ApplyPresetNames - BF888/
                    // SEM52 have no equivalent on-screen display field.
                    if (_namedDisplays && {_safeLabel != ""} && {_upperFamily == "PRC_LR"}) then {
                        private _displayField = switch (toUpper _radioClass) do {
                            case "ACRE_PRC148": {"label"}; case "ACRE_PRC152": {"description"}; case "ACRE_PRC117F": {"name"}; default {""};
                        };
                        if (_displayField != "") then {
                            private _txBefore = [_radioClass, _preset, _channel, "frequencyTX"] call acre_api_fnc_getPresetChannelField;
                            private _rxBefore = [_radioClass, _preset, _channel, "frequencyRX"] call acre_api_fnc_getPresetChannelField;
                            private _writtenLabel = [_radioClass, _preset, _channel, _displayField, _safeLabel] call acre_api_fnc_setPresetChannelField;
                            private _readLabel = [_radioClass, _preset, _channel, _displayField] call acre_api_fnc_getPresetChannelField;
                            private _txAfter = [_radioClass, _preset, _channel, "frequencyTX"] call acre_api_fnc_getPresetChannelField;
                            private _rxAfter = [_radioClass, _preset, _channel, "frequencyRX"] call acre_api_fnc_getPresetChannelField;
                            if (!_writtenLabel || {_readLabel != _safeLabel} || {!(_txBefore isEqualTo _txAfter)} || {!(_rxBefore isEqualTo _rxAfter)}) then {
                                _ok = false;
                                diag_log format ["[WMP ACRE][JOINT_NETS] Display-name verification failed for %1 %2/%3 channel %4 (%5).", _radioClass, _preset, _sideKey, _channel, _netId];
                            };
                        };
                    };
                };
            } forEach _presetMap;
        } forEach _sideChannels;
        };
    };
} forEach _jointNets;
missionNamespace setVariable ["Waldo_ACRE2_JointNetsReady", _ok];
_ok
