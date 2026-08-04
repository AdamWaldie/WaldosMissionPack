/*
 * Author: WaldoTheWarfighter
 * Adds helicopter insertion administration and landing checklists to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_LZINSERT;
 */

player createDiaryRecord ["Checklists", ["Helicopter Insertion", "
<font color='#addde6' size='20'>HELICOPTER INSERTION</font><br/><br/>
<font color='#addde6' size='16'>ADMINISTRATION</font><br/>
<font color='#d8f2f7'>1. Receive orders</font> — identify the assigned aircraft and exact insertion LZ.<br/>
<font color='#d8f2f7'>2. Coordinate</font> — confirm the aircraft's short-range frequency and expected flight time.<br/>
<font color='#d8f2f7'>3. Brief squad</font> — loading assembly point and assigned aircraft.<br/>
<font color='#d8f2f7'>4. Move</font> — assemble clear of the aircraft, then load by chalk leader. Stay outside the main rotor arc; approach a CH-47 from the rear and other helicopters from the front unless directed otherwise.<br/>
<font color='#d8f2f7'>5. Load</font> — on clearance, move to pre-load positions and board. Report 'LAST IN' and number loaded to the aircraft commander.<br/><br/>
<font color='#addde6' size='16'>LANDING AND EXIT</font><br/>
<font color='#d8f2f7'>1. Monitor</font> — track progress to the landing zone.<br/>
<font color='#d8f2f7'>2. Get ready</font> — on the 30-second call, prepare to unload.<br/>
<font color='#d8f2f7'>3. Exit side</font> — repeat the instructed side: 'TWO-SIDE EXIT', 'EXIT LEFT' or 'EXIT RIGHT.'<br/>
<font color='#d8f2f7'>4. Stand by</font> — at 10–15 seconds, prepare the jump action.<br/>
<font color='#d8f2f7'>5. Go</font> — only after aircrew call 'CLEAR'; chalk leader controls a three-second exit.<br/>
<font color='#d8f2f7'>6. Move</font> — clear the LZ, orient the squad and avoid lingering in the ambush area.
"]];
