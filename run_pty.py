#!/usr/bin/env python3
"""Drive seq7 under a pty: start the tick loop, run a while, stop, quit, dump output."""
import os, pty, select, sys, time

cmd = ["./target/debug/seq7"] + sys.argv[1:]
duration = float(os.environ.get("DURATION", "30"))

pid, fd = pty.fork()
if pid == 0:
    os.execv(cmd[0], cmd)

buf = b""
time.sleep(2)
os.write(fd, b"\n")  # empty line -> Running
time.sleep(duration)
os.write(fd, b" ")   # space -> stop + stats
time.sleep(1)
os.write(fd, b"quit\n")
time.sleep(1)
os.write(fd, b"\x03")  # Ctrl-C fallback

# drain until the child exits or 10s pass
end = time.time() + 10
alive = True
while time.time() < end:
    while True:
        r, _, _ = select.select([fd], [], [], 0.05)
        if not r:
            break
        try:
            data = os.read(fd, 4096)
        except OSError:
            alive = False
            break
        if not data:
            alive = False
            break
        buf += data
    if not alive:
        break
    try:
        wpid, status = os.waitpid(pid, os.WNOHANG)
    except ChildProcessError:
        break
    if wpid == pid:
        alive = False
        break
if alive:
    try:
        os.kill(pid, 9)
    except ProcessLookupError:
        pass
    os.waitpid(pid, 0)
else:
    try:
        os.close(fd)
    except OSError:
        pass
    os.waitpid(pid, 0)
sys.stdout.buffer.write(buf)