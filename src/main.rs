use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use std::{fs, io, thread};

use crossterm::event::{self, Event, KeyCode, KeyEventKind, KeyModifiers};
use crossterm::terminal::{disable_raw_mode, enable_raw_mode};
use midir::os::unix::VirtualOutput;
use midir::MidiOutput;
use rustyline::error::ReadlineError;
use mlua::prelude::*;
use steel::rvals::SteelVal;
use steel::steel_vm::engine::Engine;
use steel::steel_vm::register_fn::RegisterFn;

fn print_raw(args: std::fmt::Arguments) {
    use io::Write;
    let mut stdout = io::stdout();
    write!(stdout, "\r").unwrap();
    stdout.write_fmt(args).unwrap();
    write!(stdout, "\r\n").unwrap();
    stdout.flush().unwrap();
}

macro_rules! println_raw {
    ($($arg:tt)*) => { print_raw(format_args!($($arg)*)) };
}

fn load_scheme_file(engine: &mut Engine, path: &str) {
    match fs::read_to_string(path) {
        Ok(code) => {
            // Evaluate each top-level form sequentially, like the REPL does.
            // Compiling the whole file at once would make identifiers provided
            // by an earlier (load ...) form invisible to later forms at compile
            // time (steel compiles the entire program before executing any of it).
            let forms = steel::parser::parser::Parser::parse_without_lowering(&code);
            let mut ok = true;
            match forms {
                Ok(forms) => {
                    for form in forms {
                        let chunk = code[form.span().usize_range()].to_owned();
                        match engine.run(chunk) {
                            Ok(vals) => {
                                for val in vals {
                                    if !matches!(val, SteelVal::Void) {
                                        println!("{}", val);
                                    }
                                }
                            }
                            Err(e) => {
                                println!("{}", e);
                                ok = false;
                                break;
                            }
                        }
                    }
                }
                Err(e) => {
                    println!("{}", e);
                    ok = false;
                }
            }
            if ok {
                println!("loaded {}", path);
            }
        }
        Err(e) => println!("{}", e),
    }
}

/// Load a Lua file and execute it wholesale (Lua has no compile-before-run
/// quirk, so no form-by-form splitting is needed).
fn load_lua_file(lua: &mut Lua, path: &str) {
    match fs::read_to_string(path) {
        Ok(code) => match lua.load(&code).exec() {
            Ok(()) => println!("loaded {}", path),
            Err(e) => println!("{}", e),
        },
        Err(e) => println!("{}", e),
    }
}

/// Load a script, picking the language by extension: `.lua` → Lua,
/// everything else → Scheme. Records the choice in `lang` so the tick loop
/// calls the matching `tick`.
fn load_file(engine: &mut Engine, lua: &mut Lua, lang: &mut Lang, path: &str) {
    if path.ends_with(".lua") {
        *lang = Lang::Lua;
        load_lua_file(lua, path);
    } else {
        *lang = Lang::Scheme;
        load_scheme_file(engine, path);
    }
}

fn flush_pending_events() {
    while event::poll(Duration::ZERO).unwrap() {
        event::read().unwrap();
    }
}

/// Write to stdout while the `dbg` flag is on; swallow the write while it is
/// off. Shared by the Scheme `GatedConsole` port and the Lua `_seq7_write`
/// sink so script output is gated identically in both languages.
fn gated_console_write(dbg: &AtomicBool, buf: &[u8]) -> io::Result<()> {
    if dbg.load(Ordering::Relaxed) {
        use io::Write;
        let mut stdout = io::stdout();
        stdout.write_all(buf)?;
    }
    Ok(())
}

/// Hex-dump bytes (gated on `dbg`) and send them to the virtual MIDI port.
/// Shared by the Scheme and Lua `raw-midi-write` registrations so both paths
/// behave identically.
fn midi_send(dbg: &AtomicBool, port: &Mutex<midir::MidiOutputConnection>, bytes: &[u8]) {
    if dbg.load(Ordering::Relaxed) {
        use io::Write;
        let mut stdout = io::stdout();
        write!(stdout, "\r▶ {:02x?}\r\n", bytes).unwrap();
        stdout.flush().unwrap();
    }
    if let Ok(mut port) = port.lock() {
        if let Err(e) = port.send(bytes) {
            eprintln!("midi send error: {}", e);
        }
    }
}

/// stdout sink used as the Scheme current-output-port. Discards writes while
/// the dbg flag is off so scripts can't print to the console; passes them
/// through (with the \r\n newline convention) while dbg is on.
struct GatedConsole(Arc<AtomicBool>);

impl std::io::Write for GatedConsole {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        gated_console_write(&self.0, buf)?;
        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        if self.0.load(Ordering::Relaxed) {
            io::stdout().flush()?;
        }
        Ok(())
    }
}

