# GatherMate2

![Version](https://img.shields.io/badge/version-asc--1.0.7-blue?style=for-the-badge) ![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-orange?style=for-the-badge)
[![Platform](https://img.shields.io/badge/platform-Project%20Ascension-green?style=for-the-badge)](https://ascension.gg/)
[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue?style=for-the-badge)](https://Xurkon.github.io/GatherMate2/)
![Downloads](https://img.shields.io/github/downloads/Xurkon/GatherMate2/total?style=for-the-badge&label=DOWNLOADS&color=e67e22)
[![Patreon](https://img.shields.io/badge/Patreon-Support-orange?style=for-the-badge&logo=patreon)](https://patreon.com/Xurkon)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?style=for-the-badge&logo=paypal)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=kancerous@gmail.com)

> **Optimized for Project Ascension** - Complete gathering node tracker for WoW 3.3.5a!

## Description

GatherMate2 collects herbs, mines, gas clouds, woodcutting nodes, treasure, and fishing locations and displays them on both the world map and minimap. This is the Ascension-compatible version with full support for Project Ascension's custom gathering systems.

## This Repository

This monorepo contains both addons:

| Addon | Version | Description |
|-------|---------|-------------|
| **GatherMate2** | asc-1.0.7 | Core gathering node tracker and display |
| **GatherMate2_Data** | asc-1.0.2 | Pre-populated Wowhead data for all node types |

## Features

* **Multi-Node Support** - Track herbs, mines, gas clouds, woodcutting, treasure, and fish
* **Dual Map Display** - Nodes appear on both world map and minimap
* **Auto-Collection** - Automatically records new node locations as you gather
* **Data Sharing** - Share node databases with party/guild members
* **Routes Compatible** - Works seamlessly with Routes addon for farming paths
* **FarmHud Compatible** - Pins display correctly on FarmHud HUD overlay
* **Customizable Icons** - Adjust icon size, alpha, and minimap display range
* **Import/Export** - Merge data from GatherMate2_Data or other sources
* **Performance Optimized** - Efficient memory usage for large databases

## Addon Compatibility

Works seamlessly with:

* **Routes** - Draw optimized farming routes through your nodes
* **FarmHud** - Display nodes on transparent HUD overlay
* **TomTom** - Waypoint navigation to nodes
* **Carbonite** - Compatible with Carbonite map system

## Gathering Types

| Type | Description |
|------|-------------|
| 🌿 **Herbalism** | All herb nodes and their locations |
| ⛏️ **Mining** | Ore veins and mineral deposits |
| 🌲 **Woodcutting** | Tree nodes (Ascension-specific) |
| ☁️ **Gas Clouds** | Engineering gas cloud locations |
| 🐟 **Fishing** | Fishing pools and hotspots |
| 💰 **Treasure** | Treasure chests and lockboxes |

## Commands

| Command | Description |
|---------|-------------|
| `/gathermate2` | Open configuration panel |
| `/gm2` | Shortcut to open configuration |

## Installation

1. Download the latest release
2. Extract both folders to `Interface/AddOns/`:
   - `GatherMate2`
   - `GatherMate2_Data`
3. Enable both addons in character select
4. Configure via `/gathermate2` command

## Importing Pre-Populated Data

1. Open GatherMate2 config: `/gm2`
2. Go to "Import Data" section
3. Check the node types you want to import
4. Click "Import GatherMate2Data"
5. Your maps will now show all known node locations!

## Changelog

### GatherMate2 asc-1.0.7
- Ascension client compatibility
- Full support for Project Ascension gathering systems
- Woodcutting node support
- Worldforge node support
- Minimap rotation support

### GatherMate2_Data asc-1.0.2
- Updated node data for Ascension
- Includes Wowhead and Ascension-specific node locations
- Added Worldforge data
- Added Tree (Woodcutting) data

## Authors

* **Kagaro** - Original author
* **Xinhuan** - Major updates and maintenance
* **Nevcairiel** - Contributor
* **Xan** - Ascension client compatibility
* **OttoDeFe** - Launcher icon

## Disclaimer

> World of Warcraft© and Blizzard Entertainment© are all trademarks or registered trademarks of Blizzard Entertainment in the United States and/or other countries. These terms and all related materials, logos, and images are copyright © Blizzard Entertainment.
