/*
 * Author: WaldoTheWarfighter
 * Adds a readable landing-zone brief template to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_LZBRIEF;
 */

player createDiaryRecord ["Checklists", ["Landing Zone Brief", "
<font color='#addde6' size='20'>LANDING ZONE BRIEF</font><br/><br/>
<font color='#d8f2f7'>1. CURRENT LOCATION</font><br/>
Give a geographic feature, checkpoint, or preferably an eight-figure grid.<br/><br/>
<font color='#d8f2f7'>2. MARKING METHOD</font><br/>
Smoke, coloured chem lights, IR strobe, or talk-on as a last resort. State the colour when it differs from the expected default.<br/><br/>
<font color='#d8f2f7'>3. WIND</font><br/>
Wind speed in knots and direction as a compass bearing.<br/><br/>
<font color='#d8f2f7'>4. LZ SIZE AND SURFACE</font><br/>
Length by width in metres; terrain composition; flat or sloped; estimated incline where possible.<br/><br/>
<font color='#d8f2f7'>5. HAZARDS</font><br/>
Power lines, trees, obstructions, nearby aircraft, explosives and adverse weather.<br/><br/>
<font color='#d8f2f7'>6. HOSTILE FORCES</font><br/>
Direction, distance and type. Recommend an approach direction when able.<br/><br/>
<font color='#d8f2f7'>7. FRIENDLY FORCES</font><br/>
Direction and distance from LZ, plus number of wounded where relevant.<br/><br/>
<font color='#d8f2f7'>8. CONFIRMATION</font><br/>
Request confirmation, then stand by to mark when flight lead is close enough.
"]];