/// Block until `deadline`, sleeping for most of the wait and busy-spinning
/// the final margin so scheduler wakeup latency can't eat into the deadline.
fn sleep_until(deadline: Instant, now: Instant) {
    const SPIN_MARGIN: Duration = Duration::from_micros(500);
    if now >= deadline {
        return;
    }
    let remaining = deadline - now;
    if remaining > SPIN_MARGIN {
        thread::sleep(remaining - SPIN_MARGIN);
    }
    while Instant::now() < deadline {
        std::hint::spin_loop();
    }
}

/// Per-tick lateness vs. the scheduled deadline, for the stop-time report.
#[derive(Default)]
struct TickStats {
    count: u64,
    min: Duration,
    max: Duration,
    sum: Duration,
}

impl TickStats {
    fn record(&mut self, late: Duration) {
        self.count += 1;
        self.min = self.min.min(late);
        self.max = self.max.max(late);
        self.sum += late;
    }
}

impl std::fmt::Display for TickStats {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let avg = if self.count == 0 {
            0
        } else {
            (self.sum.as_micros() / self.count as u128) as u64
        };
        write!(
            f,
            "min/avg/max late {}µs / {}µs / {}µs ({} ticks)",
            self.min.as_micros(),
            avg,
            self.max.as_micros(),
            self.count
        )
    }
}

#[derive(Clone, Copy)]
enum Lang {
    Scheme,
    Lua,
}

#[derive(Clone, Copy)]
enum State {
    Command,
    Repl,
    ReplLua,
    Running,
}

