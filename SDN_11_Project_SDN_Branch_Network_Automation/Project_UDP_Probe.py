#!/usr/bin/env python3
"""Bounded UDP echo tests, including low service ports inside root lab nodes."""
import argparse
import socket
import time
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('mode', choices=['server', 'client'])
p.add_argument('--bind', default='0.0.0.0')
p.add_argument('--port', type=int, required=True)
p.add_argument('--peer')
p.add_argument('--count', type=int, default=5)
p.add_argument('--seconds', type=int, default=30)
a = p.parse_args()
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.settimeout(2)
if a.mode == 'server':
    s.bind((a.bind, a.port))
    end = time.monotonic() + a.seconds
    while time.monotonic() < end:
        try:
            payload, peer = s.recvfrom(2048)
        except socket.timeout:
            continue
        print('RECEIVED local-port=%d peer=%r payload=%r' % (a.port, peer, payload), flush=True)
        s.sendto(payload, peer)
else:
    if not a.peer:
        p.error('--peer is required in client mode')
    s.bind((a.bind, 0))
    # connect() makes the kernel accept replies only from the expected peer/port.
    s.connect((a.peer, a.port))
    successes = 0
    for i in range(a.count):
        payload = ('SDN-PROBE-%d' % i).encode()
        try:
            s.send(payload)
            received = s.recv(2048)
            if received == payload:
                successes += 1
                print('REPLY', i, 'from', s.getpeername())
        except (socket.timeout, OSError) as exc:
            print('NO REPLY', i, str(exc))
    print('%d/%d replies' % (successes, a.count))
    raise SystemExit(0 if successes == a.count else 1)
