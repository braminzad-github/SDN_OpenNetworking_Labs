# SDN Learning Labs

A progressive set of practical SDN exercises for Ubuntu, Mininet, Open vSwitch, Ryu, ONOS, and GNS3. These personal learning labs explore programmable forwarding, controllers, overlays, filtering, monitoring, and automation. They do not describe Oracle proprietary DC SDN internals.

Start with [00 Lab Setup](SDN_00_LabSetup/README.md). The reusable preconfigured Ubuntu VirtualBox VM includes all required applications and is the preferred route for the complete series. [Download the preconfigured Ubuntu SDN VM](https://liveswinburneeduau-my.sharepoint.com/:u:/g/personal/braminzad_swin_edu_au/IQAv_m6WfxYaTKZT4O6OhvkvAarseiSla89Hp5I4QfgqrNw?e=bmsMpi). A fresh introductory installation covers Labs01–03 and needs the additional controller/appliance setup for later labs.

## Lab Sequence

| Guide | Images |
| --- | --- |
| [00 SDN Lab Setup](SDN_00_LabSetup/README.md) | [3](SDN_00_LabSetup/images/) |
| [01 Lab 01 Linux Foundations](SDN_01_Lab01_Linux_Foundations/README.md) | [1](SDN_01_Lab01_Linux_Foundations/images/) |
| [02 Lab 02 Mininet Basics](SDN_02_Lab02_Mininet_Basics/README.md) | [2](SDN_02_Lab02_Mininet_Basics/images/) |
| [03 Lab 03 Mininet Python Topologies](SDN_03_Lab03_Mininet_Python_Topologies/README.md) | [1](SDN_03_Lab03_Mininet_Python_Topologies/images/) |
| [04 Lab 04 SDN Controllers: Ryu and ONOS](SDN_04_Lab04_SDN_Controllers_Ryu_ONOS/README.md) | [7](SDN_04_Lab04_SDN_Controllers_Ryu_ONOS/images/) |
| [05 Lab 05 Ryu Layer 3 Routing](SDN_05_Lab05_Ryu_L3_Routing/README.md) | [4](SDN_05_Lab05_Ryu_L3_Routing/images/) |
| [06 Lab 06 GNS3 and Open vSwitch Foundations](SDN_06_Lab06_GNS3_OVS_Foundations/README.md) | [13](SDN_06_Lab06_GNS3_OVS_Foundations/images/) |
| [07 Lab 07 OVS VLANs, LACP, and Controllers](SDN_07_Lab07_OVS_VLAN_LACP_Controllers/README.md) | [6](SDN_07_Lab07_OVS_VLAN_LACP_Controllers/images/) |
| [08 Lab 08 OVS VXLAN and GRE Overlays](SDN_08_Lab08_OVS_VXLAN_GRE/README.md) | [5](SDN_08_Lab08_OVS_VXLAN_GRE/images/) |
| [09 Lab 09 OpenFlow Filtering and Port Translation](SDN_09_Lab09_OpenFlow_Filtering_Translation/README.md) | [8](SDN_09_Lab09_OpenFlow_Filtering_Translation/images/) |
| [10 Lab 10 OVS Port Mirroring](SDN_10_Lab10_OVS_Port_Mirroring/README.md) | [5](SDN_10_Lab10_OVS_Port_Mirroring/images/) |
| [11 Project: SDN Branch Network and Automation](SDN_11_Project_SDN_Branch_Network_Automation/README.md) | [11](SDN_11_Project_SDN_Branch_Network_Automation/images/) |

## Repository Conventions

Keep these directories together so setup and navigation links work. Each lab has its own `images` and `config_backup` directories. Image numbering restarts within each lab: `image.png`, `image-1.png`, and so on. Copy image files into the repo alongside the README when adding screenshots.

Commands identify their Ubuntu, appliance, Mininet, VPCS, or ONOS context. Steps include verification, expected results, backup/redeployment, and targeted cleanup. The tmux helpers always enable mouse support. Source Pass/Credit/Distinction variants are combined into a single guide for each topic; assessment questions are replaced with guided tasks.

## Validation Status

These guides were adapted from the supplied lab documents and project, with commands, addressing, and static helper checks reviewed. The authoring workspace has no attached Ubuntu SDN VM, so the complete series still needs execution in the published VM. The guides contain the tests to perform and the evidence to retain. No sample screenshot or expected output should be taken as proof of a new local run.

The original lab documents and VM image are not redistributed in this package. The VM download is linked in Lab00; keep its version, checksum if available, and login information with the release details.

## Figure Placement

Diagrams and screenshots are placed beside the matching lab steps. Brief captions identify historical names, addresses, ports, or interface differences; follow the existing commands and current address tables. Guide folders use the SDN_ prefix. The project uses technology-based stages, topology diagrams, deployment tables, and copyable configuration/automation blocks.
