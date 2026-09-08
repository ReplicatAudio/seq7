# Plan: add Lua 5.4 support to seq7

Shape (per decisions): Lua **coexists** with the steel/Scheme engine, script language is
picked by file extension (`.lua` → Lua, `.scm`/anything else → Scheme), MIDI bytes are
Lua varargs (`raw_midi_write(0x91, 60, 100)`), Lua 5.4 via
[`mlua`](https://docs.rs/mlua/latest/) 0.12 (current release, MSRV 1.88+ — matches this
project's modern Rust).

---

## 1. Dependency — `Cargo.toml`

```toml
mlua = { version = "0.12", features = ["lua54", "vendored"] }
```

- `vendored` builds the Lua 5.4 C sources during `cargo build` → **a C compiler
  (cc/gcc/clang) becomes a build requirement** (first build compiles Lua, ~seconds).
- Alternative (no C compiler needed, but system Lua must be installed): drop `vendored`
  so the build script uses `pkg-config` to find `lua5.4`.

## 2. `src/main.rs` — one coexisting Lua VM

Everything stays on the main thread (tick loop, REPL, loader), so default `!Send` Lua
needs no `send` feature.

### a) New state

`enum Lang { Scheme, Lua }` + `let mut lang = Lang::Scheme;`

Set whenever a script is loaded, by extension (see e). Also: initial `script_path` arg
and the empty-line "reload and run" path use the same dispatch, so
`cargo run -- examples/tick.lua` + Enter just works.

### b) Create the VM next to the steel engine

```rust
let mut lua = mlua::prelude::Lua::new();   // full stdlibs (math, string, table, os, ...)
```

### c) Register Rust functions into Lua

Same closures/captures already used for the steel engine (`conn`, `dbg`, `frame`):

| Lua global | Signature | Rust impl |
|---|---|---|
| `raw_midi_write(...)` | `Variadic<f64>` (or `Variadic<u8>` — verify mlua's `FromLua<u8>` at impl time; otherwise convert f64 with 0–255 validation) | forwards to the existing `midi.lock().send(...)` + the `dbg` `▶ hex` dump |
| `log_raw(...)` | same bytes | existing gated hex dump |
| `set_tick_speed(ms)` | `u64` | existing `*frame.lock() = ...` |
| `_seq7_write(text)` | `String` | gated stdout write (see d) |

Return `Ok(())` — mlua's `create_function` requires `LuaResult` returns.

### d) Gated console for Lua

Mirrors the Scheme `GatedConsole` port:

- Register `_seq7_write(text)` writing through the same `dbg` AtomicBool (extract the
  gate logic from `GatedConsole::write` into a shared helper so both paths stay
  identical).
- After creating the VM, run a tiny preamble that routes Lua output through it:

```lua
local w = _seq7_write
print   = function(...) w(table.concat({...}, '\t') .. '\n') end
io.write = function(...) w(table.concat({...})) end
```

Best-effort gate, same class of weakness as the Scheme one (`io.stdout:write` still
bypasses; acceptable).

### e) `load_file` dispatch

Split into `load_scheme_file` (current code, unchanged) and new `load_lua_file`:

```rust
fn load_lua_file(lua: &mut Lua, path: &str) {
    // fs::read_to_string → lua.load(&code).exec()?  → println "loaded {path}"
    // Err(e) → println error, ok = false
}
```

`load_file(path)` chooses by `path.ends_with(".lua")` and sets `lang` accordingly. Lua
files execute wholesale (no steel's compile-before-run quirk), so no form-by-form
splitting needed.

### f) Command prompt (`State::Command`)

- `load <file>` — now dispatches by extension (updating `lang`).
- New command `lua` — enter Lua REPL (`State::ReplLua`); `repl` keeps its Scheme meaning.
- Update the `help` text.

### g) Lua REPL (`State::ReplLua`, mirroring `State::Repl`)

- Per line: try `lua.load(line).eval()?` (prints returned values, non-nil only — matches
  Scheme REPL output style); if eval fails because the line is a statement, fall back to
  `lua.load(line).exec()?` (i.e. `eval` → on error `exec` → only print the error if both
  fail). Verify `Chunk::eval` semantics at impl time.
- `repl` → back to Command; empty line → reload script + start tick loop; `quit`/`Ctrl-C`
  exit. The existing `return_to` mechanism makes Space return to whichever REPL started
  the loop, unchanged.

### h) Tick loop (`State::Running`) — dispatch on `lang`

```rust
match lang {
    Lang::Scheme => engine.call_function_by_name_with_args("tick", vec![]),
    Lang::Lua    => {
        // lua.globals().get::<Function>("tick") → call with no args
        // if global missing/not callable → error path identical to current
        // "tick error: ..." print + stop + return_to
    },
}
```

Lua scripts define `function tick() ... end`; a loaded `.lua` without `tick` errors and
stops the loop, exactly like Scheme today. Late-tick timing logic, raw mode, Space/Ctrl-C
handling untouched.

## 3. Examples

- `examples/tick.lua` — direct port of `examples/simple.scm`, exercising varargs + 0-based
  mod:

```lua
set_tick_speed(250)
local t = 0
function tick()
  raw_midi_write(0x90, 21 + t % 60, 127)   -- Lua % → 0..59, so 21..80
  t = t + 1
end
```

- Optional (ask before building): `lib/midi.lua` porting `lib/midi.scm`
  (`midi_note_on(ch, note, vel)` etc.) — note a `.lua` script cannot `load` a `.scm`, so
  Scheme `lib/` helpers are unavailable to Lua.

## 4. `README.md`

- Tagline: "scriptable with Scheme and Lua".
- New "Lua API" section: the mapping table (scheme ↔ lua), `load` dispatch by extension,
  the `lua` REPL command, `cargo run -- examples/tick.lua`.
- Dependencies: add mlua; note the C compiler requirement for the vendored Lua build.

## 5. Verification

- `cargo build` (watch for mlua `u8`/`Variadic` conversions, snapshot API of
  `globals().get::<Function>`).
- Manual: run `examples/tick.lua`, start tick loop, confirm notes arrive
  (`test/arrival.rs` probe works unchanged); confirm `dbg` gates Lua `print` and MIDI
  dump; confirm `load` of both extensions + both REPLs coexist and the Space-return target
  is right.
- Existing Scheme examples must keep working (language default remains Scheme when no
  `.lua` is involved).

---

## Notable decisions / risks

- **C compiler needed at build time** (vendored Lua). If that's undesirable, gear to
  system Lua via `pkg-config` — say the word.
- **Lua helpers aren't available in Scheme and vice versa** — each language has its own
  VM/globals (Scheme's `lib/*.scm` stay Scheme-only). No cross-language bridging is
  proposed.
- **Two REPLs** (`repl` = Scheme, new `lua` = Lua) rather than a merged one — keeps
  existing behavior byte-identical.
- Two implementation details to confirm against mlua 0.12 during coding (with fallbacks
  ready): `FromLua<u8>` for MIDI bytes (fallback: `Variadic<f64>` + range check) and
  `Chunk::eval`'s behavior on statements (fallback: eval-then-exec).
- **Tick loop semantics assumption**: the last-loaded script's extension decides which
  `tick` runs — the predictable rule given extension dispatch. Flag if you'd rather have
  it be the language of the REPL the loop was started from.