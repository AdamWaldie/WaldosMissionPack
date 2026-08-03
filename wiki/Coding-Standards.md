# Coding and Documentation Standards

> **Use this page when:** you are changing WMP scripts, functions, documentation, or validation tooling.

The following will note the standards that I attempt to uphold in the making of this pack. As I am but one man, however, and with this being a side project, the pack may not always be to this standard. Refactor and "standard" passes are committed every three months or so to bring severe cases in line with this standard where possible.

## Text Editor
You are free to select your own text editor for the creation or editing of your scripts, but I would advise selecting Visual Studio Code & Its SQF plugins. It'll make any script reading in Arma 3 easier on you! 
- Visual Studio Code: https://code.visualstudio.com/
- SQF Language Extension: https://marketplace.visualstudio.com/items?itemName=vlad333000.sqf
- SQF Debugger Extension: https://marketplace.visualstudio.com/items?itemName=billw2011.sqf-debugger


## Documentation principle

WMP documentation serves two readers at once:

1. A new Arma mission maker must be able to decide what to change, where to place a call, and what
   result to expect without reverse-engineering SQF.
2. A maintainer must still receive the complete technical contract. Plain language must never remove
   argument positions, accepted types, defaults, return values, locality, authority, JIP behavior,
   call syntax, or current call sites.

Start with the player-facing purpose, then give the exact callable/configuration contract. Explain
acronyms and engine terms the first time they appear. Never use an unexplained positional array.
Every numbered field needs a type, valid values or range, units where relevant, and its default.

## Script Header Requirements
The header is an executable user's manual, not only a description. It contains:

- `Author:` followed by the human author or authors responsible for the script. WMP-authored pack
  work uses `WaldoTheWarfighter`; an independently contributed script may name its actual human
  contributor. Never present an AI assistant, code generator, or editing tool as an author.
- A plain-English purpose and the practical result.
- `Locality and authority`: which machine calls it, which machine owns changes, and whether state is
  published/replayed for Join in Progress (JIP).
- `Arguments`: numbered in the exact order consumed by `params`; retain parameter names, types,
  valid values/ranges, units, optional/default status, and nested row/HashMap field shapes.
- `Return Value`: exact type and meaning, or `Nothing`.
- `Example`: a copyable call including every required argument and a common optional setup.
- `Result`: what the example visibly or programmatically does.
- `Current callers`: init file, registered function, event handler, ZEN module, editor init, or
  mission-maker call path currently invoking it. Write `None; public/manual API` when that is true.

### In-File Header - the canonical template
Every script file (`.sqf`) should open with this block. Functions that operate on `_this` still list their logical arguments. Use `None` / `Nothing` where appropriate.

```
/*
 * Author: WaldoTheWarfighter
 * Plain-English purpose and practical result.
 *
 * Locality and authority:
 * Call on the server. The server owns the created object and publishes its state for JIP.
 *
 * Arguments:
 * 0: target <OBJECT> - existing object to configure; must not be null.
 * 1: enabled <BOOL> - whether the behavior starts immediately (optional, default: false).
 * (Use `None` only when the script genuinely accepts no arguments.)
 *
 * Return Value:
 * <BOOL> - true when setup was accepted; false when validation rejected it.
 *
 * Example:
 * [this, true] call Waldo_fnc_SomeFunction;
 *
 * Result:
 * Configures this editor object and activates it immediately.
 *
 * Current callers:
 * Editor object init and Waldo_fnc_CreateSomeFeature (server-routed ZEN creation).
 */
```
Notes:
* If a file begins with `#include` lines, put the header **after** them (the validator requires `#include` before any block comment).
* Preserve a human contributor's accurate author line when maintaining their script. Add another
  human author only when their contribution warrants authorship; routine formatting need not do so.
* Registering a new function? The header is step one; you must also add the class entry in `MissionScripts\WaldosFunctions.sqf`.
* A wrapper and the function it wraps each need their own accurate arguments/callers. Do not copy a
  public function's contract onto an internal helper with a different signature.

## Feature-config setting standard

Every editable setting in `MissionConfig` is explained where its active value appears. Use the
following structure; the concise equivalent is acceptable only when all four facts remain explicit:

