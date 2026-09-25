/*
 * Author: WaldoTheWarfighter
 * Marks the end of this machine's own initialisation phase. Arma runs every object's Eden Init
 * field before postInit functions on every machine, including each JIP client. A WMP function
 * that is safe in an Init field and forwards client calls to the server checks this flag: while it
 * is unset, the client call is an Init-field replay the server already ran itself, so forwarding it
 * again would recreate something since deleted (a removed jammer, tracker, 3D marker, completed
 * objective or used notification trigger). Calls made later by scripts and actions still forward.
 * Locality / Authority: Local to each machine; never broadcast.
 * Repeat / JIP: Runs once per machine as a CfgFunctions postInit function.
 *
 * Arguments: None.
 * Return Value: Nothing.
 * Current caller: CfgFunctions postInit.
 * Example: missionNamespace getVariable ["Waldo_ClientInitPhaseDone", false]
 */
missionNamespace setVariable ["Waldo_ClientInitPhaseDone", true];
