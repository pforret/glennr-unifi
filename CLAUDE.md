# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a mirror/backup of Ubiquiti UniFi installation scripts from glennr.nl. The main purpose is to sync and distribute UniFi Network Controller installation scripts for Raspberry Pi and Ubuntu servers.

**Important**: These scripts were not created by the repository owner - they are developed by Glenn Rietveld from Ubiquiti. This is only a mirror repository for easier access and tracking.

## Architecture

### Main Script: `glennr-unifi.sh`

Built using the [pforret/bashew](https://github.com/pforret/bashew) framework (v1.20.5), this is the core synchronization script with the following structure:

- **Option Configuration**: Uses `Option:config()` to define CLI flags and parameters
- **Main Logic**: `Script:main()` handles the core actions
- **Helper Functions**: Custom functions like `download_from_glennr()` for web scraping
- **Framework Functions**: Built-in IO, OS, and Script utilities from bashew

### Directory Structure

```
scripts/
├── controller/     # UniFi Network Controller installation scripts
├── video/          # UniFi Video installation scripts
├── update/         # UniFi Easy Update scripts
├── fail2ban/       # UniFi Fail2Ban scripts
├── encrypt/        # UniFi Let's Encrypt scripts
├── remote/         # UniFi Remote Adoption scripts
└── latest/         # Symlinks to latest versions
```

## Development Commands

### Main Operations
```bash
# Sync all scripts from glennr.nl (main function)
./glennr-unifi.sh get

# Check script configuration and environment
./glennr-unifi.sh check

# Update repository to latest version
./glennr-unifi.sh update

# Generate example .env file
./glennr-unifi.sh env > .env
```

### Dependencies
The script requires:
- `wget` for downloading scripts
- `awk` for parsing HTML responses
- `setver` (for version management outside GitHub Actions)

### Automation
- GitHub Actions workflow runs daily at 09:15 UTC
- Automatically commits new script versions when found
- Uses `setver auto` for version bumping in local development

## Key Functions

### `download_from_glennr(url, folder)`
Web scraper that:
1. Downloads the webpage from glennr.nl
2. Extracts download links using awk pattern matching
3. Downloads each script file to the specified folder
4. Uses `wget -N` for timestamp-based conditional downloads

### Version Management
- Version stored in `VERSION.md` (currently 0.1.11)
- Automatic version bumping via `setver auto`
- GitHub Actions integration with `Gha:finish`

## Script Pattern Recognition

When working with the downloaded UniFi scripts, note they follow naming patterns:
- Controller scripts: `unifi-network-controller-*.sh`
- Video scripts: `unifi-video-*.sh` or `video-*.sh`
- Update scripts: `unifi-*.sh`

The `latest/` directory always contains the most recent versions for easy access.