fn main() {
    let midi_out = MidiOutput::new("seq7").expect("failed to create MIDI output");
    let conn = midi_out
        .create_virtual("seq7")
        .expect("failed to create virtual MIDI port");
    let conn = Arc::new(Mutex::new(conn));

    let mut engine = Engine::new();

    engine
        .run(
            r#"
(define newline
  (case-lambda
    [()
     (#%raw-write-char #\return (current-output-port))
     (#%raw-write-char #\newline (current-output-port))]
    [(port)
     (#%raw-write-char #\return port)
     (#%raw-write-char #\newline port)]))
"#,
        )
        .expect("redefine newline");

    let dbg = Arc::new(AtomicBool::new(false));

    // Scheme console output is routed through this port. While dbg is off
    // (default), writes are swallowed so scripts can't spam the terminal;
    // enabling dbg passes everything through (and also turns on the MIDI
    // hex dump in raw-midi-write).
    let dbg_console = dbg.clone();
    engine.register_fn("gated-console-port", move || {
        SteelVal::new_dyn_writer_port(GatedConsole(dbg_console.clone()))
    });
    engine
        .run("(current-output-port (gated-console-port))")
        .expect("install gated console port");

    let dbg_log = dbg.clone();
    engine.register_fn("log-raw", move |bytes: Vec<u8>| {
        if dbg_log.load(Ordering::Relaxed) {
            use io::Write;
            let mut stdout = io::stdout();
            write!(stdout, "\rlog: {:02x?}\r\n", bytes).unwrap();
            stdout.flush().unwrap();
        }
    });

    let midi = conn.clone();
    let dbg_midi = dbg.clone();
    engine.register_fn("raw-midi-write", move |bytes: Vec<u8>| {
        midi_send(&dbg_midi, &midi, &bytes);
    });

    let mut script_path = std::env::args().nth(1);

    let frame = Arc::new(Mutex::new(Duration::from_millis(1)));

    {
        let frame = frame.clone();
        engine.register_fn("set-tick-speed", move |ms: u64| {
            let d = Duration::from_millis(ms.max(1));
            *frame.lock().unwrap() = d;
        });
    }

    // Lua 5.4 VM (mlua), coexisting with the steel engine. The script
    // language is picked by file extension (.lua → Lua, everything else →
    // Scheme); see load_file.
    let mut lua = Lua::new();
    let mut lang = Lang::Scheme;

    // Lua console output goes through the same dbg gate as the Scheme
    // current-output-port, via this sink + the preamble below. The gate is
    // best-effort (io.stdout:write and the like still bypass), the same
    // class of weakness as the Scheme one.
    {
        let lua_console = dbg.clone();
        let seq7_write = lua
            .create_function(move |_, text: String| -> LuaResult<()> {
                let _ = gated_console_write(&lua_console, text.as_bytes());
                Ok(())
            })
            .expect("create Lua _seq7_write");
        lua.globals().set("_seq7_write", seq7_write).expect("install Lua _seq7_write");
    }
    lua.load(
            r#"
local w = _seq7_write
print    = function(...) w(table.concat({...}, "\t") .. "\n") end
io.write = function(...) w(table.concat({...})) end
"#
        )
        .exec()
        .expect("install Lua console preamble");

    {
        let dbg_log = dbg.clone();
        let log_raw = lua
            .create_function(move |_, bytes: LuaVariadic<u8>| -> LuaResult<()> {
                if dbg_log.load(Ordering::Relaxed) {
                    use io::Write;
                    let mut stdout = io::stdout();
                    write!(stdout, "\rlog: {:02x?}\r\n", &bytes).unwrap();
                    stdout.flush().unwrap();
                }
                Ok(())
            })
            .expect("create Lua log_raw");
        lua.globals().set("log_raw", log_raw).expect("install log_raw");
    }

    {
        let midi = conn.clone();
        let dbg_midi = dbg.clone();
        let raw_midi = lua
            .create_function(move |_, bytes: LuaVariadic<u8>| -> LuaResult<()> {
                midi_send(&dbg_midi, &midi, &bytes);
                Ok(())
            })
            .expect("create Lua raw_midi_write");
        lua.globals()
            .set("raw_midi_write", raw_midi)
            .expect("install raw_midi_write");
    }

    {
        let frame = frame.clone();
        let set_speed = lua
            .create_function(move |_, ms: u64| -> LuaResult<()> {
                let d = Duration::from_millis(ms.max(1));
                *frame.lock().unwrap() = d;
                Ok(())
            })
            .expect("create Lua set_tick_speed");
        lua.globals().set("set_tick_speed", set_speed).expect("install set_tick_speed");
    }

    // Load the script only after every Rust function (Scheme and Lua) has
    // been registered, so scripts can call set-tick-speed (and friends) at
    // load time instead of failing with FreeIdentifier / a nil global.
    if let Some(ref path) = script_path.clone() {
        load_file(&mut engine, &mut lua, &mut lang, path);
    }

    let mut rl = rustyline::DefaultEditor::new().expect("rustyline editor");
    let mut state = State::Command;
    let mut return_to = State::Command;

    println!("seq7 v0.1.0 — virtual MIDI + Scheme script engine");
    println!("type help for commands, scheme for live Scheme, Enter on empty line to start tick loop");

    'main: loop {
        match state {
            State::Command => match rl.readline("seq7> ") {
                Ok(line) => {
                    rl.add_history_entry(&line).ok();
                    let line = line.trim().to_owned();

                    if line.is_empty() {
                        *frame.lock().unwrap() = Duration::from_millis(1);
                        if let Some(ref path) = script_path {
                            load_file(&mut engine, &mut lua, &mut lang, path);
                        }
                        println!("▶ running");
                        return_to = state;
                        state = State::Running;
                    } else if let Some(path) = line.strip_prefix("load ") {
                        let path = path.trim().to_string();
                        script_path = Some(path.clone());
                        load_file(&mut engine, &mut lua, &mut lang, &path);
                    } else if line == "load" {
                        println!("usage: load <file>");
                    } else if line.eq_ignore_ascii_case("dbg") {
                        let on = !dbg.load(Ordering::Relaxed);
                        dbg.store(on, Ordering::Relaxed);
                        println!("dbg {}", if on { "on" } else { "off" });
                    } else if line.eq_ignore_ascii_case("help") || line == "?" {
                        println!("commands:");
                        println!("  load <file>  — load and evaluate a script (.lua → Lua, else Scheme)");
                        println!("  scheme       — enter the live Scheme REPL");
                        println!("  lua          — enter the Lua REPL");
                        println!("  dbg          — toggle console output (off silences script prints + MIDI dump)");
                        println!("  help         — show this help");
                        println!("  quit         — exit");
                        println!("  Enter (empty) — start/stop the tick loop");
                    } else if line.eq_ignore_ascii_case("scheme") {
                        state = State::Repl;
                    } else if line.eq_ignore_ascii_case("lua") {
                        state = State::ReplLua;
                    } else if line.eq_ignore_ascii_case("quit")
                        || line.eq_ignore_ascii_case("exit")
                    {
                        break 'main;
                    } else {
                        println!("unknown command: {}", line);
                    }
                }
                Err(ReadlineError::Interrupted | ReadlineError::Eof) => break 'main,
                Err(e) => {
                    eprintln!("readline error: {:?}", e);
                    break 'main;
                }
            },

            State::Repl => match rl.readline("seq7> ") {
                Ok(line) => {
                    rl.add_history_entry(&line).ok();
                    let line = line.trim().to_owned();

                    if line.is_empty() {
                        *frame.lock().unwrap() = Duration::from_millis(1);
                        if let Some(ref path) = script_path {
                            load_file(&mut engine, &mut lua, &mut lang, path);
                        }
                        println!("▶ running");
                        return_to = state;
                        state = State::Running;
                    } else if line.eq_ignore_ascii_case("scheme") {
                        state = State::Command;
                    } else if line.eq_ignore_ascii_case("quit")
                        || line.eq_ignore_ascii_case("exit")
                    {
                        break 'main;
                    } else {
                        match engine.run(line) {
                            Ok(vals) => {
                                for val in vals {
                                    if !matches!(val, SteelVal::Void) {
                                        println!("{}", val);
                                    }
                                }
                            }
                            Err(e) => println!("{}", e),
                        }
                    }
                }
                Err(ReadlineError::Interrupted | ReadlineError::Eof) => break 'main,
                Err(e) => {
                    eprintln!("readline error: {:?}", e);
                    break 'main;
                }
            },

            State::ReplLua => match rl.readline("seq7> ") {
                Ok(line) => {
                    rl.add_history_entry(&line).ok();
                    let line = line.trim().to_owned();

                    if line.is_empty() {
                        *frame.lock().unwrap() = Duration::from_millis(1);
                        if let Some(ref path) = script_path {
                            load_file(&mut engine, &mut lua, &mut lang, path);
                        }
                        println!("▶ running");
                        return_to = state;
                        state = State::Running;
                    } else if line.eq_ignore_ascii_case("scheme") {
                        state = State::Command;
                    } else if line.eq_ignore_ascii_case("quit")
                        || line.eq_ignore_ascii_case("exit")
                    {
                        break 'main;
                    } else {
                        // eval first (returns the value of an expression line);
                        // if that fails, fall back to exec (statement line).
                        match lua.load(&line).eval::<LuaMultiValue>() {
                            Ok(vals) => {
                                for val in vals {
                                    if !val.is_nil() {
                                        match val.to_string() {
                                            Ok(s) => println!("{}", s),
                                            Err(e) => println!("{}", e),
                                        }
                                    }
                                }
                            }
                            Err(_) => {
                                if let Err(e) = lua.load(&line).exec() {
                                    println!("{}", e);
                                }
                            }
                        }
                    }
                }
                Err(ReadlineError::Interrupted | ReadlineError::Eof) => break 'main,
                Err(e) => {
                    eprintln!("readline error: {:?}", e);
                    break 'main;
                }
            },

            State::Running => {
                enable_raw_mode().expect("raw mode");
                flush_pending_events();

                // Anchored schedule: `next` advances by exactly one frame per
                // tick and is never re-derived from the current time, so a late
                // wakeup shifts a single tick instead of dragging the tempo.
                let f = *frame.lock().unwrap();
                let mut next = Instant::now() + f;
                let mut stats = TickStats {
                    min: Duration::MAX,
                    ..Default::default()
                };

                'running: loop {
                    // Wait out the slot. If the previous tick overran the
                    // schedule, re-anchor to now + f instead of piling up
                    // catch-up ticks.
                    let now = Instant::now();
                    if now >= next {
                        next = now + f;
                    } else {
                        sleep_until(next, now);
                        stats.record(Instant::now() - next);
                        next += f;
                    }

                    while event::poll(Duration::ZERO).unwrap() {
                        if let Ok(Event::Key(key)) = event::read() {
                            if key.kind == KeyEventKind::Press {
                                match key.code {
                                    KeyCode::Char(' ') => {
                                        println_raw!("■ stopped");
                                        state = return_to;
                                        break 'running;
                                    }
                                    KeyCode::Char('c')
                                        if key.modifiers == KeyModifiers::CONTROL =>
                                    {
                                        break 'main;
                                    }
                                    _ => {}
                                }
                            }
                        }
                    }

                    // The last-loaded script's extension decides which `tick`
                    // runs: a Lua function for .lua files, a Scheme function
                    // for everything else. Errors stop the loop either way.
                    let tick_result: Result<(), String> = match lang {
                        Lang::Scheme => {
                            match engine.call_function_by_name_with_args("tick", vec![]) {
                                Ok(_) => Ok(()),
                                Err(e) => Err(e.to_string()),
                            }
                        }
                        Lang::Lua => match lua.globals().get::<LuaFunction>("tick") {
                            Ok(tick) => tick.call::<()>(()).map_err(|e| e.to_string()),
                            Err(e) => Err(e.to_string()),
                        },
                    };
                    if let Err(e) = tick_result {
                        println_raw!("tick error: {}", e);
                        state = return_to;
                        break 'running;
                    }
                }

                disable_raw_mode().expect("disable raw mode");
                println_raw!("tick timing: {}", stats);
                flush_pending_events();
            }
        }
    }

    let _ = disable_raw_mode();
    {
        use io::Write;
        writeln!(io::stdout(), "").unwrap();
    }
}
