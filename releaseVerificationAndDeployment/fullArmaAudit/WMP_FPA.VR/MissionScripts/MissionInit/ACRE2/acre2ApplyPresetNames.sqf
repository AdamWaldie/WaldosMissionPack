/*
 * Author: WaldoTheWarfighter
 * Applies safe twelve-character names to each radio's official display-name field in the existing
 * ACRE side presets. It snapshots TX/RX fields, verifies the text write and reports frequency drift.
 *
 * Arguments:
 * 0: configuration <HASHMAP>
 *
 * Return Value: BOOL - true when every requested label was applied and verified.
 *
 * Example: [_config] call Waldo_fnc_ACRE2ApplyPresetNames;
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2Init retry path.
 */
params [['_config', missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap], [createHashMap]]];
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {true};
if !(_config getOrDefault ['namedDisplays', true]) exitWith {true};
private _ok = true;
private _profiles = [_config] call Waldo_fnc_ACRE2GetRadioProfiles;
{
    _x params ['_sideKey', '_preset', '_nets'];
    {
        private _label = toUpper (_x select 1);
        private _safe = '';
        {if (_x in (toArray 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_/')) then {_safe = _safe + toString [_x]}} forEach toArray _label;
        if (count _safe > 12) then {_safe = _safe select [0, 12]};
        private _family = toUpper (_x select 2);
        private _channel = _x select 3;
        if (_family == 'PRC_LR') then {
        {
            _x params ['_radioClass', '_displayField'];
            private _profileIndex = _profiles findIf {toUpper (_x select 0) == _radioClass};
            if (_profileIndex >= 0 && {_channel isEqualType 0} && {_channel >= 1} && {_channel <= ((_profiles select _profileIndex) select 3)}) then {
            private _tx = [_radioClass, _preset, _channel, 'frequencyTX'] call acre_api_fnc_getPresetChannelField;
            private _rx = [_radioClass, _preset, _channel, 'frequencyRX'] call acre_api_fnc_getPresetChannelField;
            private _written = [_radioClass, _preset, _channel, _displayField, _safe] call acre_api_fnc_setPresetChannelField;
            private _read = [_radioClass, _preset, _channel, _displayField] call acre_api_fnc_getPresetChannelField;
            private _txAfter = [_radioClass, _preset, _channel, 'frequencyTX'] call acre_api_fnc_getPresetChannelField;
            private _rxAfter = [_radioClass, _preset, _channel, 'frequencyRX'] call acre_api_fnc_getPresetChannelField;
            if (!_written || {_read != _safe} || {!(_tx isEqualTo _txAfter)} || {!(_rx isEqualTo _rxAfter)}) then {
                _ok = false;
                diag_log format ['[WMP ACRE] Preset display-name verification failed for %1/%2 channel %3 (%4).', _radioClass, _preset, _channel, _sideKey];
            };
            };
        } forEach [['ACRE_PRC148', 'label'], ['ACRE_PRC152', 'description'], ['ACRE_PRC117F', 'name']];
        };
    } forEach _nets;
} forEach (_config getOrDefault ['sides', []]);
missionNamespace setVariable ['Waldo_ACRE2_PresetNamesReady', _ok];
_ok
