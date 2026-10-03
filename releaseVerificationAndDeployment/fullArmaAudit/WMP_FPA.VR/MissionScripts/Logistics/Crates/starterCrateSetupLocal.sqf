/*
 * Author: WaldoTheWarfighter
 * Installs the local starter-crate identifier and save-loadout interaction.
 * Repeat-safe and suitable for current clients plus JIP replay.
 * Arguments: 0: starter crate <OBJECT>
 * Return Value: Boolean
 * Locality and authority: Installs object actions only on each interface client; the server
 * creates the crate and publishes an object-scoped JIP setup call. Repeating local setup keeps
 * the identifier action from duplicating.
 * Current caller: Waldo_fnc_DoStarterCrate during initial and JIP client setup.
 * Example: [starterCrate] call Waldo_fnc_StarterCrateSetupLocal;
 * Result: Players can recognise the starter crate and save their loadout there.
 */

params [["_target", objNull, [objNull]]];
if !(hasInterface && {!isNull _target}) exitWith {false};

if !(_target getVariable ["Waldo_StarterCrateIdentifierInstalled", false]) then {
    private _identifier = _target addAction [
        "<t color='#79C7FF'>Starter Crate</t>",
        {}, nil, 1.5, true, false, "",
        "alive _this && {_this distance _target < 6}", 6
    ];
    _target setVariable ["Waldo_StarterCrateIdentifierActionId", _identifier];
    _target setVariable ["Waldo_StarterCrateIdentifierInstalled", _identifier >= 0];
};

[_target] call Waldo_fnc_ZenAddLoadoutSaveAction;
true
