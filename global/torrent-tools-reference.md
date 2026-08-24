### 🖥️ Command line (CLI) Tools

- **CineCLI**: A cross-platform CLI tool specifically for movie torrents. It searches the YTS API, automatically selects the best quality with healthy seeders, and can even launch the torrent directly from your terminal.
- **tomagnet**: A Go-based CLI and library that's a bit more advanced. It allows you to fetch and search against custom indexer definitions (like those used by Jackett) and output results in JSON or table format.

### 📦 New API & Backend Tools

- **Torrent Search MCP Server**: This is a versatile Python project that can be run in several modes: as a CLI, a FastAPI server, or an MCP (Model Context Protocol) server for easy integration. It can search ThePirateBay, Nyaa, 1337x, YTS, FitGirl, EZTV, SubsPlease, and BitTorrented.
- **go-torrent-go**: A concurrent torrent search engine written in Go that aggregates results from sites like 1337x, RARBG, NyaaSI, and Torrent9. It provides a JSON API and supports advanced filtering.

### 🧩 New Proxy & Aggregator Tools

- **JacRed-FDB**: A high-performance torrent indexing and search system that acts as middleware for media automation tools (Sonarr, Radarr). It works by scraping individual torrent trackers directly.

### 🧰 Modern Torrent Clients with APIs

If you ever need to build a custom download client, these are excellent choices with great APIs:

- **Porla**: A high-performance BitTorrent server designed for headless operation. It features a full HTTP API with JWT authentication and a Lua API for writing custom plugins and workflows.
- **Haul**: A self-hosted BitTorrent client with a modern React web UI and a full REST API. It's built to be a modern alternative to qBittorrent or Transmission and integrates well with media stacks like Sonarr/Radarr.

### 🐚 Unique Terminal Clients

- **superseedr**: A terminal user interface (TUI) BitTorrent client. It allows you to download and seed torrents directly from your terminal, track peers and pieces, and even shows real-time analytics like heatmaps and peer metrics.

### 🤖 Automation & RSS Tools

- **autobrr**: A powerful media automation tool that monitors IRC channels and RSS feeds for new releases, filters them based on your rules, and sends them to your download client. It supports 75+ torrent trackers.
- **FlexGet**: A program for automated downloading of media. It can process RSS feeds, HTML pages, and search engines to automatically find and download torrents based on your criteria.

### 📱 Android Apps

- **uToor**: A torrent search engine that lets you find magnet links, sort by seeders/leechers, and filter by category.
- **TorrDroid**: A torrent client that also has a built-in search engine, providing a hassle-free way to search and download torrents on your phone.

---

I'll add these new tools to the updated Markdown file below, making it an even more complete reference for your future projects.

---

# BitTorrent Search & Indexing Tools Reference

## 📋 Overview

A curated collection of BitTorrent search engines, indexers, and API tools categorized by their primary use case. All tools are self-hostable unless otherwise noted.

---

## 🔍 API-First & Backend Tools

### Torrentinim

**Status:** ⭐ **Top Recommendation for API-Backend Projects**

> A self-hosted, API-only torrent search engine and crawler designed specifically to be used as a backend.

