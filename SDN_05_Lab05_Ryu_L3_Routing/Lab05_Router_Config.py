#!/usr/bin/env python3
"""Apply/verify untagged Ryu rest_router state without duplicate POSTs."""
import argparse
import ipaddress
import json
import sys
from urllib.request import Request, urlopen

def request(base, dpid, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = Request(base.rstrip('/') + '/router/' + dpid, data=data,
                  headers={'Content-Type': 'application/json'})
    with urlopen(req, timeout=10) as response:
        result = json.load(response)
    if not isinstance(result, list):
        raise RuntimeError('Unexpected API response: %r' % result)
    for switch in result:
        for item in switch.get('command_result', []):
            if item.get('result') != 'success':
                raise RuntimeError('Ryu rejected request: %r' % result)
    return result

def entries(state):
    networks = [n for s in state for n in s.get('internal_network', [])
                if n.get('vlan_id', 0) in (0, '0')]
    addresses = {str(ipaddress.ip_interface(a['address']))
                 for n in networks for a in n.get('address', [])}
    routes = {(str(ipaddress.ip_network(r['destination'], strict=False)), r['gateway'])
              for n in networks for r in n.get('route', [])}
    return addresses, routes

def apply(base, config, verify=False):
    for dpid, desired in config.items():
        if len(dpid) != 16 or any(c not in '0123456789abcdef' for c in dpid):
            raise ValueError('DPID must be 16 lowercase hexadecimal digits')
        state = request(base, dpid)
        if not any(s.get('switch_id') == dpid for s in state):
            raise RuntimeError('Expected router not connected: ' + dpid)
        addresses, routes = entries(state)
        for address in desired.get('addresses', []):
            address = str(ipaddress.ip_interface(address))
            if address not in addresses:
                if verify:
                    raise RuntimeError('Missing %s on %s' % (address, dpid))
                print('ADD', dpid, address)
                request(base, dpid, {'address': address})
                addresses.add(address)
        for route in desired.get('routes', []):
            destination = str(ipaddress.ip_network(route.get('destination', '0.0.0.0/0'), strict=False))
            gateway = str(ipaddress.ip_address(route['gateway']))
            if any(d == destination and g != gateway for d, g in routes):
                raise RuntimeError('Conflicting route on %s to %s; inspect/delete it explicitly' % (dpid, destination))
            if (destination, gateway) not in routes:
                if verify:
                    raise RuntimeError('Missing route %s via %s on %s' % (destination, gateway, dpid))
                print('ADD', dpid, destination, 'via', gateway)
                request(base, dpid, {'destination': destination, 'gateway': gateway})
                routes.add((destination, gateway))
        # Read back from the controller; a successful POST alone is insufficient.
        actual_addresses, actual_routes = entries(request(base, dpid))
        expected_addresses = {str(ipaddress.ip_interface(a)) for a in desired.get('addresses', [])}
        expected_routes = {(str(ipaddress.ip_network(r.get('destination', '0.0.0.0/0'), strict=False)), r['gateway'])
                           for r in desired.get('routes', [])}
        if not expected_addresses <= actual_addresses or not expected_routes <= actual_routes:
            raise RuntimeError('Read-back failed for ' + dpid)
        print('VERIFIED', dpid)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('config')
    parser.add_argument('--url', default='http://127.0.0.1:8080')
    parser.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    with open(args.config) as stream:
        config = json.load(stream)
    apply(args.url, config, args.verify)

if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        print('ERROR:', exc, file=sys.stderr)
        sys.exit(1)