```sqf
// SETTING: Waldo_Example_Enable (MISSION MAKER)
// WHAT IT CHANGES: whether the example feature may initialise.
// VALUES: true enables it; false disables it. BOOL; default false.
// EXAMPLE/RESULT: true starts support at mission load; required world objects must still be registered.
["Waldo_Example_Enable", false],
```

For every setting explain:

- whether it is a normal `MISSION MAKER` choice, `ADVANCED TUNING`, or
  `COMPATIBILITY / INFRASTRUCTURE`;
- what changing it affects and what it does **not** create or activate;
- exact value forms, classnames/IDs, valid ranges and units;
- the shipped default and one realistic alternative with its result;
- every field of arrays, HashMaps and nested rows by zero-based position;
- what `[]`, `""`, `-1`, `0`, and `objNull` mean in that particular setting.

Config file headers retain their own callable contract: `Arguments`, `Return Value`, `Example`,
`Result`, and `Current callers`. They also state the activation model and whether custom calls belong
in `initServer.sqf`, `initPlayerLocal.sqf`, an editor object init, a server trigger/script, or ZEN.

## Feature Documentation Standard
A "feature" is a user-facing capability (a system, a Zeus module, a script a mission maker calls). When you add or change one, document it in **all** of these places so it stays discoverable:
1. **In-file headers** - on every script that makes up the feature (above).
2. **`MissionConfig`** - setting-by-setting guidance when the feature is configurable.
3. **`README.md`** - one concise entry in *Pack Features*.
4. **Wiki** - a beginner setup page following the Wiki Page Standard below, linked from the feature
   index and relevant configuration reference.

Keep terminology identical across all four (same feature name, same variable names).

## Wiki Page Standard
Wiki pages are the mission-maker-facing guides; optimise them for usability. A feature page should contain, in order:
1. An early **Use this page when** summary.
2. A plain-English overview: what players experience and why a maker would use it.
3. **Prerequisites and activation model**: required mods, enable switch, registrations/placements,
   authority, locality, and JIP behavior.
4. **Quick setup**: the smallest safe copyable setup, including the correct init file.
5. **Setting-by-setting reference**: what to change, allowed form/range, shipped default, example and
   result; mark normal choices versus advanced/compatibility values.
6. **Script calls**: numbered arguments matching the in-file header, return value, copyable example,
   result, current call sites, and script-versus-ZEN parity where applicable.
7. **Runtime changes and cleanup**, when supported.
8. **Troubleshooting and engine limits**.
9. A **See also** list and the standard navigation footer.

Large features get a **hub page** plus one sub-page per sub-system (see *Waldos Economy Systems*). Write in plain language; assume the reader is a mission maker, not a scripter.

## Adding a Feature - documentation checklist
- [ ] Header block on every script file
- [ ] Function(s) registered in `WaldosFunctions.sqf`
- [ ] Every config setting has values/default/example/result documentation
- [ ] `README.md` Pack Features bullet
- [ ] Wiki page(s) following the Wiki Page Standard, linked from `Feature-Tutorials.md`
- [ ] Documentation, SQF, config and wiki validators pass

Run the blocking documentation contract check with:

```text
python releaseVerificationAndDeployment/documentation_contract_checker.py
```

When remediating an existing branch, provide its Git base to audit every changed script against the
complete header contract:

```text
python releaseVerificationAndDeployment/documentation_contract_checker.py --changed-base <base revision>
```

The strict audit deliberately reports older incomplete headers instead of inserting guessed
locality, arguments or callers. Fix those findings by reading the implementation and real call sites.

## Code Conventions
## ACE Coding Guidelines
Please adhere to the [ACE CODING GUIDELINES](https://github.com/acemod/ACE3/blob/master/docs/wiki/development/coding-guidelines.md) where possible

## Specific differences to the ACE Coding Guidelines
* Constants are types in full capitals: CONSTANT
* Variables are to be in lower camel case: variablesAreFun , _variablesAreFun 
* Functions are to be in upper camel case: Waldo_fnc_UpperCamelCaseFunction

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
