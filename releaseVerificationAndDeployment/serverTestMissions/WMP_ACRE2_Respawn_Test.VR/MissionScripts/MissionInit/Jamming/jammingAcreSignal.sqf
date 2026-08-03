/*
 * Author: WaldoTheWarfighter
 * Installs the ACRE2 side of the jamming system. ACRE2 has no built-in jammer API - the only
 * hook is a single custom signal function (acre_api_fnc_setCustomSignalFunc) which ACRE2 calls
 * whenever it works out how well one radio hears another. This installs a function that first
 * asks ACRE2 for the normal signal (acre_sys_signal_fnc_getSignalCore) and then attenuates it by
 * the jammer registry: if either the receiving or the transmitting radio sits inside an active
 * jammer field that affects the local player's side (and matches the band), the received signal
 * strength and audio power are pushed down toward the noise floor. With no active jammers it
 * returns ACRE2's own result unchanged, so it has zero gameplay effect until a jammer exists.
 *
 * Client-local (audio is calculated per client). Only one custom signal function can exist at a
 * time in ACRE2, so this owns that hook while the jamming feature is enabled. Requires ACRE2's
 * signal model to be "LOS Multipath" (the default) or "Arcade" - the custom hook is not called
 * under "LOS Simple".
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_JammingAcreSignal;
 */

if !(hasInterface) exitWith {};
if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {};
if (missionNamespace getVariable ["Waldo_Jamming_AcreInstalled", false]) exitWith {};
missionNamespace setVariable ["Waldo_Jamming_AcreInstalled", true];

// Wait until ACRE2 is initialised before touching its signal hook.
[] spawn {
    waitUntil { sleep 1; [] call acre_api_fnc_isInitialized };

    private _jamFunc = {
        // ACRE2 passes [frequencyMHz, powerMilliwatts, receiverRadioId, transmitterRadioId].
        params ["_freq", "_power", "_rxId", "_txId"];

        // Baseline: ask ACRE2 for its normal calculation so we only ever attenuate from it.
        private _base = [1, -60];
        if !(isNil "acre_sys_signal_fnc_getSignalCore") then {
            _base = _this call acre_sys_signal_fnc_getSignalCore;
        };

        private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
        if (_registry isEqualTo []) exitWith { _base };

        // Jam if either endpoint is inside a field affecting our side on this band.
        private _sidePlayer = side player;
        private _rxPos = [];
        private _txPos = [];
        if !(isNil "acre_sys_radio_fnc_getRadioPos") then {
            _rxPos = [_rxId] call acre_sys_radio_fnc_getRadioPos;
            _txPos = [_txId] call acre_sys_radio_fnc_getRadioPos;
        } else {
            // Fallback if the helper is unavailable: the receiver is the local player.
            _rxPos = getPosASL player;
        };

        private _f1 = 0;
        if (_rxPos isEqualType [] && {count _rxPos >= 3}) then {
            _f1 = [_rxPos, _sidePlayer, _freq, _power] call Waldo_fnc_JammingFactor;
        };
        private _f2 = 0;
        if (_txPos isEqualType [] && {count _txPos >= 3}) then {
            _f2 = [_txPos, _sidePlayer, _freq, _power] call Waldo_fnc_JammingFactor;
        };

        private _jam = _f1 max _f2;
        if (_jam <= 0) exitWith { _base };

        _base params ["_pct", "_dbm"];
        _pct = (_pct * (1 - _jam)) max 0;
        // Push received strength down toward / below the noise floor so ACRE2 garbles then drops it.
        _dbm = _dbm - (_jam * 130);
        [_pct, _dbm]
    };

    [_jamFunc] call acre_api_fnc_setCustomSignalFunc;
    diag_log "[WMP JAM] ACRE2 custom signal function installed for localised jamming.";
};
