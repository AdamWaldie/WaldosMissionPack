/*
 * Author: WaldoTheWarfighter
 * Installs the additive Zeus END-key kill fallback. Arma receives and handles the original key press
 * first; on the next scheduled frame, WMP applies `setDamage 1` to any objects that were selected
 * when plain END was pressed and are still alive. Hovered objects are deliberately excluded.
 *
 * Locality and authority: Runs only on interface clients. The handler requires the local player to
 * have an assigned curator and attaches only to that client's curator display. `setDamage` accepts a
 * remote object and has a global effect, so no unauthenticated server remote-execution bridge is
 * exposed. The handler always returns false and therefore never consumes or replaces vanilla/ZEN
 * END-key behaviour.
 *
 * Repeat and JIP behaviour: `initPlayerLocal.sqf` calls this once for every player, including JIP.
 * A missionNamespace guard starts one local watcher. The watcher installs one tracked KeyDown event
 * handler on each newly opened curator display, including later reopenings, and removes any stale
 * tracked handler before installation.
 *
 * Arguments:
 * None.
 *
 * Return Value:
 * Boolean - true when the local display watcher is running or was already running; false without an
 * interface.
 *
 * Current callers:
 * `initPlayerLocal.sqf` during player-local startup.
 *
 * Example:
 * [] call Waldo_fnc_KillHotkeyInit;
 */

if !(hasInterface) exitWith {false};
if (missionNamespace getVariable ["Waldo_KillHotkey_WatcherStarted", false]) exitWith {true};
missionNamespace setVariable ["Waldo_KillHotkey_WatcherStarted", true];

[] spawn {
    while {hasInterface} do {
        waitUntil {
            uiSleep 0.1;
            !isNull (findDisplay 312)
        };

        private _display = findDisplay 312;
        private _oldHandler = _display getVariable ["Waldo_KillHotkey_KeyDownHandler", -1];
        if (_oldHandler >= 0) then {
            _display displayRemoveEventHandler ["KeyDown", _oldHandler];
        };

        private _handler = _display displayAddEventHandler ["KeyDown", {
            params ["_display", "_keyCode", "_shift", "_ctrl", "_alt"];

            // DIK_END is 207. Modifier combinations remain available to other Zeus/addon actions.
            if (_keyCode != 207 || {_shift || {_ctrl || {_alt}}}) exitWith {false};
            if (isNull (getAssignedCuratorLogic player)) exitWith {false};

            // Capture the selection now, but apply the fallback after Arma has processed END itself.
            private _selectedObjects = (curatorSelected select 0) select {
                !isNull _x && {alive _x}
            };

            if !(_selectedObjects isEqualTo []) then {
                [_selectedObjects] spawn {
                    params ["_targets"];
                    uiSleep 0;

                    private _fallbackCount = 0;
                    {
                        if (!isNull _x && {alive _x}) then {
                            _x setDamage 1;
                            _fallbackCount = _fallbackCount + 1;
                        };
                    } forEach _targets;

                    if (_fallbackCount > 0) then {
                        diag_log format [
                            "[WMP KILL] Applied additive END-key setDamage fallback to %1 selected object(s).",
                            _fallbackCount
                        ];
                    };
                };
            };

            false
        }];

        _display setVariable ["Waldo_KillHotkey_KeyDownHandler", _handler];
        diag_log format ["[WMP KILL] Additive END-key handler installed on curator display for clientOwner=%1.", clientOwner];

        waitUntil {
            uiSleep 0.1;
            isNull _display
        };
    };
};

true
