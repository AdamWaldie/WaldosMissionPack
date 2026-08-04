# Radio Reports, Checklists, and Support Calls

> **Use this page when:** you want WMP's optional briefing references or need to add your own documents.

_Associated Files: MissionScripts\MissionInit\BriefingDocuments\_

The pack provides in-game documentation, quick-reference templates, and checklists in the player's map diary. `Waldo_fnc_AddDocs` installs them locally for each player during mission startup.

Operational reference cards use native rich text rather than fixed-size pictures. Text wraps to the player's diary width, remains readable at different resolutions and UI scales, and can be copied or updated without re-exporting an image. The converted references include the five-line gunship brief, nine-line CAS brief, CAS check-in, call for fire, landing-zone brief, helicopter insertion and extraction, landing-zone specifications, and jumpmaster checklists.

---

## What Is Provided

### Radio Reports
| Document | Function |
|---|---|
| SITREP (Situation Report) | `Waldo_fnc_SITREP` |
| SPOTREP (Spot Report) | `Waldo_fnc_SPOTREP` |
| LACE/ACE Report | `Waldo_fnc_ACEREP` |
| Helicopter Pickup Request | `Waldo_fnc_ROTARYPICKUPREQUEST` |
| LZ Briefing | `Waldo_fnc_LZBRIEF` |

### Support Calls
| Document | Function |
|---|---|
| 5-Line Special Operations Gunship Call | `Waldo_fnc_FIVELINEGUNSHIP` |
| 9-Line CAS/ECAS Request | `Waldo_fnc_NINELINE` |
| IDF Call For Fire | `Waldo_fnc_CALLFORFIRE` |
| CAS Check-In Template | `Waldo_fnc_CASCHECKIN` |

### Checklists
| Document | Function |
|---|---|
| Squad Preparation Checklist | `Waldo_fnc_SQUADPREDOC` |
| Fireteam Preparation Checklist | `Waldo_fnc_FIRETEAMPREPDOC` |
| Fire Commands Reminder | `Waldo_fnc_FIRECOMMANDS` |
| Jump Master Checklist | `Waldo_fnc_JUMPMASTER` |
| LZ Specifications | `Waldo_fnc_LZSPECS` |
| LZ Insert Checklist | `Waldo_fnc_LZINSERT` |
| LZ Extract Checklist | `Waldo_fnc_LZEXTRACT` |

### General Information
| Document | Function |
|---|---|
| General Mission & Player Info | `Waldo_fnc_GENINFO` |

---

## Setup

Documents are loaded automatically. The call in `init.sqf` looks like this:

```sqf
call Waldo_fnc_AddDocs;
```

All documents are added to the player's **map screen briefing diary** (the `Diary` tab when opening the map). Each document is a separate entry.

---

## Enabling or Disabling Individual Documents

All individual document functions are called from `AddDocs.sqf`. To remove a document from the briefing, open `MissionScripts\MissionInit\BriefingDocuments\AddDocs.sqf` and comment out the corresponding function call.

For example, to remove the SITREP template:

```sqf
// [] call Waldo_fnc_SITREP;   // commented out — no longer shown to players
```

---

## Adding Custom Briefing Documents

To add a custom briefing document, create a new `.sqf` file in `BriefingDocuments\` using the existing files as a template. Each file uses `player createDiaryRecord` to add a titled entry to the map diary. Then call your new function from `AddDocs.sqf`.

Example of the basic pattern:

```sqf
player createDiaryRecord ["Diary", ["My Document Title", "Content goes here.<br/>More text on next line."]];
```

Documents support Arma structured-text tags such as `<br/>` for line breaks and `<font>` for colour and size. Prefer native text for operational instructions. Avoid using a screenshot of text: fixed-size images crop, scale poorly, cannot wrap, and are harder for players using accessibility or unusual UI settings.

Keep each entry easy to scan:

- Start with one clear title.
- Use short, numbered sections in the order players must transmit or act.
- Give examples directly below the field they explain.
- Reserve colour for headings, examples and warnings; the instructions must still be understandable without colour.
- Test the map diary at the supported aspect ratios and UI scales before release.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
