# Plugin Compatibility Tracking

This document tracks plugin compatibility for Minecraft version updates.

## Current Status

**Server Version**: Minecraft 1.21.10 (Paper)
**Target Version**: Minecraft 1.21.11+

## Blocking Plugins

These plugins are currently blocking the upgrade to MC 1.21.11+:

### WorldGuard
- **Current Status**: ❌ Not compatible with 1.21.11+
- **Source**: https://dev.bukkit.org/projects/worldguard
- **Alternative Source**: https://enginehub.org/worldguard
- **Last Checked**: 2025-12-19
- **Notes**: WorldGuard is a critical plugin for region protection. Cannot upgrade without it.

### Chunker (Simple Voice Chat)
- **Current Status**: ❌ Not compatible with 1.21.11+
- **Source**: https://modrinth.com/plugin/chunker
- **Project ID**: `chunker`
- **Last Checked**: 2025-12-19
- **Notes**: Provides proximity voice chat functionality. Check for updates regularly.

## Compatible Plugins

These plugins are confirmed compatible with 1.21.11+:

### Core Plugins
- ✅ **Paper** - Server software (always compatible with target version)
- ✅ **Multiverse-Core** - Multi-world management
- ✅ **Essentials** - Economy and commands
- ✅ **LuckPerms** - Permissions management
- ✅ **ViaVersion** - Backwards compatibility (usually updates quickly)
- ✅ **ViaBackwards** - Backwards compatibility

### Gameplay Plugins
- ✅ **PlotSquared** - Plot management
- ✅ **FastAsyncWorldEdit** - World editing
- ✅ **BlueMap** - Web map
- ✅ **CoreProtect** - Logging and rollback

### Utility Plugins
- ✅ **Vault** - Economy API
- ✅ **FancyNPCs** - NPC management
- ✅ **QuickShop** - Shop plugin

## Monitoring Schedule

Check for updates on the following schedule:

- **Weekly**: Check Modrinth for Chunker updates
- **Weekly**: Check EngineHub for WorldGuard updates
- **Monthly**: Review all plugin versions for updates
- **On MC Update**: Check all plugins when new Minecraft version releases

## Update Process

When blocking plugins become compatible:

1. **Verify Compatibility**
   - Check plugin pages for 1.21.11+ support
   - Read changelogs for breaking changes
   - Check for dependency updates

2. **Update Dockerfile**
   ```dockerfile
   # Update MC_VERSION
   ARG MC_VERSION=1.21.11

   # Update plugin downloads if needed
   # Most plugins auto-download latest version
   ```

3. **Test in Development**
   - Build new Docker image
   - Start test server
   - Verify all plugins load successfully
   - Test core functionality

4. **Update Documentation**
   - Update this file with new compatibility status
   - Update CLAUDE.md with new MC version
   - Update README if needed

5. **Deploy**
   - Merge PR
   - CI/CD will build and push new image
   - Update production deployments

## Plugin Links

### Modrinth Projects
- [Chunker](https://modrinth.com/plugin/chunker)
- [Multiverse-Core](https://modrinth.com/plugin/multiverse-core)
- [BlueMap](https://modrinth.com/plugin/bluemap)
- [WorldGuard](https://modrinth.com/plugin/worldguard)
- [LuckPerms](https://modrinth.com/plugin/luckperms)
- [Essentials](https://modrinth.com/plugin/essentialsx)
- [PlotSquared](https://modrinth.com/plugin/plotsquared)
- [FastAsyncWorldEdit](https://modrinth.com/plugin/fastasyncworldedit)
- [Simple Voice Chat](https://modrinth.com/plugin/simple-voice-chat)

### Other Sources
- [Vault (Spiget)](https://www.spigotmc.org/resources/vault.34315/)
- [EngineHub (WorldGuard, WorldEdit)](https://enginehub.org/)
- [Paper MC](https://papermc.io/)

## Notes

- Most plugins use auto-download from Modrinth API, which fetches the latest compatible version
- Some plugins (Vault, SmoothTimber, Shopkeepers) use direct download links
- PlotSquared is built from source to ensure latest fixes
- ViaVersion/ViaBackwards usually update within days of new MC releases

## Changelog

### 2025-12-19
- Created compatibility tracking document
- Identified WorldGuard and Chunker as blocking plugins for 1.21.11+
- Established monitoring schedule

---

Last Updated: 2025-12-19
