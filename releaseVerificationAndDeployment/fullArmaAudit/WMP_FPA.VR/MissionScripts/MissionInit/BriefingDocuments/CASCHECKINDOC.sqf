/*
 * Author: WaldoTheWarfighter
 * Adds the CAS aircraft check-in format to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_CASCHECKIN;
 */

player createDiaryRecord ["Support Calls", ["CAS Aircraft Check-In", "
<font color='#addde6' size='20'>CAS AIRCRAFT CHECK-IN</font><br/>
<font color='#a9a9a9'>Aircraft transmits this information to the controller.</font><br/><br/>
<font color='#addde6'>OPENING CALL</font><br/>
'Controller callsign, this is aircraft callsign.'<br/>
Controller: 'Standing by for aircraft check-in.'<br/><br/>
<font color='#addde6'>CHECK-IN FIELDS</font><br/>
<font color='#d8f2f7'>1. Pilot callsign / mission number</font><br/>
<font color='#d8f2f7'>2. Number and aircraft type</font> — e.g. 'Single Harrier GR9.'<br/>
<font color='#d8f2f7'>3. Position and altitude</font> — e.g. 'Four kilometres south-east of Kavala, angels two.'<br/>
<font color='#d8f2f7'>4. Ordnance</font> — e.g. 'Two GBU-12, two AGM-65.'<br/>
<font color='#d8f2f7'>5. Time on station</font> — e.g. 'Thirty minutes.'<br/>
<font color='#d8f2f7'>6. Abort code</font> — e.g. 'Juliet.'<br/>
<font color='#d8f2f7'>7. Additional remarks</font> — threats, restrictions or limitations as required.
"]];
