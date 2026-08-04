/*
 * Author: WaldoTheWarfighter
 * Adds helicopter extraction preparation and loading checklists to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_LZEXTRACT;
 */

player createDiaryRecord ["Checklists", ["Helicopter Extraction", "
<font color='#addde6' size='20'>HELICOPTER EXTRACTION</font><br/><br/>
<font color='#addde6' size='16'>PREPARATION</font><br/>
<font color='#d8f2f7'>1. Receive orders</font> — PZ, alternate PZ, PZ rally point, control-party composition, reconnaissance timing, main-body departure and arrival timing.<br/>
<font color='#d8f2f7'>2. Send warning order</font> — pass orders to the serial commander.<br/>
<font color='#d8f2f7'>3. Reconnoitre</font> — mark PZs, landing points, assembly points, OPs and hazards; plan chalk movement; assign guides; report readiness; send a situation report; detail security and return to the rally point.<br/><br/>
<font color='#addde6' size='16'>PICKUP AND LOADING</font><br/>
<font color='#d8f2f7'>1. Meet and brief</font> — brief the main body at the rally point; assign chalk leaders and landing-point guides.<br/>
<font color='#d8f2f7'>2. Move</font> — chalks move to their loading assembly points.<br/>
<font color='#d8f2f7'>3. Confirm pickup</font> — contact serial commander, initiate aircraft movement and update PZ security status.<br/>
<font color='#d8f2f7'>4. Move to landing points</font> — chalk leaders position their chalks.<br/>
<font color='#d8f2f7'>5. Mark</font> — on the 30-second warning, deploy smoke, IR grenades or another planned mark.<br/>
<font color='#d8f2f7'>6. Load</font> — move from assembly to pre-load positions, then board on order. PZ controller is last to board.
"]];
