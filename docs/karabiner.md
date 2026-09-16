# Keyboard setup

## Restore on a Mac

```zsh
brew install --cask karabiner-elements
scripts/bootstrap_karabiner.sh --check
scripts/bootstrap_karabiner.sh --replace
open -a Karabiner-Elements
```

The installer may need administrator authentication. In Karabiner's Setup page,
complete all four checks:

1. Background Services: enable both Non-Privileged Agents v2 and Privileged Daemons v2 in System Settings → General → Login Items & Extensions. The privileged service affects all users.
2. Accessibility: allow Karabiner's requested component in Privacy & Security → Accessibility.
3. Capture Input Events: verify capture is allowed. Accessibility may already cover this; otherwise follow the Input Monitoring prompt.
4. Driver Extension: allow Karabiner's virtual keyboard driver in Login Items & Extensions.

These permissions belong to macOS and cannot be restored from the configuration
file. Authenticate in the system dialog when requested. All four were verified
as enabled on the current Mac on September 16, 2026.

## What is saved

The complete active configuration is in [karabiner.json](../.config/karabiner/karabiner.json).
It includes the selected Default profile, eight manipulators for the Caps Lock
layer, the American National Standards Institute (ANSI) virtual keyboard
layout, and the Keychron device override (`ignore: false`).

| Device | Vendor / product identifiers | Behavior |
| --- | --- | --- |
| Keychron K4 HE | 13364 / 3648 (`0x3434` / `0x0e40`) | Modify events enabled explicitly |
| Apple Internal Keyboard / Trackpad | Karabiner's default device behavior | Keyboard remapping enabled; built-in keyboard stays usable |

The Keychron reports keyboard, pointing-device, and game-pad capabilities; its
saved identifiers include all three. Another connection mode may report different
identifiers: check Devices → Modify events if reconnecting makes shortcuts stop.

The repository stores a snapshot, not a live symbolic link. This avoids requiring
Karabiner's services to read this Desktop-based repository. Karabiner recommends
linking the entire configuration directory when using links and documents extra
permissions for Desktop locations. [Configuration location documentation](https://karabiner-elements.pqrs.org/docs/manual/misc/configuration-file-path/).

After editing Karabiner settings, export the live configuration:

```zsh
scripts/bootstrap_karabiner.sh --export
git diff -- .config/karabiner/karabiner.json
```

`--check` changes nothing. `--replace` copies the repository configuration to the
live location, backing up any differing existing file first. `--export` copies in
the opposite direction and backs up the repository copy if it differs. Neither
operation deletes other assets or changes system permissions. Backups use
`karabiner.json.backup.*`; copy the desired backup over the destination to undo.
Karabiner watches the live directory and reloads file changes.

## Active bindings and boundaries

| Input | Result |
| --- | --- |
| Hold Caps Lock, press S outside Slack | Launch or focus Slack |
| Hold Caps Lock, press S inside Slack | Focus the most recently used running app |
| Hold Caps Lock, press G | Toggle Ghostty and the previous app |
| Hold Caps Lock, press B | Toggle Google Chrome and the previous app |
| Hold Caps Lock, press Backspace | Send Option + Backspace to delete the previous word; repeats while held |
| Tap Caps Lock alone | Do nothing; capitalization is disabled on this key |
| Release Caps Lock | Clear the shortcut layer |

Caps Lock is consumed while held; S, G, B, and Backspace have layer bindings. Other
letters pass through normally. These shortcuts with additional Command, Control, Option, or
Shift modifiers does not match this shortcut. Existing capitalization is allowed.
Holding S, G, or B does not repeat the app-switch action. Word deletion follows
the foreground app's Option + Backspace behavior. Chrome was the default browser
when configured; this binding targets Chrome explicitly, even if that default changes.

The return target is app history, not a saved window or browser tab. If you
manually switch apps between presses, the target follows that updated history.
History includes running apps focused since Karabiner launched; closed apps are
excluded. [Native app-switching documentation](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/software_function/open_application/).

## Unified Modeling Language (UML) sequence

This is the logical end-to-end flow; Karabiner's services are grouped for clarity.

```mermaid
sequenceDiagram
    actor User
    participant Keyboard as Keychron / Apple keyboard
    participant K as Karabiner services
    participant Rules as Active configuration
    participant V as Virtual keyboard driver
    participant OS as macOS apps and focus
    Note over K,OS: Background services, Accessibility, input capture and driver allowed
    Rules-->>K: Load selected profile and device settings
    User->>Keyboard: Hold Caps Lock
    Keyboard->>K: Caps down
    K->>K: caps_slack_layer = 1 (consume Caps)
    alt S, G, or B pressed while Caps held
        Keyboard->>K: App shortcut down
        K->>Rules: Check layer and frontmost app
        alt Target app is frontmost
            K->>OS: Focus app history index 1
        else Another app is frontmost
            K->>OS: Open or focus Slack / Ghostty / Chrome
        end
        Note over K,OS: Native app action; no synthetic S or shell script
    else Backspace pressed while Caps held
        K->>V: Emit Option + Backspace (repeat allowed)
        V->>OS: Delete previous word
    else Caps tapped alone
        K->>K: Consume key; emit nothing
    end
    Keyboard->>K: Caps up
    K->>K: caps_slack_layer = 0
    Note over K,V: Ordinary key output uses the virtual keyboard
```

## Code shape

The behavior in pseudocode:

```text
Caps down → layer = 1
S / G / B down when layer == 1:
    target = Slack / Ghostty / Chrome
    if target is frontmost: focus previous running app
    else: launch or focus target
Backspace down when layer == 1 → emit Option + Backspace
Caps up → layer = 0
Caps tapped alone → no output
```

The two native action objects in the configuration are:

```json
{"software_function":{"open_application":{"bundle_identifier":"com.tinyspeck.slackmacgap"}},"repeat":false}
```

```json
{"software_function":{"open_application":{"frontmost_application_history_index":1}},"repeat":false}
```

To add another app toggle, duplicate both S manipulators, replace their `from`
key and app identifiers, and retain the shared `caps_slack_layer` condition.
Keep only one Caps Lock manipulator. Verify the app's identifier in EventViewer.

## Possible next binding (not enabled)

| Binding | Proposed action | Reason |
| --- | --- | --- |
| Caps + H / J / K / L | Left / down / up / right | Navigation without leaving the home row |

Caps alone currently does nothing. Navigation bindings
should allow Shift for selection and use repeating key output; app toggles should
keep `repeat: false`. These suggestions are personal workflow choices, not defaults.

## Check after restoring

1. Open Karabiner → Setup and verify all four checks pass.
2. In Devices, verify Modify events for the Keychron and internal keyboard.
3. In Complex Modifications, confirm the Caps Lock layer rule is enabled.
4. From another app, test Caps + S, G, and B twice each to check switching back.
5. In a scratch text field, test Caps + Backspace and its repeat behavior.
6. Verify Caps alone does nothing and plain letters still type normally.

If switching fails, inspect Karabiner → Log for configuration errors and use
EventViewer to confirm key events and the Slack bundle identifier. App history
needs another running app to have been focused since Karabiner started.
