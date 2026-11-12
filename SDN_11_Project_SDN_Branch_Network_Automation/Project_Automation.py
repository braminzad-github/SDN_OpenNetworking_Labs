#!/usr/bin/env python3
"""Start foreground controllers, configure WAN, verify visibility, stop owned processes."""
import argparse
import base64
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from Project_Router_Config import apply

HERE = Path(__file__).resolve().parent
BACKUP = HERE / 'config_backup'
STATE = BACKUP / 'automation-processes.json'

def http_json(url, auth=False):
    headers = {}
    if auth:
        user = os.environ.get('ONOS_USER', 'onos')
        password = os.environ.get('ONOS_PASSWORD')
        if not password:
            raise RuntimeError('Set ONOS_PASSWORD in the shell; do not commit credentials')
        token = base64.b64encode((user + ':' + password).encode()).decode()
        headers['Authorization'] = 'Basic ' + token
    with urlopen(Request(url, headers=headers), timeout=5) as response:
        return json.load(response)

def reachable(url):
    try:
        with urlopen(url, timeout=3):
            return True
    except HTTPError as exc:
        return exc.code in (401, 403)
    except OSError:
        return False

def listening(port):
    try:
        with socket.create_connection(('127.0.0.1', port), timeout=1):
            return True
    except OSError:
        return False

def wait_for(label, predicate, timeout):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if predicate():
            print('READY', label, flush=True)
            return
        time.sleep(1)
    raise RuntimeError('Timed out waiting for ' + label + '; inspect config_backup logs')

def birth(pid):
    # Linux process creation tick protects against stale PID reuse.
    data = Path('/proc/%d/stat' % pid).read_text()
    return data.rsplit(')', 1)[1].split()[19]

def start(config):
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    for name, url, ports in [
            ('onos', config['onos_url'] + '/onos/ui/', (8181, 7777)),
            ('ryu', config['ryu_url'] + '/router/all', (8080, 6653))]:
        if reachable(url):
            print('REUSE', name, '(will not add shutdown ownership)')
            continue
        if any(listening(port) for port in ports):
            raise RuntimeError('Partial/conflicting %s listener; inspect and stop it manually' % name)
        command = list(config[name + '_command'])
        if name == 'ryu' and os.environ.get('RYU_MANAGER'):
            command[0] = os.environ['RYU_MANAGER']
        if name == 'onos' and os.environ.get('ONOS_HOME'):
            command[2] = os.environ['ONOS_HOME'].rstrip('/') + '/bin/onos-service'
        with (BACKUP / (name + '.log')).open('ab') as log:
            process = subprocess.Popen(command, cwd=str(HERE), stdout=log,
                                       stderr=subprocess.STDOUT, start_new_session=True)
        state[name] = {'pid': process.pid, 'birth': birth(process.pid), 'command': command}
        STATE.write_text(json.dumps(state, indent=2) + '\n')
        wait_for(name, lambda: reachable(url), config['timeout_seconds'])
    wait_for('Ryu OpenFlow6653', lambda: listening(6653), config['timeout_seconds'])
    wait_for('ONOS OpenFlow7777', lambda: listening(7777), config['timeout_seconds'])

def verify(config):
    with (HERE / config['router_config']).open() as stream:
        desired = json.load(stream)
    apply(config['ryu_url'], desired, verify=True)
    devices = http_json(config['onos_url'] + '/onos/v1/devices', auth=True)
    available = {d['id'] for d in devices.get('devices', []) if d.get('available') is True}
    missing = set(config['expected_onos_devices']) - available
    if missing:
        raise RuntimeError('Missing/unavailable ONOS devices: ' + ', '.join(sorted(missing)))
    (BACKUP / 'onos-devices.json').write_text(json.dumps(devices, indent=2) + '\n')
    (BACKUP / 'wan-router-state.json').write_text(json.dumps(
        http_json(config['ryu_url'] + '/router/all'), indent=2) + '\n')
    print('VERIFIED expected router state and all three ONOS devices')

def stop():
    if not STATE.exists():
        print('No controllers started by this script')
        return
    state = json.loads(STATE.read_text())
    remaining = {}
    for name, item in state.items():
        pid = item['pid']
        try:
            if birth(pid) != item['birth'] or os.getpgid(pid) != pid:
                print('SKIP stale ownership record', name)
                continue
        except FileNotFoundError:
            continue
        try:
            os.killpg(pid, signal.SIGTERM)
        except PermissionError:
            subprocess.run(['sudo', '-n', 'kill', '-TERM', '--', '-%d' % pid], check=True)
        for _ in range(50):
            try:
                os.killpg(pid, 0)
            except ProcessLookupError:
                break
            except PermissionError:
                pass
            time.sleep(0.1)
        else:
            print('Still stopping; inspect controller log/process group:', name, pid)
            remaining[name] = item
        print('STOP requested for owned process group', name, pid)
    STATE.write_text(json.dumps(remaining, indent=2) + '\n')

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('action', choices=['start', 'configure', 'verify', 'stop'])
    p.add_argument('--config', default='Project_Automation.json')
    args = p.parse_args()
    BACKUP.mkdir(exist_ok=True)
    with (HERE / args.config).open() as stream:
        config = json.load(stream)
    if args.action == 'start':
        start(config)
    elif args.action == 'configure':
        wait_for('WAN DPID', lambda: any(
            d.get('switch_id') == '0000000000000104'
            for d in http_json(config['ryu_url'] + '/router/all')), config['timeout_seconds'])
        with (HERE / config['router_config']).open() as stream:
            apply(config['ryu_url'], json.load(stream))
    elif args.action == 'verify':
        verify(config)
    else:
        stop()

if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        print('ERROR:', exc, file=sys.stderr)
        sys.exit(1)
