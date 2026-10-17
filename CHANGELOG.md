# Changelog

This fork's releases. Releases up to 0.2.35 are upstream's: see the [upstream releases](https://github.com/eliasstravik/herdr-projects/releases?q=v0.2&expanded=true).

## 0.2.36

The first release of the fork. It carries upstream 0.2.35, the last release of the Rust version, plus the fixes below.

### New
- Routine schedules take `weekly <days> HH:MM`: days as `mon`…`sun`, a list (`mon,wed,fri`), a range (`mon-fri`, which may wrap: `fri-mon`), or both. Several times are allowed, for `weekly` and `daily` alike (`daily 09:00,18:00`).

### Improved
- A machine or `gh` outage ends only after 15 minutes without a failure (`HERDR_PROJECTS_RECOVER_SECS`, 900 by default). A failure during that time is the same outage, so a flaky link no longer wakes the coordinator again and again.
- No machine outage items while none of that machine's threads is working (all ready for review or idle). Polling and report copying go on. If a thread starts working during the outage, the item is written then.
- No "PR updated" item when only the head commit moved. Failing checks that clear, comments, reviews and state changes still raise one.
- The coordinator skill sends work to threads only with `thread prompt`, checks that the turn started, and never submits a dim suggestion.
- `scripts/update-fork.sh` updates an install of this fork in place of `herdr-projects update`, which installs upstream releases.

### Fixed
- The ticker reads omp's input box, including its `▎` editor layout and multi-glyph hint keys (nerd symbol preset), so it can nudge an omp coordinator.
- `thread read` wraps the input box's dim text (a placeholder, a suggested prompt) as `[dim: ...]` and ends with a line saying whether the box is empty or holds typed text, so a coordinator no longer takes Claude Code's grey suggestion for a draft and leaves the thread idle.
- Clippy lints raised by Rust 1.99.

### From upstream 0.2.35
- A Claude Code session with a label in its input box's top border (session name, `--agent` name, effort or fast-mode tags, history position) gets its brief and its coordinator nudges again.
- When two projects share a remote machine, both are polled.
- Progress hooks stay silent outside a project's coordinator and local thread panes.
- A Codex thread resting at `unknown` with an open composer gets its first brief.
- `coordinator prompt` no longer reaches another project's coordinator started from a shell in this project's folder.