- **Features:** JSON API endpoint, crawls major trackers, single lightweight binary (~700KB), memory efficient (~24MB)
- **Supported Sites:** eztv, 1337x, nyaa, rarbg, torrentdownloads.me, yts
- **API Type:** REST (JSON)
- **Source:** [https://github.com/sergiotapia/torrentinim](https://github.com/sergiotapia/torrentinim)
- **Installation:** Download binary from releases

---

### Bitmagnet

**Status:** ⭐ **Best for DHT Crawling & Independence**

> A self-hosted BitTorrent indexer, DHT crawler, and search engine with GraphQL API.

- **Features:** GraphQL API, built-in web UI, crawls DHT network (no reliance on tracker websites), full-text search
- **Supported Sites:** None (self-indexes from DHT)
- **API Type:** GraphQL
- **Source:** [https://github.com/bitmagnet-io/bitmagnet](https://github.com/bitmagnet-io/bitmagnet)
- **Installation:** Docker or Go binary

---

### Torrent Search MCP Server

**Status:** 🐍 **Versatile Python API & Server**

> A Python project that can run as a CLI, FastAPI server, or MCP server.

- **Features:** Multiple run modes (CLI, FastAPI, MCP), in-memory caching
- **Supported Sites:** ThePirateBay, Nyaa, 1337x, YTS, FitGirl, EZTV, SubsPlease, BitTorrented
- **API Type:** FastAPI (REST) / MCP
- **Source:** [https://github.com/philogicae/torrent-search-mcp](https://github.com/philogicae/torrent-search-mcp)
- **Installation:** `uvx torrent-search-mcp`

---

### go-torrent-go

**Status:** 🐹 **Concurrent Go Search Engine**

> A concurrent torrent search engine written in Go.

- **Features:** Multi-site search, advanced filtering, JSON API
- **Supported Sites:** 1337x, RARBG, NyaaSI, Torrent9
- **API Type:** JSON
- **Source:** [https://github.com/cterlecki/go-torrent-go](https://github.com/cterlecki/go-torrent-go)
- **Installation:** `go build`

---

## 🐍 Python Library & API Tools

### Torrent-Api-py

**Status:** 📦 **Best for Python Backends**

> An unofficial Python API for multiple torrent sites.

- **Features:** Wide site coverage, Python library, easy integration
- **Supported Sites:** 1337x, Piratebay, Nyaasi, Torlock, Torrent Galaxy, Zooqle, Kickass, Bitsearch, MagnetDL, YTS, and many more
- **API Type:** Python Library
- **Source:** [https://github.com/ngosang/torrent-api-py](https://github.com/ngosang/torrent-api-py)
- **Installation:** `pip install torrent-api`

---

## 🔄 Proxy & Aggregator Tools

### Jackett

**Status:** ⭐ **Best for Maximum Site Support**

> A universal translation proxy for torrent indexers.

- **Features:** Supports 500+ trackers, provides standardized Torznab API, translation proxy architecture
- **Supported Sites:** 500+ (all major and many niche trackers)
- **API Type:** Torznab / REST
- **Source:** [https://github.com/Jackett/Jackett](https://github.com/Jackett/Jackett)
- **Installation:** Docker, Linux binaries, Windows service

---

### Prowlarr

**Status:** 🔄 **Modern Alternative to Jackett**

> A modern indexer manager/proxy built on the same stack as Sonarr and Radarr.

- **Features:** Modern UI, comprehensive REST API, indexer sync with Arr stack
- **Supported Sites:** 500+ (same as Jackett)
- **API Type:** REST
- **Source:** [https://github.com/Prowlarr/Prowlarr](https://github.com/Prowlarr/Prowlarr)
- **Installation:** Docker, Linux binaries, Windows

---

### JacRed-FDB

**Status:** ⚡ **High-Performance Middleware**

> A middleware system that sits between media automation clients and trackers.

- **Features:** High-performance, scraping-based indexing
- **Supported Sites:** Multiple trackers via scraping
- **API Type:** Torznab-compatible
- **Source:** [https://github.com/immisterio/jacred-fdb](https://github.com/immisterio/jacred-fdb)

---

## 🖥️ Terminal (CLI) Tools

### torhunt

**Status:** ⭐ **Best for Quick Terminal Searching**

> A modern, distraction-free terminal torrent search and download tool.

- **Features:** Concurrent search, one-key downloads, non-blocking queue, privacy-focused
- **Supported Sites:** YTS, The Pirate Bay, 1337x, EZTV, Nyaa
- **Installation:** `npx torhunt` (requires Node.js v22+)
- **Source:** [https://github.com/rogerer/torhunt](https://github.com/rogerer/torhunt)

---

### NinjaBits

**Status:** 🥷 **Best for Stealth & Category Search**

> Terminal UI tool focusing on stealth and category-based searching.

- **Features:** TUI interface, headless mode with REST API, category filtering (Games, Movies, TV, Anime, etc.)
- **Supported Sites:** YTS, EZTV, Nyaa, SubsPlease, FitGirl, 1337x, The Pirate Bay, BitSearch, BitTorrented, SolidTorrents
- **Installation:** `npx ninjabits` (requires Node.js)
- **Source:** [https://github.com/matiasglessi/ninjabits](https://github.com/matiasglessi/ninjabits)

---

### CineCLI

**Status:** 🎬 **Best for Movie Torrents**

> A cross-platform CLI tool specifically for searching and launching movie torrents.

- **Features:** Fetches movie data via YTS API, auto-selects best quality and seeders
- **Supported Sites:** YTS
- **Installation:** Platform-specific binary
- **Source:** Available via various package managers

---

### torlnk

**Status:** 🔗 **Simple Zero-Setup Alternative**

> Another zero-configuration Node.js tool, very similar to torhunt.

- **Features:** Zero setup, headless mode for servers/seedboxes
- **Supported Sites:** YTS, The Pirate Bay, 1337x, EZTV, Nyaa
- **Installation:** `npx torlnk` (requires Node.js)
- **Source:** [https://github.com/hanzos/torlnk](https://github.com/hanzos/torlnk)

---

### Torrra

**Status:** 🐍 **Best for Jackett/Prowlarr Integration**

> Python-based TUI that works with Jackett or Prowlarr indexers.

- **Features:** Beautiful Textual TUI, persistent configuration, customizable themes
- **Supported Sites:** Depends on your Jackett/Prowlarr configuration
- **Installation:** `pipx install torrra`
- **Source:** [https://github.com/stabldev/torrra](https://github.com/stabldev/torrra)

---

### tomagnet

**Status:** 🐹 **Go CLI with Custom Indexer Support**

> A Go CLI and library for querying torrent indexers.

- **Features:** Fetches Cardigann/Jackett-style indexer definitions, JSON/table output
- **Supported Sites:** Configurable (default: btdig, yts, limetorrents, thepiratebay)
- **Installation:** `go install github.com/sergiobonfiglio/tomagnet/cmd/tomagnet@v0.3.9`
- **Source:** [https://github.com/sergiobonfiglio/tomagnet](https://github.com/sergiobonfiglio/tomagnet)

---

### TermSearch (Torrent Module)

**Status:** 🔍 **General-Purpose Search with Torrent Module**

> A personal search engine for the terminal with torrent search capabilities.

- **Features:** Multi-module search with torrent module
- **Supported Sites:** The Pirate Bay, 1337x, YTS, Nyaa, EZTV, Torrent Galaxy
- **Installation:** Go install
- **Source:** [https://github.com/skanehira/termsearch](https://github.com/skanehira/termsearch)

---

## 🧰 Torrent Clients with APIs

### Porla

**Status:** ⚡ **High-Performance Headless Server**

> A powerful BitTorrent client designed for servers and seedboxes.

- **Features:** HTTP API with JWT auth, Lua API for plugins, supports BitTorrent v1 and v2
- **API Type:** REST (HTTP) + Lua
- **Source:** [https://github.com/vktr/porla](https://github.com/vktr/porla)
- **Installation:** Download binary

---

### Haul

**Status:** 🚢 **Modern Client for Home Servers**

> A self-hosted BitTorrent client with a React web UI.

- **Features:** Full REST API, WebSocket event stream, modern UI, integrates with media stacks
- **API Type:** REST + WebSocket
- **Source:** [https://github.com/beacon-stack/haul](https://github.com/beacon-stack/haul)
- **Installation:** Docker or Go binary

---

### qBittorrent

**Status:** 🧩 **The Classic with a Great API**

> A well-known, feature-rich torrent client.

- **Features:** Extensive REST API, RSS support, widely used and documented
- **API Type:** REST (WebUI API)
- **Source:** [https://github.com/qbittorrent/qBittorrent](https://github.com/qbittorrent/qBittorrent)
- **Installation:** Available for all platforms

---

## 🐚 Unique Terminal Clients

### superseedr

**Status:** 🦀 **Rust-based TUI Client**

> A terminal user interface (TUI) BitTorrent client.

- **Features:** Real-time analytics (heatmaps, peer metrics), persistent state, VPN-aware
- **API Type:** TUI
- **Source:** [https://github.com/superseedr/superseedr](https://github.com/superseedr/superseedr)
- **Installation:** `cargo install superseedr`

---

## 🐀 Alternative Architecture Tools

### RatsSearch (Rats on The Boat)

**Status:** 🐀 **Full Desktop Application**

> A C++/Qt desktop application with its own DHT crawler and built-in client. (Note: Not a terminal tool)

- **Features:** Full GUI, console mode for headless, built-in torrent client, P2P search, ratings system
- **Architecture:** Self-contained DHT crawler (doesn't rely on tracker websites)
- **Platforms:** Windows, Linux, macOS
- **Source:** [https://github.com/DEAD10C5/rats-search](https://github.com/DEAD10C5/rats-search)

---

## 🤖 Automation & RSS Tools

### autobrr

**Status:** ⚡ **Media Automation Tool**

> Monitors IRC and RSS feeds for new releases and sends them to your download client.

- **Features:** Supports 75+ trackers, filter-based matching
- **Source:** [https://github.com/autobrr/autobrr](https://github.com/autobrr/autobrr)

---

### FlexGet

**Status:** 🔄 **Versatile Automation Program**

> Program for automated downloading of media from various sources.

- **Features:** Processes RSS feeds, HTML pages, and search engines
- **Source:** [https://github.com/FlexGet/FlexGet](https://github.com/FlexGet/FlexGet)

---

## 📱 Android Mobile Tools

### Torrent Search Engine

- **Type:** Android app, search aggregator
- **Features:** Multiple providers, sortable providers
- **Source:** Available on Google Play Store

### uToor

- **Type:** Android app, torrent search
- **Features:** Sort by seeders/leechers, filter by category, remove no-seeder results
- **Source:** Available on Google Play Store

### Torrent Search Revolution

- **Type:** Android app, multi-provider search
- **Note:** Pro key for ads removal

### Magnet Googo

- **Type:** Privacy-first Android search aggregator
- **Features:** Ad-free, searches multiple sites simultaneously, deduplicated results
- **Source:** Available on F-Droid or GitHub

### TorrDroid

- **Type:** Torrent client with built-in search
- **Features:** All-in-one search and download
- **Source:** APKMirror

---

## 📊 Quick Decision Guide

| Use Case                             | Recommended Tool                     |
| ------------------------------------ | ------------------------------------ |
| **Build a custom web UI with API**   | Torrentinim                          |
| **Maximum site support via API**     | Jackett or Prowlarr                  |
| **Python backend development**       | Torrent-Api-py or Torrent Search MCP |
| **DHT independence & GraphQL**       | Bitmagnet                            |
| **Quick terminal searching**         | torhunt                              |
| **Terminal with category filters**   | NinjaBits                            |
| **Terminal with movie focus**        | CineCLI                              |
| **Terminal with Jackett/Prowlarr**   | Torrra                               |
| **Full desktop application**         | RatsSearch                           |
| **High-performance headless client** | Porla                                |
| **Modern client for home servers**   | Haul                                 |
| **Android mobile**                   | Magnet Googo                         |

---

## 🚀 Quick Start Commands

```bash
# Terminal Tools (Zero Setup)
npx torhunt
npx ninjabits
npx torlnk

# Python API Tools
pip install torrent-api
uvx torrent-search-mcp

# Go Tools
go install github.com/sergiobonfiglio/tomagnet/cmd/tomagnet@v0.3.9
go build -o go-torrent-go github.com/cterlecki/go-torrent-go

# Rust Tools
cargo install superseedr
```

---

## 📝 Notes for Future Reference

1. **Docker Host Networking**: When using Docker containers to connect to host PostgreSQL, use `host.docker.internal` (macOS/Windows) or your Docker network IP (Linux).

2. **Bitmagnet Database Setup**: Bitmagnet automatically creates the database schema on first run. Just point it to your PostgreSQL.

3. **API Authentication**: Most self-hosted tools don't include built-in authentication. Add a reverse proxy (nginx, caddy) with auth if exposing publicly.

4. **Resource Considerations**: DHT crawlers (Bitmagnet, RatsSearch) are resource-intensive. Proxy tools (Jackett, Prowlarr) are lightweight.

---

## 🔗 Sources & References

| Tool               | GitHub Repository                                |
| ------------------ | ------------------------------------------------ |
| Torrentinim        | https://github.com/sergiotapia/torrentinim       |
| Bitmagnet          | https://github.com/bitmagnet-io/bitmagnet        |
| Jackett            | https://github.com/Jackett/Jackett               |
| Prowlarr           | https://github.com/Prowlarr/Prowlarr             |
| RatsSearch         | https://github.com/DEAD10C5/rats-search          |
| torhunt            | https://github.com/rogerer/torhunt               |
| NinjaBits          | https://github.com/matiasglessi/ninjabits        |
| CineCLI            | Available via package managers                   |
| torlnk             | https://github.com/hanzos/torlnk                 |
| Torrra             | https://github.com/stabldev/torrra               |
| tomagnet           | https://github.com/sergiobonfiglio/tomagnet      |
| TermSearch         | https://github.com/skanehira/termsearch          |
| Torrent-Api-py     | https://github.com/ngosang/torrent-api-py        |
| Torrent Search MCP | https://github.com/philogicae/torrent-search-mcp |
| go-torrent-go      | https://github.com/cterlecki/go-torrent-go       |
| Porla              | https://github.com/vktr/porla                    |
| Haul               | https://github.com/beacon-stack/haul             |
| superseedr         | https://github.com/superseedr/superseedr         |
| autobrr            | https://github.com/autobrr/autobrr               |
| FlexGet            | https://github.com/FlexGet/FlexGet               |
