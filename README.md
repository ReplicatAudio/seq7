# seq7

**seq7** — a virtual MIDI device scriptable with Scheme and Lua.

It creates a virtual ALSA MIDI port and runs a Lua 5.4 engine ([mlua](https://docs.rs/mlua/latest/)) alongside the Scheme engine ([steel-core](https://github.com/mwdx/steel)), both able to send raw MIDI messages. A 1ms tick loop lets you write sequenced, algorithmic, or interactive MIDI logic in either language.

## Usage

```
cargo run [script.scm | script.lua]
```

With a path argument, the script is loaded automatically before showing the command prompt; the language is picked by file extension (`.lua` → Lua, anything else → Scheme). Examples:

```
cargo run -- scm/simple.scm
cargo run -- lua/tick.lua
```

This opens a command prompt with full readline support (line editing, history via up/down arrows, Ctrl-A/E/U/W/K, etc.):

- `load <file>` — load and evaluate a script (`.lua` → Lua, anything else → Scheme).
- `scheme` — enter the live Scheme REPL (type `scheme` again to leave).
- `lua` — enter the live Lua REPL (type `scheme` to leave).
- `dbg` — toggle console output: off (default) silences script prints and the MIDI hex dump; on shows both.
- `help` — show commands.
- `quit` — exit.
- Press **Enter on an empty line** to start the tick loop.
- During the tick loop, press **Space** to stop it; `Ctrl-C` quits.

Anything else at the command prompt (e.g. raw Scheme text) is rejected with `unknown command: <text>` — Scheme evaluation happens only inside the REPL.

In `scheme`, type Scheme expressions and press Enter to evaluate them. In `lua`, type Lua expressions or statements (see Lua API below).

While the tick loop is running, `seq7` calls the last-loaded script's `tickfn` on every tick (1ms by default, adjustable with `set-tick-speed`) — `(define (tickfn) ...)` in Scheme, `function tickfn() ... end` in Lua. Use `raw-midi-write` / `raw_midi_write` to send MIDI bytes to the virtual port.

## Scheme API

| Function | Description |
|---|---|
| `(raw-midi-write bytes)` | Sends a list of bytes to the virtual MIDI port |
| `(log-raw bytes)` | Prints a hex dump of bytes to the terminal (only while `dbg` is on) |
| `(display ...)` | Standard Scheme display; silenced while `dbg` is off |
| `(newline)` | Standard Scheme newline, rewritten to write `\r\n` for raw mode; silenced while `dbg` is off |
| `(tickfn)` | Called every tick when the loop is running — define this in your script (default: 1ms) |
| `(set-tick-speed ms)` | Set tick interval in milliseconds (minimum 1) |

### steel/random builtins

`(rng->gen-range lo hi)` — random integer in `[lo, hi)` — and `(rng->gen-usize)` — random unsigned integer — are provided by steel-core's `steel/random` module, not seq7. Enable them with `(require-builtin steel/random)`.

### Scheme libraries

Library helpers are provided in `scm/lib/`; load them all with `(load "scm/lib/lib.scm")`.

## Lua API

Scripts ending in `.lua` run on a Lua 5.4 VM that coexists with the Scheme engine (everything without a `.lua` extension is Scheme). `load <file>` and the `cargo run <script>` argument pick the language by file extension, and the tick loop calls whichever `tickfn` the last-loaded script defined — define `function tickfn() ... end` in a `.lua` file exactly like `(define (tickfn) ...)` in Scheme.

| Lua global | Scheme equivalent | Description |
|---|---|---|
| `raw_midi_write(...)` | `(raw-midi-write bytes)` | Sends one byte per vararg to the virtual MIDI port — e.g. `raw_midi_write(0x91, 60, 100)` sends Note On, channel 2, note 60, velocity 100. Byte values must be in 0–255. |
| `log_raw(...)` | `(log-raw bytes)` | Prints a hex dump of the bytes (only while `dbg` is on) |
| `set_tick_speed(ms)` | `(set-tick-speed ms)` | Set tick interval in milliseconds (minimum 1) |
| `print(...)` / `io.write(...)` | `(display ...)` / `(newline)` | Console output; silenced while `dbg` is off (best-effort, like the Scheme console port) |

`tickfn` and `set_tick_speed` are available at load time, so a `.lua` script needs no explicit setup:

```lua
-- lua/tick.lua
dofile("lua/lib/lib.lua")

set_tick_speed(250)

local t = 0

function tickfn()
  midi_note_on(0, 21 + t % 60, 127)   -- Lua % is 0-based → notes 21..80
  t = t + 1
end
```

Run it with `cargo run -- lua/tick.lua`, then press **Enter** on an empty line to start the tick loop.

The `lua` command at the prompt enters a live Lua REPL (`scheme` returns to the command prompt). Each line is evaluated as an expression (printing its value when non-nil) or run as a statement. Note standard Lua semantics: `local` variables don't survive across REPL lines.

Libraries are provided in `lua/lib/`; load them all with `dofile("lua/lib/lib.lua")` (the Scheme and Lua library trees are independent — each language has its own VM, global environment, and libraries). Editor users on the Lua language server get the seq7 API globals declared in [`.luarc.json`](./.luarc.json).

Scheme's helpers are not available to Lua scripts, and vice versa.

## MIDI channels

MIDI channels (1–16) are embedded in the status byte — there is no separate "channel" argument. The status byte's low nibble selects the channel:

| Message | Channel 1 | Channel 2 | ... | Channel 16 |
|---|---|---|---|---|
| Note Off | `#x80` | `#x81` | ... | `#x8F` |
| Note On | `#x90` | `#x91` | ... | `#x9F` |
| Poly Aftertouch | `#xA0` | `#xA1` | ... | `#xAF` |
| Control Change | `#xB0` | `#xB1` | ... | `#xBF` |
| Program Change | `#xC0` | `#xC1` | ... | `#xCF` |
| Channel Aftertouch | `#xD0` | `#xD1` | ... | `#xDF` |
| Pitch Bend | `#xE0` | `#xE1` | ... | `#xEF` |

For example, `(raw-midi-write (list #x91 60 100))` sends Note On, channel 2, note 60, velocity 100.

## Virtual MIDI port

The virtual port appears as "seq7" in your ALSA MIDI connections. Route it to a synthesizer with `aconnect`:

```
aconnect seq7:0 <synth>:0
```

## Examples

Examples for both languages live in [`scm/`](./scm) and [`lua/`](./lua). Run one with `cargo run -- scm/<name>.scm` (or `lua/<name>.lua`), then press **Enter** on an empty line to start the tick loop and **Space** to stop it.

## Dependencies

- [steel-core](https://crates.io/crates/steel-core) — Scheme interpreter
- [mlua](https://docs.rs/mlua/latest/) — Lua 5.4 interpreter (vendored Lua sources; **a C compiler is required to build**)
- [midir](https://crates.io/crates/midir) — MIDI I/O (ALSA backend on Linux)
- [crossterm](https://crates.io/crates/crossterm) — raw terminal mode and key handling (tick loop only)
- [rustyline](https://crates.io/crates/rustyline) — readline support for the command prompt and REPL
