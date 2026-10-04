/*
 * Author: WaldoTheWarfighter
 * Purpose: Shows a transfer/merge result, clears a successful reviewed queue and refreshes the panel.
 * Locality / Authority: Requesting interface client; accepts only server results.
 * Repeat / JIP: One transient result per request; no durable state to replay.
 * Arguments: success <BOOL>, source <OBJECT>, destination <OBJECT>, category <STRING>.
 * Return Value: Nothing. Current caller: RequestWithFeedbackServer.
 * Example: [true, boxA, boxB, "ITEM"] remoteExecCall ["Waldo_fnc_SupplyTransfersResultLocal", owner player];
 * Result: The player sees a transfer outcome and the panel refreshes if it remains open.
 */
params [["_ok", false, [false]], ["_source", objNull, [objNull]],
    ["_destination", objNull, [objNull]], ["_category", "", [""]]];
if (!hasInterface || {remoteExecutedOwner isNotEqualTo 2}) exitWith {};
if (_ok && {_category == "ALL"}
    && {(missionNamespace getVariable ["Waldo_SupplyTransfers_SelectedSource", objNull]) isEqualTo _source}) then {
    missionNamespace setVariable ["Waldo_SupplyTransfers_SelectedSource", objNull];
    missionNamespace setVariable ["Waldo_SupplyTransfers_SourceExpiresAt", -1];
};
private _message = if (_ok) then {
    if (_category == "DELETE") then {"Empty container removed."} else {
        if (_category == "ALL") then {"Source contents merged into the destination."} else {"Supplies moved successfully."}
    }
} else {
    if (_category == "DELETE") then {"Container was not empty or could not be removed."} else {
        "Transfer rejected. Check box separation, current contents and destination capacity."
    }
};
private _display = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
if (!isNull _display && {(_display getVariable ["Waldo_SupplyTransfers_Destination", objNull]) isEqualTo _destination}) then {
    if (_category == "BATCH"
        && {(_display getVariable ["Waldo_SupplyTransfers_PendingSource", objNull]) isEqualTo _source}) then {
        _display setVariable ["Waldo_SupplyTransfers_Pending", false];
        _display setVariable ["Waldo_SupplyTransfers_PendingSource", objNull];
        if (_ok && {_category == "BATCH"}) then {_display setVariable ["Waldo_SupplyTransfers_Queue", []]};
    };
    private _status = _display getVariable ["Waldo_SupplyTransfers_Status", controlNull];
    if (!isNull _status) then {_status ctrlSetText _message};
    [_display] spawn {
        params ["_panel"];
        uiSleep 0.15;
        if (!isNull _panel) then {[_panel] call Waldo_fnc_SupplyTransfersRefreshLocal};
    };
} else {
    ["SUPPLY TRANSFER", _message, ["WARNING", "SUCCESS"] select _ok,
        "SUPPLY_TRANSFER_RESULT"] call Waldo_fnc_FeatureNotifyLocal;
};
