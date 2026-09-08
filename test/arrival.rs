// TEMP DIAGNOSTIC: subscriber that timestamps note arrivals on the seq7 virtual port.
// usage: cargo run --example arrival [duration_secs]
use midir::{MidiInput, MidiInputConnection};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{mpsc, Arc};
use std::time::{Duration, Instant};

fn main() {
    let dur = std::env::args()
        .nth(1)
        .and_then(|s| s.parse::<u64>().ok())
        .unwrap_or(60);

    let mut input = MidiInput::new("arrival-probe").expect("midi input");
    input.ignore(midir::Ignore::ActiveSense | midir::Ignore::Sysex);

    let ports = input.ports();
    let port = ports
        .iter()
        .find(|p| input.port_name(p).map(|n| n.contains("seq7")).unwrap_or(false))
        .expect("seq7 virtual port not found; start seq7 first");
    println!("connected to {}", input.port_name(port).unwrap());

    let (tx, rx) = mpsc::channel::<(Instant, Vec<u8>)>();
    let note_offs = Arc::new(AtomicU64::new(0));
    let note_offs_cb = Arc::clone(&note_offs);
    let conn: MidiInputConnection<()> = input
        .connect(
            port,
            "probe",
            move |_ts, bytes, _| {
                if bytes.len() >= 2 && bytes[0] & 0xF0 == 0x80 {
                    note_offs_cb.fetch_add(1, Ordering::Relaxed);
                } else if bytes.len() >= 2 && bytes[0] & 0xF0 == 0x90 && bytes[2] != 0 {
                    tx.send((Instant::now(), bytes.to_vec())).unwrap_or(());
                }
            },
            (),
        )
        .expect("connect");

    let t0 = Instant::now();
    let mut n = 0u64;
    let mut max_gap = Duration::ZERO;
    let mut max_gap_at = 0u64;
    let mut late_count = 0u64; // gaps deviating > 2ms from 150ms
    let mut early_count = 0u64;
    let mut total_gap = Duration::ZERO;
    let mut prev = Instant::now();

    loop {
        match rx.recv_timeout(Duration::from_millis(250)) {
            Ok((arr, bytes)) => {
                n += 1;
                let gap = arr.duration_since(prev);
                prev = arr;
                total_gap += gap;
                if gap > max_gap {
                    max_gap = gap;
                    max_gap_at = n;
                }
                if gap > Duration::from_millis(152) {
                    late_count += 1;
                    println!(
                        "t={:>8.3}s note {:3} {:02x} {:3} gap={:>8.1}ms   <-- late",
                        arr.duration_since(t0).as_secs_f64(),
                        n,
                        bytes[1],
                        bytes[2],
                        gap.as_secs_f64() * 1000.0
                    );
                } else if gap < Duration::from_millis(148) {
                    early_count += 1;
                }
                if n % 500 == 0 {
                    println!(
                        "t={:>8.3}s n={} avg_gap={:.3}ms",
                        arr.duration_since(t0).as_secs_f64(),
                        n,
                        total_gap.as_secs_f64() * 1000.0 / n as f64
                    );
                }
            }
            Err(_) => {
                if t0.elapsed() > Duration::from_secs(70) || (n == 0 && t0.elapsed() > Duration::from_secs(5)) {
                    break;
                }
            }
        }
        if t0.elapsed() > Duration::from_secs(dur) {
            break;
        }
    }
    drop(conn);
    println!(
        "summary: {} notes, {} note-offs, max gap {:.3}ms at note {}, late(>2ms) {}, early(<148ms) {}",
        n,
        note_offs.load(Ordering::Relaxed),
        max_gap.as_secs_f64() * 1000.0,
        max_gap_at,
        late_count,
        early_count
    );
}