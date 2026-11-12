#!/usr/bin/env python3
"""Custom Mininet topologies; invoke with mn --custom, not directly."""
from mininet.topo import Topo

class SingleLab(Topo):
    def build(self, n=3):
        n = int(n)
        if n < 1:
            raise ValueError('n must be positive')
        switch = self.addSwitch('s1')
        for i in range(1, n + 1):
            host = self.addHost('h%d' % i)
            self.addLink(host, switch)

class LinearLab(Topo):
    def build(self, n=3):
        n = int(n)
        if n < 1:
            raise ValueError('n must be positive')
        previous = None
        for i in range(1, n + 1):
            switch = self.addSwitch('s%d' % i)
            host = self.addHost('h%d' % i)
            self.addLink(host, switch)
            if previous is not None:
                self.addLink(previous, switch)
            previous = switch

class TreeLab(Topo):
    def build(self, depth=3, fanout=2):
        depth, fanout = int(depth), int(fanout)
        if depth < 1 or fanout < 1:
            raise ValueError('depth and fanout must be positive')
        switch_id, host_id = [0], [0]
        def grow(level, parent=None):
            switch_id[0] += 1
            switch = self.addSwitch('s%d' % switch_id[0])
            if parent is not None:
                self.addLink(parent, switch)
            for _ in range(fanout):
                if level == depth:
                    host_id[0] += 1
                    host = self.addHost('h%d' % host_id[0])
                    self.addLink(host, switch)
                else:
                    grow(level + 1, switch)
        grow(1)

topos = {'singlelab': SingleLab, 'linearlab': LinearLab, 'treelab': TreeLab}
