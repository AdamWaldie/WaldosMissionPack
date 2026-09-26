# Treatment Feedback

> **Use this page when:** patients should see clear start, completion and interruption feedback for ACE medical treatment.

Treatment Feedback shows a WMP card to the patient during ACE Medical actions. The medic can receive a separate card if the mission maker enables that choice. The card reports the real ACE treatment result. It does not run on an unrelated timer.

## Enable it

ACE Medical is required. Open `MissionConfig/interfaceConfig.sqf` and change the existing `Waldo_TreatmentFeedback_Enable` row from `false` to `true`. Start the mission and treat a wounded player. The patient should see the start card, followed by a completion or failure card. No object placement or ZEN module is needed.

## Choose the cards

Edit the existing rows in `MissionConfig/interfaceConfig.sqf`. Keep the `Waldo_TreatmentFeedback_` prefix on every setting.

| Setting suffix | Type | Shipped value | What it changes |
|---|---|---|---|
| `Enable` | Boolean | `false` | Installs local ACE Medical listeners. No object placement is needed. |
| `ShowStart` | Boolean | `true` | Shows a card when ACE starts treatment. |
| `ShowSuccess` | Boolean | `true` | Shows a card after ACE reports completion. |
| `ShowFailure` | Boolean | `true` | Shows a card after ACE reports interruption or failure. |
| `NotifyPatient` | Boolean | `true` | Sends the card to the treated player. |
| `NotifyMedic` | Boolean | `false` | Also sends the medic a separate card. |
| `ShowMedicName` | Boolean | `true` | Includes the medic's name on the patient's card. |
| `ShowBodyPart` | Boolean | `true` | Includes the treated body part. |
| `StartTitle` | String | `"TREATMENT STARTED"` | Heading for the start card. |
| `SuccessTitle` | String | `"TREATMENT COMPLETE"` | Heading for completion. |
| `FailureTitle` | String | `"TREATMENT FAILED"` | Heading for interruption. |
| `Duration` | Number | `3` | Seconds the result card stays visible after the ACE event. It does not alter treatment time. |
| `TreatmentNames` | HashMap | Empty | Optional ACE treatment classname to readable label overrides. |
| `BodyPartNames` | HashMap | Shipped ACE body-part labels | Optional body-part ID to readable label overrides. |

The notification uses a padded bottom-centre specialist area and follows the shared visual theme. It replaces an earlier treatment card instead of stacking every rapid event across the screen.

## Script calls and runtime changes

The normal setup needs no script call. WMP reads the config and starts each player's listeners, including on JIP. If a mission changes the enable setting during play, `[] call Waldo_fnc_TreatmentFeedbackInit` attempts to install listeners on that player's interface and returns a Boolean. It returns `false` without an interface, ACE Medical or an enabled feature. A repeat call returns `true` without adding duplicate handlers. `[] call Waldo_fnc_TreatmentFeedbackStop` removes the local handlers and returns no useful value. Run these on the affected client, not only on the dedicated server.

## If feedback is missing

Check that ACE Medical is loaded, the enable row is `true`, and the intended recipient option is on. A treatment that never finishes does not produce a success card.

## See also

- [Custom UI Notifications](Custom-UI-Notifications)
- [UI Visual Themes](UI-Visual-Themes)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
