/*
 * Author: WaldoTheWarfighter
 * Restores the vanilla Zeus "press END to instantly kill whatever the cursor is on" shortcut, which a
 * later Arma engine update broke by making that native shortcut respect `allowDamage` - any unit or
 * object a mission had made damage-immune (including WMP's own SafeStart/ENDEX freeze) silently
 * stopped dying to it, with no error or feedback. This installs a mission-wide "KeyDown" handler that
 * only acts while this client's Zeus curator interface is actually open, so it never intercepts the
 * END key anywhere else (menus, chat, a player's own game).
 * Unconditional, not an opt-in feature - there is no config toggle. It is installed on every
 * interface client regardless of what else is loaded; Zeus Enhanced itself is not required (every
 * command used - curatorSelected, curatorMouseOver, getAssignedCuratorLogic - is vanilla Arma, so
 * this works under plain Zeus too). ZEN's own source (github.com/zen-mod/ZEN, checked directly -
 * editor/fnc_handleKeyDown.sqf, damage/, context_actions/, context_menu/, and its release notes) does
 * not implement any force-kill/force-destroy bypass of its own to defer to; the "Force Destroy"
 * behaviour some players know from a Ctrl+double-click keybind comes from a separate third-party
 * addon, not ZEN core, so there is no ZEN system to route through here.
 * Every kill it finds goes through the same call, with no "selected vs. hovered" either/or: both the
 * curator's box-selected entities (`curatorSelected`) and whatever is directly under the cursor
 * (`curatorMouseOver`) are combined into one deduplicated target list every press, so pressing END
 * always kills everything currently selected AND whatever is being hovered, not just one or the
 * other. Waldo_fnc_KillUnit itself is what varies by mod load: it force-clears `allowDamage` and, only
 * when ACE medical is present, kills a person through ACE's own death API instead of a bare
 * `setDamage 1` - a load-dependent effect, never a mission-config toggle.
 * Repeat/JIP-safe: guarded by a missionNamespace flag so a respawn or reconnect never installs a
 * second handler on the same client. Player-interface only - dedicated servers and headless clients
 * have no keyboard input and no consumer for this.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true once the handler is installed (or was already installed on this client)
 *
 * Example:
 * [] call Waldo_fnc_KillHotkeyInit;
 * Current caller: initPlayerLocal.sqf.
 */

if !(hasInterface) exitWith {false};
if (missionNamespace getVariable ["Waldo_KillHotkey_Installed", false]) exitWith {true};
missionNamespace setVariable ["Waldo_KillHotkey_Installed", true];

addMissionEventHandler ["KeyDown", {
    params ["_dikCode"];
    if (_dikCode != 207) exitWith {false}; // DIK_END = 207 (0xCF) - the vanilla Zeus "Kill" shortcut's own key.
    if (isNull findDisplay 312) exitWith {false}; // Zeus curator interface is not open on this client.

    if (isNull (getAssignedCuratorLogic player)) exitWith {false}; // this client is not an assigned curator.

    // curatorSelected is nular (no operand) and returns [objects, groups, waypoints, markers].
    private _selected = (curatorSelected) select 0;
    // curatorMouseOver returns ["OBJECT", object] under a curator-editable object, [""] over empty
    // ground, or [] entirely outside curator mode - never the object on its own.
    private _mouseOver = curatorMouseOver;
    private _hovered = if (count _mouseOver > 1 && {(_mouseOver select 0) == "OBJECT"}) then {_mouseOver select 1} else {objNull};
    private _candidates = _selected + (if (isNull _hovered) then {[]} else {[_hovered]});
    private _targets = (_candidates arrayIntersect _candidates) select {!isNull _x && {_x isKindOf "AllVehicles" || {_x isKindOf "Man"}}};
    if (_targets isEqualTo []) exitWith {false};

    private _killed = 0;
    {
        if (alive _x) then {
            if ([_x] call Waldo_fnc_KillUnit) then {_killed = _killed + 1};
        };
    } forEach _targets;

    if (_killed > 0) then {
        ["ZEUS", format ["%1 %2 killed.", _killed, if (_killed == 1) then {"target"} else {"targets"}], "SUCCESS", "KILL_HOTKEY", 4] call Waldo_fnc_FeatureNotifyLocal;
        diag_log format ["[WMP KILL] END-key hotkey killed %1 target(s) curator=%2", _killed, name player];
    };
    true // Consume the key so nothing else in the Zeus interface tries to act on it too.
}];

diag_log format ["[WMP KILL] End-key kill hotkey installed on clientOwner=%1", clientOwner];
true
