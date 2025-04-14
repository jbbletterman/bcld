# Release Information

## 2025

## April
* `2025-04-14 16:59:13` : Ported SSH configuration to [ISO-TWEAKS](./ISO-builder.sh)
* `2025-04-14 16:57:40` : [OAC-1190] Changed following packages from [REQUIRED](./config/packages/REQUIRED) to [CHROOT](./config/packages/CHROOT)
  * iptables
  * netfilter-persistent
  * plymouth-theme-spinner
  * unattended-upgrades
  * zstd
* `2025-04-11 16:51:22` : [OAC-1190] Added new packages for Intel Arc and OpenCL support:
  * libze-intel-gpu1
  * libze1
  * intel-opencl-icd
  * Mintor kernel patch: `6.11.0-21 --> 6.11.0-24`
* `2025-04-01 12:25:54` : [OAC-1257] Added `snd_intel_dspcfg.dsp_driver=1` to [BCLD config file](./config/bcld/bcld.cfg)
  * Deprecated `snd_hda_intel.dmic_detect=0`

## March
* `2025-03-28 12:13:14` : Minor kernel patch: `6.11.0-19` --> `6.11.0-21`
* `2025-03-25 12:27:39` : Added `firmware-sof-signed` to [REQUIRED](./config/packages/REQUIRED) packages
    - System should now have SOF audio support, may require additional configuration
* `2025-03-07 17:45:21` : Enabled xmodmap and xbindkeys configurations for TEST
    - Disabled server keys globally
* `2025-03-05 14:48:08` : Added license to [PXE-deploy](./tools/PXE-deploy.sh) script
    - Mindor kernel patch: `6.11.0-17` --> `6.11.0-19`

## February
* `2025-02-28 17:24:42` : [OAC-1247] BCLD TEST will now automatically start the app for testing purposes
    - Kiosk mode will also be disabled after 10 seconds, to test escape combinations
    - New system tests will run over SSH before switching to Chrome debugger
* `2025-02-25 15:35:05` : [OAC-1170] Added [xdotool](./config/packages/DEBUG) to DEBUG packages
* `2025-02-19 16:30:45` : [OAC-1170] Added [VERSION](./config/BUILD.conf) file to artifacts for PXE testing
* `2025-02-18 15:24:41` : [OAC-1170] Added new [PXE-deploy](./tools/PXE-deploy.sh) script
* `2025-02-14 12:06:56` : [OAC-1192] Kernel update `6.8.0-52` --> `6.11.0-18`
* `2025-02-07 10:28:51` : [OAC-1239] Fix network check
* `2025-02-06 16:48:16` : [OAC-1158] Added APP packages to cleanup in [chroot.sh](./script/chroot.sh)
* `2025-02-05 14:24:52` : [OAC-1158] Minor kernel patch: `6.8.0-51` --> `6.8.0-52`
* `2025-02-03 16:52:30` : [OAC-1158] Added new `import_pkg_list` method in [ISO-builder](./ISO-builder.sh) to add CHROOT packages

## January
* `2025-01-30 12:14:22` : [OAC-1158] Added DHCP fix to check lease right before app start in [startup](./script/startup.sh)
* `2025-01-09 12:41:47` : [OAC-1158] Set DHCP Client Identifier back to MAC address in [ISO-builder](./ISO-builder.sh)
    - Minor kernel patch `6.8.0-47` --> `6.8.0-51`

## 2024

## Oktober
* `2024-10-16 15:08:57` : [OAC-1163] Added new parameter to make the BCLD sound check optional: [bcld.audio.sound_check](./config/bcld/bcld.cfg)
    - Minor kernel patch `6.8.0-45` --> `6.8.0-47`
* `2024-10-11 17:21:26` : [OAC-1159] Changed `BCLD_MACHINE_ID` to `BCLD_HOST`, since the actual machine id is longer
* `2024-10-11 15:05:44` : [OAC-1159]
    - Added Super key to `xmodmap` configuration
    - Applied name corrections in repository for capitalization errors...
    - Added new `BCLD_KEYMAPs` function in [bcld_test](./test/bcld_test.sh) for quick analysis of key map status
    - Added new output in [Xconfigure](./script/Xconfigure.sh) for `BCLD_VERBOSE`
    - Shorten [BCLD_KEYMAPs](./test/bcld_test.sh)
* `2024-10-11 13:36:42` : [OAC-1159] Found conflicts between `Xkbmap`, `xmodmap` and `xbindkeys` configurations
    - `xkbmap` : Will be used to disable system keys, (like TTY switching)
    - [xmodmap](./config/X11/xmodmap/.xmodmap) : Will be used to disable entire keys (like Alt and Meta)
    - [xbindkeys](./config/X11/xbindkeys/.xbindkeysrc) : Will be used to disable custom shortcuts (like closing browser tabs in web browsers)
* `2024-10-10 17:14:01` : [OAC-1159] Fix typo in [Xconfigure](./script/Xconfigure.sh) that broke the entire script and disabled kiosk mode
* `2024-10-08 11:07:12` : [OAC-1159] Updated [xbindkeys](./config/X11/xbindkeys/.xbindkeysrc) configuration
    - Kernel update: `6.8.0-41` --> `6.8.0-45`
    - Updated GitHub workflows
        - [actions/upload-artifact@v2](https://github.blog/changelog/2024-02-13-deprecation-notice-v1-and-v2-of-the-artifact-actions/) is deprecated
        - Using `actions/upload-artifact@v4` now
        - [actions/checkout@v2](https://github.blog/changelog/2023-06-13-github-actions-all-actions-will-run-on-node16-instead-of-node12-by-default/) is deprecated
        - Using actions/checkout@v4 now
    - Moving xbindkeys and xmodmap configurations from RELEASE-tweaks to general (for testing)
        - These daemons must be triggered manually, therefore will not activate in TEST by default
## August
* `2024-09-05 15:51:37` : [OAC-1147] Minor kernel patch: `6.8.0-38` --> `6.8.0-41`

## July
* `2024-07-18 14:42:31` : [OAC-1120] Enabled redirect location for [BCLD_CHECK](./script/startup.sh)
    - BCLD will now follow redirects with BCLD_CHECK
    - Will proceed with `trap_shutdown` after 10s
* `2024-07-16 14:57:00` : Added new [BCLD Parameters](./config/bcld/bcld.cfg):
    - [OAC-1120] `bcld.network.check`: BCLD parameter to disable the netwerk check that downloads the BCLD_URL index page to test network speed
    - [OAC-1124] `Super_L + Tab` removed from [xBindKeys configuration](./config/X11/xbindkeys/.xbindkeysrc)
    - [OAC-1126] `dis_ucode_ldr`: Kernel parameter that disabled CPU microcode updates during boot and may help running BCLD on older systems
    - Removed outdated parameters and aliases from [BCLD ENVs](./config/bash/environment) and [BCLD Startup](./script/startup.sh)
    - Adding `Default output` to [BCLD TEST](./test/bcld_test.sh)
* `2024-07-15 14:03:58` : 
    - Improve console readability
    - [Client Logger](./script/client_logger.sh) was missing `NSSDB_KEYS` variable
    - Minor kernel patch: `6.8.0-35` --> `6.8.0-38`
* `2024-07-09 12:09:36` : [OAC-1118] Replace echos after printing during the sound checks
* `2024-07-08 14:06:28` : [OAC-1118] Restrict sound card `trap_shutdown` to Facet `BCLD_VENDOR`
* `2024-07-03 15:54:30` : [OAC-1106] 
    - Improved console output readability for TEST images
    - Remove all `BCLD_OPTS` configuration from [BCLD-INIT](./config/bash/bcld-init) and [BCLD_VENDOR](./script/bcld_vendor.sh)
    - Migrate all `BCLD_OPTS` configurations to [STARTUP](./script/startup.sh)
* `2024-07-03 11:18:40` : Unquote conditional to fix `KERNEL_PARAM` in [BCLD-INIT](./config/bash/bcld-init)
* `2024-07-02 16:37:41` : [OAC-1106]
    - Updated user password method after LTS upgrade (for TEST)
    - Improved `print_cert` and `print_key` TEST methods

## June
* `2024-06-26 14:03:48` : [OAC-1106] Revert major release to sync with Facet 13
* `2024-06-25 13:51:24` : [OAC-1103] Disable sound card `trap_shutdown` for `DEBUG` and `TEST` images
    - Will allow automatic tests to proceed without sound checks
    - `trap_shutdown` will still work in `RELEASE` builds
    - Added `logger` command to `list_item_fail` method (as `BCLD-ERROR`)
    - [OAC-1108] Minor kernel patch: `6.8.0-31 --> 6.8.0-35`
    - Fix SBOM test
* `2024-06-19 12:03:43` : [OAC-1100] Removed `BCLD_REALTEK` parameter from [BCLD ENVs](./config/bash/environment)
* `2024-06-04 17:43:10` : 
    - Added `check_tags` method to [ISO-builder](./ISO-builder.sh)
    - Improved GRUB output
    - Improved BCLD test package logging output
    - Changes some TAGs
* `2024-06-04 14:26:23` : Improvements to [BCLD-INIT](./config/bash/bcld-init)
* `2024-06-03 16:25:44` : Upgrade GitHub container LTS (24.04) in Workflows
    - Added `release/*` branch to `release` environment
* `2024-06-03 14:07:04` : 
    - Added `logout` to `bcld_set_hostname` method in [BCLD-INIT](./config/bash/bcld-init)
    - Clean up grub output

## May
* `2024-05-30 09:57:04` : `BCLD_RSYSLOG` has been obsoleted; Rsyslogging is now enabled for Facet by default
* `2024-05-23 12:25:59` : [OAC-1068]
    - [BCLD Vendor](./script/bcld_vendor.sh) now runs with root permissions through [BCLD-INIT](./config/bash/bcld-init)
    - Changes have been made to the BCLD Vendor script
    - Output goes to journal instead of console
    - Cleaned up build output with new headers and lists in [ISO-builder](./ISO-builder.sh) and [IMG-builder](./IMG-builder.sh)
    - Removed unnecessary functions from [ISO-builder](./ISO-builder.sh)
    - Added new [ISO-builder](./ISO-builder.sh) TAGs: 
        1. `ISO-SVCS` : Build component installs BCLD services
        2. `ISO-CERT` : Build component manages BCLD Certificate module
        3. `ISO-TWEAKS` : Build component manages configuration tweaks for BCLD_MODELs
        4. `ISO-CLEANUP` : Build component cleans up after SQUASHFS generation
        5. `ISO-CLEAR` :  Build component cleans up after finishing build
    - Added new [file operation](./script/file_operations.sh): `safe_return`
    - General cleanup of build output
    - Updated [Tag Check](./test/00_BCLD-BUILD.bats)
* `2024-05-23 12:09:01` : [OAC-1043]
    - Added new [bcld-log](./config/rsyslog/70-bcld-log.conf) config
    - Added new BCLD parameter: [bcld.afname.logging](./config/bcld/bcld.cfg)
    - Added new BCLD ENV: [BCLD_LOGGING](./config/bash/environment)
    - Config will be utilized for advanced BCLD logging metrics using new parameter
* `2024-05-22 14:03:32` : [OAC-1068] 
    - Improved [BCLD-INIT](./config/bash/bcld-init) by adding BCLD_VENDOR to ENVIRONMENT instead of exporting in root scope
    - Migrated [BCLD Vendor](./script/bcld_vendor.sh) script from [Startup](./script/startup.sh) to [BCLD-INIT](./config/bash/bcld-init)
* `2024-05-21 13:19:45` : [OAC-1068]
    - Moved some more sudo operations from [Startup](./script/startup.sh) to [BCLD-INIT](./config/bash/bcld-init)
    - Moved some more ENVs from [Startup](./script/startup.sh) to [Environment](./bash/enviroment)
* `2024-05-17 15:37:37` : [OAC-1068]
    - In Noble (24.04), `hostnamectl` can no longer be used without authorization
    - This means we need to migrate the hostname changes to a higher escalation than `./script/startup.sh`
    - Grouped bash configuration scripts in `./config/bash`
    - Added new [BCLD-INIT](./config/bash/bcld-init) root execution script for hostname changes
    - Added license to [BCLD Bash profile](./config/bash/profile.d/10-BCLD.sh)
    - Added `copy_post_config_dirs` to [ISO-builer](./ISO-builder.sh)
    - Added `link_file` to [File Operations](./script/file_operations.sh)
    - Added `bcld_init_links` to [ISO-builder](./ISO-builder.sh)
* `2024-05-15 14:20:26` : [OAC-1068] Upgraded more packages
    - Removed `libcups2` (UNNECESSARY)
    - Removed `librpm9` (UNNECESSARY)
* `2024-05-15 11:46:33` : 
    - Build log now displays failed packages
    - Added new [BUILD](./config/BUILD.conf) env: `DEFAULT_APP="(/usr/bin/qutebrowser &) && /usr/bin/qutebrowser :tab-close"`
    - `BCLD_APP` is now optional, but will override `DEFAULT_APP`
    - Optimized [Echo Tools](./script/echo_tools.sh), improved conditionals and removed sleeps
* `2024-05-14 16:06:51` : [OAC-1068] Upgrade [packages](./config/packages/REQUIRED)
    - Many packages replaced/updated
    - Python 3.10 > 3.12
    - Perl 5.34 > 5.38
    - Removed `libgsasl7` (DEPRECATED)
    - Removed `libsnapd-glib` (DEPRECATED)
    - Removed `lsb-core` (DEPRECATED)
    - Removed `rtl8821ce-dkms` (OBSOLETE)
    - Added `TZ` to [BUILD](./config/BUILD.conf) configuration
* `2024-05-14 17:31:56` : Bootstrap process made visible in build logs

## April
* `2024-04-16 15:02:15` : [Network check](./script/startup.sh#L366)
    - [OAC-1040] Now actually scans 3 times, instead of stopping after 2 tries
    - [OAC-1038] Now waits 3 seconds after every wireless scan if the network is unstable
    - [OAC-1039] Now shuts down the system on failure
* `2024-04-16 12:37:52` : Remove duplicate package `keyboard-configuration` from [REQUIRED](./config/packages/REQUIRED) packages
* `2024-04-11 16:35:55` : [OAC-905] Swapping mouse buttons 2 and 3 for Vendorless BCLD by default in [Xconfigure](./script/Xconfigure.sh#L99)
    - Mouse button 2 does not work in Vendorless BCLD
    - Swapping mouse buttons allows for usage of tabs on laptops
* `2024-04-10 17:11:10` : [OAC-1031] Enhanced `BCLD_CERTs` and `BCLD_KEYs` methods in [BCLD TEST package](./test/bcld_test.sh) to also include checks for client certificate and key
* `2024-04-04 17:24:11` : Migrated system requirements, USB configurations and tools from [README](./README.md) to [BCLD Wiki](https://www.github.com/jbbletterman/bcld/wiki)

## March
* `2024-03-26 11:58:27` : [OAC-837] Attempting to update kernel with `Illium` release: [6.5.0-26](https://packages.ubuntu.com/jammy-updates/linux-image-6.5.0-26-generic)
* `2024-03-25 14:10:46` : [OAC-486]
    - The [Release workflow](./.github/workflows/release%20(r8168).yml) now contains a BCLD Wiki export for archiving purposes
    - The [Extra workflow](./.github/workflows/extra%20(r8168).yml) now contains the SBOM generation for resource optimization
* `2024-03-25 12:22:20` : [OAC-986] Added BCLD Wiki project as submodule in [Modules](./modules/bcld.wiki)
    - Added [WIKI-exporter.sh](./tools/WIKI-exporter.sh)
* `2024-03-20 13:02:53` : [OAC-480] Added reporting template and `Disclosure Policy` to [Security Policy](./SECURITY.md)
* `2024-03-14 16:39:46` : [OAC-1003] Added `isolinux` package to [BUILD](./config/packages/BUILD) packages
    - Now generating new [isolinux.bin](./image/ISO/isolinux/)
* `2024-03-14 15:44:49` : [OAC-1005]
    - Add `pci=noaer` to [BCLD Client config](./config/bcld/bcld.cfg)
    - Change precommit to only commit changes if HashGen works
* `2024-03-14 12:45:25` : [OAC-480] Added section on Vulnerability Reporting in [Security Policy](./SECURITY.md#reporting-a-vulnerability)
* `2024-03-13 13:33:25` : [OAC-480] Updated [Security Policy](./SECURITY.md#reporting-a-bug)
    - More detailed description of bug reporting
* `2024-03-12 15:14:49` : [OAC-1000]
    - Moved BCLD assets to [BCLD Wiki](https://www.github.com/jbbletterman/bcld.wiki#bcld-flow-charts) project
* `2024-03-12 12:23:28` : [OAC-978] Updated all [license texts](./LICENSE.eupl) in scripts
* `2024-03-07 14:22:23` : [OAC-938] Added new font packages to support third party apps:
    - [fonts-font-awesome](./config/packages/REQUIRED)
    - [fonts-inconsolata](./config/packages/REQUIRED)
* `2024-03-06 15:15:15` : 
    - Added `licensecheck` to [BUILD](./config/packages/BUILD) packages
    - Added new [LICENSE-CHECK](./test/LICENSE-CHECK.sh) test to [BATS](./test/00_BCLD-BUILD.bats)
    - Added [SHELL-CHECK](./test/SHELL-CHECK.sh) back to [BATS](./test/00_BCLD-BUILD.bats)
    - Made the appropriate changes in [GitHub Workflows](./.github/workflows/release (r8168).yml)
    - Added new [GitHub Workflow](./.github/workflows/test.yml) for testing and saving resources
    - Added missing [EUPL licensing text](./COPYING) to various BCLD scripts
    - [BATS](./test/00_BCLD-BUILD.bats) tests now skip immediately upon failure
* `2024-03-05 14:32:08` : Make network check visible in [startup script](./script/startup.sh)
* `2024-03-04 13:54:55` : 
    - Renamed `X_PARAM` and `X_ALIAS` to `VENDOR_PARAM` and `VENDOR_ALIAS`
    - Make sure BCLD always reads the [BCLD_VERBOSE](./script/startup.sh) parameter first
    - Renamed methods in [BCLD Vendor script](./script/bcld_vendor.sh)

### Februari
* `2024-02-27 17:32:47` : Fixed NSSDB permissions in [BCLD Vendor script](./script/bcld_vendor.sh)
* `2024-02-26 14:49:36` : [OAC-836] BCLD now executes [HashGen](./tools/HashGen.sh) automatically as part of the new [pre-commit](.git/hooks/pre-commit) hook
* `2024-02-26 12:46:52` : Converted ShellCheck report to Markdown format
* `2024-02-26 10:35:35` : 
    - Split ShellCheck tests from [BCLD BATS](./test/00_BCLD-BUILD.bats) to [ShellCheck](./test/SHELL-CHECK.sh)
    - Added to [HashGen](./tools/HashGen.sh)
* `2024-02-23 15:54:27` : Fixed ALSA sound card check in [startup script](./script/startup.sh) to display results or failure
    - Also refactored [trap_shutdown](./config/profile.d/10-BCLD.sh) to include [snd-warning](./config/trap_shutdown/snd-warning/snd-warning-1.png)
* `2024-02-22 15:02:56` : Fixed output in BATS and ShellCheck test reports
* `2024-02-21 17:56:29` : Fixed missing description in SBOM
* `2024-02-21 12:21:25` : 
    - Added `echo_build` method to [BCLD-BATS](./test/00_BCLD-BUILD.bats) to fix a broken test in the GitHub Workflow
    - Split up BATS test to try and fix on GitHub Actions
    - Removed `ISO-CROS` TagCheck, because it will always fail in Vendorless BCLD
    - Added new [workflow](./.github/workflows/release%20(r8168).yml) for Realtek BCLD image
* `2024-02-19 16:03:28` : Added [Security Policy](./SECURITY.md)
* `2024-02-15 15:47:17` : Renamed `COPYING.eupl` back to [COPYING](./COPYING)
    - Fixed hyperlinks in [README](./README.md)
* `2024-02-15 15:30:43` : [OAC-833] There have been complaints about the network check [BCLD_DOWNLOAD](./script/startup.sh) performs
    - Outbound asset was [a 10mb PNG-file](https://www.thinkbroadband.com/assets/images/download-files/iconDownload-10MB.png)
    - Asset appears to be blocked in some client networks
    - New asset will be [BCLD_URL](./README.md#bcld-configuration) index page
* `2024-02-14 16:19:27` : [OAC-458] Added OVAL OpenSCAP evaluation to [BCLD test package](./test/bcld_test.sh)
* `2024-02-08 14:15:37` : Removed `bcld.realtek.driver` parameter from [BCLD ENVs](./config/bash/environment)
    - Driver is still not able to secureboot
    - Removed [r8168-dkms](./config/packages/REQUIRED)
* `2024-02-06 15:12:49` : Added KEY checks back to [bcld_vendor.sh](./script/bcld_vendor.sh)
    - BCLD will break if the NSSDB has a password
    - But when the NSSDB has a password, the URL prompts for it
    - This is undesirable
* `2024-02-05 13:58:35` : Disabled alternative BCLD_MD5CHECK
* `2024-02-05 11:39:11` : Fix permissions and remove NSSDB generation from [chroot.sh](./script/chroot.sh)
* `2024-02-02 15:25:10` : 
    - Fix certificate permissions inside [bcld_vendor.sh](./script/bcld_vendor.sh)
    - Remove KEY checks from [bcld_vendor.sh](./script/bcld_vendor.sh) (they no longer work since the NSSDB has password security)

### January
* `2024-01-26 16:46:24` : RepoMan dependency check updates
* `2024-01-26 13:38:45` : Kernel update `6.2.0-37` > `6.2.0-39` (kernel 6.5 does not yet support Realtek 8168)
* `2024-01-25 14:21:40` : Added [RepoMan](./RepoMan.sh) dependencies to [BUILD packages](./config/packages/BUILD)
* `2024-01-22 18:01:45` : BATS tests refactored into single file: `./test/00_BCLD-BUILD.bats`
* `2024-01-22 16:05:02` : Removing `test/00_PRE-BUILD.bats` because tests are not portable
* `2024-01-12 16:58:28` : Added `shellcheck` to `BUILD` packages and `./test/BCLD-BATS.sh`
* `2024-01-12 14:27:53` : [OAC-897] Added pactl scan before starting the app to detect hidden sinks
* `2024-01-11 13:48:04` : Expand HashGen to include `./.assets` and `./.github`
* `2024-01-10 12:39:20` : Vendorless BCLD released on GitHub
    - BATS modules readded
    - Cleanup up [README.md](./README.md)
* `2024-01-03 16:42:21` : 
    - Replaced `falkon` with `qutebrowser`
    - Unable to disable tabs, only downside
    - Added `Shift + Escape` to `.xbindkeys` for `QuteBrowser`
    - Plymouth English translation

## 2023

### December
* `2023-12-12 15:39:18`: More chroot checks
* `2023-12-11 17:13:44`: 
    - Updated `./BCLD_FLOW.png`
    - Delete `systemd-resolvd.service`
    - Added `BCLD_APP` to the required build ENVs
    - Improvements to checks for required ENVs
    - Removed value outputs for ENV checks as they are not needed
* `2023-12-08 16:12:01`: 
    - Introduce `BCLD_CFG_EDIT` as build variable
    - Allows custom text in `bcld.cfg` during build
    - Packages in `./config/packages/APP` will now only be installed if `./app` does not contain any packages
* `2023-12-08 14:19:46`: 
    - [OAC-770] `ttf-mscorefonts-installer` and `gsfonts-x11` removed from `REQUIRED` (did not fix Pi symbol)
    - [KERNEL PATCH] `6.2.0-36` > `6.2.0-37`
* `2023-12-07 13:02:53`: 
    - System will now immediately poweroff if selected app closes or crashes
    - This prevents RELEASE from reaching a terminal (TTY) if the app crashes unexpectedly
    - [OAC-806] `BCLD_VENDORLESS_URL` renamed to `BCLD_DEFAULT_URL`
* `2023-12-06 15:43:41`: `HashGen` now creates optional hashes and will no longer fail if directories are missing (like `./cert`)
* `2023-12-06 13:28:28`: [OAC-806] Removed `vendorless` parameter, is now a different build image
* `2023-12-05 14:43:24`: Adding `xbindkeys` and `./config/X11/xbindkeys` to disable extra key bindings in other apps
    - Adding `.xmodmap` in `./config/X11/xmodmap` for extra bindings
* `2023-12-04 14:13:20`: Added `F11`-key to `config/openbox/rc.xml` and sorted keybinds
* `2023-12-04 19:01:56`: Fixed `check_app` in `./ISO-builder.sh`

### November
* `2023-11-23 14:12:04`: [OAC-856] Unblacklist `r8168-dkms` to load as default
* `2023-11-22 15:38:29`: 
    - Moving most app check to the start of the build
    - Renamed `./deb` to `./app`
    - Enabled support for AppImages in `./app`
* `2023-11-22 13:07:38`: Renamed `check_opt` method to `check_app`
* `2023-11-22 12:49:38`: Testing Flatpak functionality with Chromium
* `2023-11-21 11:37:53`: Added `./packages/APP` and `chromium-browser`
* `2023-11-20 15:44:37`: Merged `./script/Xlogger.sh` with `./script/Xconfigure.sh`
* `2023-11-20 14:40:06`: [OAC-806] 
    - `FACET_SECRET` and `WFT_SECRET` are now optional
    - Build will no longer fail when SECRETS are not set
    - If no certificates are found in `./cert`, build will attempt `Vendorless BCLD`
    - Moved `./config/nssdb` to `./cert` for modularization and open source
    - Using `./Docker-builder.sh` now generates `./log` directory
* `2023-11-20 12:08:22`: Giving BCLD Parameters more meaningful home in `./config/bash/environment`
* `2023-11-15 13:47:29`: [OAC-770] 
    - Added `ttf-mscorefonts-installer` to `REQUIRED`
    - Requires `multiverse` in `./config/apt/sources.list`
* `2023-11-14 17:41:12`: [OAC-785]
    - Optimizations to Grub
    - [KERNEL PATCH] `6.2.0-36`
    - `xserver-xorg-video-openchrome` was also not included in `xserver-xorg-video-all`
* `2023-11-14 13:35:19`: [OAC-785]
    - Apparently `xserver-xorg-video-intel` is not included in `xserver-xorg-video-all`
    - Readded Intel X11 drivers
    - Added `xserver-xorg-video-qxl` for `TEST` (SPICE/QEMU X11 driver)
* `2023-11-06 17:22:54`: [OAC-770]
    - Added `gsfonts-x11` to `REQUIRED` packages
    - Added 3s sleep during startup for console readability.
* `2023-11-06 11:55:06`: [OAC-785]
    - Added `nvidia-utils` to NVIDIA packages
    - Added `nvidia-xrun` to Git `./modules`
* `2023-11-02 13:22:10`: [OAC-785]
    - Updated `nvidia_modules` in `./script/startup.sh`
    - Added `20-nvidia.conf` configuration in `./config/X11`
* `2023-11-01 13:47:44`: [OAC-785]
    - Added `nvidia-prime`, `nvidia-settings` and `pkg-config` to BCLD Nvidia
    - Removed `i915` from blacklist as it does not work
    - Replaced X11 drivers with `xserver-xorg-video-all`
    - Added `nouveau` to `./config/modprobe/blacklist.conf`
    - Added DMI system information to `./script/client_logger.sh`
    - Added `bcld_exports` to `./config/BUILD.conf`
    - Added `update_readme` to `./tools/HashGen.sh`

### October
* `2023-10-27 16:09:50`: [OAC-785] Added tools to `./test/bcld_test.sh` for BCLD Nvidia
* `2023-10-27 14:39:24`: 
    - Renamed `tools/docker_tools.sh` to `script/docker_run.sh`
    - Reduced console output
* `2023-10-27 12:35:58`: Introduced `true_brightness` & `true_scaling` methods to help cleanup `./script/Xconfigure.sh`
* `2023-10-27 11:42:31`: Removed unnecessary `update-manager` package causing errors
* `2023-10-26 16:05:23`: [OAC-785] Now blacklisting `Intel i915` in Nvidia builds
* `2023-10-26 11:20:13`: 
    - Added `check_iso_file` and `check_img_size` tests to `./scripts/file_operations.sh`
    - `./tools/NEXUS-deploy.sh` now uses `check_img_size` before uploading
    - `BCLD_STRING` renamed to `BCLD_NEXUS_STRING` for Nexus upload
    - `BCLD_NEXUS_STRING` moved to `./config/BUILD.conf` with global export
* `2023-10-25 14:58:07`: 
    - Improved `./IMG-builder.sh`
    - [OAC-785] Added `BCLD-Nvidia` to `BCLD_VERSION_FILE`
* `2023-10-25 13:42:27`: 
    - Removed remnants of `BCLD_VENDOR` in BATS tests and `BUILD.conf`
    - Implemented `check_req_envs` and `check_opt_envs`
* `2023-10-24 19:28:22`: Improved console output
* `2023-10-24 15:05:29`: [OAC-785] Added Nvidia drivers and console output
* `2023-10-20 12:25:31`: Expanded artifact check in `./IMG-builder.sh`
* `2023-10-19 17:44:20`: [OAC-804]
	- Removed `720p` and `SVGA` presets
	- Resolutions are too small to comply with Facet vendor
* `2023-10-19 16:33:46`: 
	- Casper fixes
	- `image/ISO/EFI/BOOT/` binary updates
	- These binaries are replaced during every new build
	- The updates are useful for `casper_md5check`
	- Because these binaries are checked during BCLD startup
* `2023-10-18 14:33:24`: [OAC-785] Added `BCLD Nvidia` build options
* `2023-10-11 23:48:33`: Improve shutdown flashing
* `2023-10-10 13:11:03`: 
	- Improved readability of console output
	- Added 3s to `init_app` method, so users can read/screenshot BCLD output
* `2023-10-09 18:42:13`: Placed a copy of `md5_file` in BCLD chroot
* `2023-10-09 16:08:02`: 
	- [OAC-783] New `BCLD_VENDOR`: `vendorless`
	- Added `./config/pam/login` settings to disable `motd-news` and `MAIL` services
	- Attempt to fix Casper md5 service by renaming `md5sum.txt` to `md5_file`
* `2023-10-06 17:05:13`: [OAC-782] Split `trap_shutdown` into `net_shutdown`, `virt_shutdown` and `param_shutdown`
* `2023-10-05 13:02:31`: Preset fixes
* `2023-10-04 16:51:10`: 
	- Added new `BCLD_VENDOR`: `default`
	- Rsyslogging feature no longer exclusive to `facet`
* `2023-10-03 12:56:53`: Corrected `VGA` preset name to `SVGA`
* `2023-10-02 17:34:06`: [OAC-779]
	- Added new BCLD preset: `768p`
	- Fixed BCLD preset: `720p` was `720P`
* `2023-10-02 14:20:02`: [OAC-766] Reverted back to `Caliburn` release name

### September
* `2023-09-29 14:55:59`: 
	- [OAC-776] Discontinued `sambo` as `BCLD_VENDOR`
	- Removed outdated file hashes in `./test/ubcld.md5`
	- Kernel patch `6.2.0-32` -> `6.2.0-33`
* `2023-09-22 10:27:57`: [OAC-752] Added new BCLD parameter: `bcld.realtek.driver`
* `2023-09-20 16:02:19`: [OAC-746] Added license references to `./script` and `./test` directories.
* `2023-09-18 16:35:17`: 
	- [OAC-742] Translated `COPYING` and `LICENSE`.
		- Continuing project in `ENGLISH`, will use `DUTCH` for licensing
	- [OAC-743] Deleted `./tools/bcld_build.sh` (obsolete)
	- [OAC-746] Added EUPL references: 
		- `BCLD-BATS.sh`
		- `BCLD_TEST.sh`
		- `docker_tools.sh`
		- `Docker-builder.sh`
		- `EXPORTER-TOOLKIT.sh`
		- `HashGen`
		- `IMG-builder.sh`
		- `ISO-builder.sh`
		- `LICENSE` 
		- `NEXUS-deploy.sh`, and
		- `RepoMan.sh`
* `2023-09-12 18:27:41`:
	- [OAC-738] Added [COPYING](./COPYING) and [LICENSE](./LICENSE)
	- Changed `CHANGELOG.md` to [CHANGELOG](./CHANGELOG)
	- Updated [README.md](./README.md)
* `2023-09-11 12:55:11`: Updated `README.md` with kernel version and parameters
* `2023-09-08 16:21:56`: [OAC-725] Changes made to `./tools/EXPORTER-TOOLKIT.sh` to be implemented in `./ISO-builder.sh`
* `2023-09-06 14:35:25`: Added `BCLD_KERNEL_VERSION` ENV
	- Will only be shown in logging and `TEST` versions
* `2023-09-06 12:12:00`: [OAC-705] Kernel patched to `6.2.0-32`
* `2023-09-05 14:54:31`: [OAC-712] Converged `LAN_TRIES` and `WLAN_TRIES` into `SCAN_TRIES`
* `2023-09-04 15:41:34`: [OAC-718] RepoMan updates
	- Moved `chrepoman.sh` to `tools/bcld-repo-manager`
* `2023-09-04 17:45:55`: Moved `./tools/bats` and `./tools/test_helper` to `./modules`
	- Git modules updated
* `2023-09-04 19:00:54`: [OAC-718] Removed all `mesa` and OpenGL packages
	- libegl-mesa0
	- libgl1
	- libgl1-mesa-dri
	- libgl1-mesa-glx
	- libglu1-mesa
	- libglx0
	- libglx-mesa0

### August
* `2023-08-31 12:44:11`: `Bootstrap` section removed from BCLD logging
	- Contains irrelevant CI/CD information
* `2023-08-30 14:49:18`: [OAC-712] Changed dhclient timeout to `20s` and `WLAN_TRIES` to `3`
* `2023-08-29 21:12:19`: [OAC-718]
	- APT now cleans more thoroughly
	- Removed `gcc-9`, `gcc`, `libgcc-dev`
	- `gcc-11` and `gcc-12` seem to auto-install as dependencies
	- Excluded `var/cache`, `var/lib/apt/lists` and `usr/share/backgrounds` from `mksquashfs`
* `2023-08-29 19:11:13`: Many `./tools` consolidated:
	- `tools/ART-exporter.sh`
	- `tools/IMG-exporter.sh`
	- `tools/IMG-mounter.sh`
	- `tools/ISO-exporter.sh`
	- `tools/LINK-exporter.sh`
	- All these tools have been consolidated into `./tools/EXPORTER-TOOLKIT.sh`
* `2023-08-28 18:07:33`: Added `vmlinuz`(kernel) and `initrd` (file system) to `./artifacts` post-build
  - For PXE usage and direct kernel booting
* `2023-08-16 11:26:51`: Swapped kernel back to `5.19.0-50` due to a misrelease
* `2023-08-15 12:29:13`: 
  - Fix `/VERSION` output
    - Renamed `BCLD_VERSION_FILE` to `BCLD_VERSION_STRING`, to be used as BUILD ENV
    - Renamed `BCLD_VERSION` to `BCLD_VERSION_FILE`, to be used in file names
* `2023-08-11 16:43:19`: [OAC-705] Kernel upgrade `5.19.0-50` > `6.2.0-26`
* `2023-08-11 14:35:41`: [BUG] Disable Wi-Fi powersaving which throws errors on `r8821ce`
	- Will enable better connectivity
* `2023-08-10 14:23:18`: [OAC-685] Migrating BCLD ENVs from `/etc/bash.bashrc` -> `/etc/environment`
	- ENVs do not need `export`
	- Absolved `./script/param_switcher.sh` into `./test/bcld_test.sh`
	- Removed Bamboo $PATH variable from client
	- Only show number of sinks if available
* `2023-08-08 13:35:26`: [OAC-379] Added filter for `bcld.display.scale_factor`
* `2023-08-07 14:11:53`: [OAC-471] Language translation complete
* `2023-08-02 17:28:48`: 
	- [OAC-541] DHCLIENT timeout back from 60s to 30s, as looking for connections takes too long
	- [OAC-584] `curl` added to REQUIRED packages, to check network stability

### July
* `2023-07-31 15:25:55`: [OAC-664] Kernel updated to `5.19.0-50` (HWE)
* `2023-07-06 15:41:49`: Added `TMP`, `TMPDIR` and `TEMP` ENVs to `BUILD.conf`
* `2023-07-04 12:37:36`: Added `dkms` to `BUILD` packages

### June
* `2023-06-29 16:40:17`: [OAC-584] Added `BCLD_DOWNLOAD` to ENVs
* `2023-06-28 10:44:53`:
	- XTerm fixes
	- [OAC-541] Set dhclient to 60s instead of 5s (very short)
* `2023-06-14 16:30:13`: [OAC-540] Added new parameters to `bcld.cfg`:
	- `acpi=off`
	- `nouveau.modeset=0`
* `2023-06-13 18:31:50`: [OAC-541] Reset dhclient retries back to default (5min, instead of 1h)
* `2023-06-09 14:25:15`: [OAC-570] Fixed grub config file extension for legacy
* `2023-06-07 14:44:05`: 
	- Fixes to `client_logger.sh` when running with sudo
	- `BCLD_MODEL` `TEST` now includes `BCLD_VERBOSE=1`
* `2023-06-07 10:41:07`: 
	- [OAC-462] `BCLD_PW` and `TEST_PW` merged into `BCLD_SECRET`
* `2023-06-06 21:31:53`: 
	- Split the file `BCLD_LOG` into `BCLD_LOG` and `OPENBOX_LOG`
	- Refactored BUILD TAGS
* `2023-06-06 13:01:56`: Wake-On-LAN refactor
	- `BCLD-rsyslogger` service removed
	- `rsyslogger.sh` is now a backgrounded shell (only `facet`)
	- Restarting the service interfered with WOL

### May
* `2023-05-22 12:51:46`: 
	- [OAC-446 KERNEL] Patched from `5.15.0-72` to `5.15.0-72`
	- [NETWORK STABILIZATION] Cache ENV variables like `BCLD_URL` and `BCLD_IF`
* `2023-05-10 16:08:19`: Removed `config/paplay` with login sound effect
* `2023-05-10 13:05:51`: Merged `bcld_functions.sh` with `file_operations.sh`
* `2023-05-09 12:37:44`: 
	- Execute emergency kernel patch `5.15.0-57 > 5.15.0.71` as availability ceased
	- Optimized disk usage during ISO build
* `2023-05-09 10:57:41`: Enable nullfix as the problem is persistent
* `2023-05-08 15:46:55` : Fixed X11 error which was popping back up
* `2023-05-05 16:05:35` :
	- Disabled `nullfix` for now
	- Added `clean_docker` to local build scripts
* `2023-05-04 16:19:09`: Added `nullfix` method in `./IMG-builder` to attempt to fix `/dev/null` if missing post-build
* `2023-05-03 13:47:20`: [Bamboo/Docker] Added `DOCKER-install.sh` tool
* `2023-05-01 18:06:21`: [iptables] New firewall rules to REJECT ICMPs instead of DROP

### April
* `2023-04-26 16:31:01`: `[OAC-595]` Updated ALSA configurations:
	- Added new BCLD parameter: `bcld.audio.alsa_port`
	- Added new BCLD parameter: `bcld.audio.alsa_sink`
* `2023-04-25 17:22:01`: `BCLD_ENVs` are now saved in `/etc/bash.bashrc` (for use between sessions)
* `2023-04-24 13:55:58`: 
	- `[OAC-598]` `BCLD_IF` and `BCLD_IP` no longer contains multiple interfaces when using wireless
	- Moved `bcld_test.sh` tools to `./test`
* `2023-04-17 14:49:13`:
	- Fixed a bug that re-enabled systemd-resolved
	- Enabled bootstrap caching for faster builds
* `2023-04-13 16:30:50`:
	- Now pushes `client_logger.sh` to journal after restarting Rsyslog service.
* `2023-04-12 13:26:20`:
	- Import `echo_tools.sh` into BCLD profile script
* `2023-04-11 19:36:30`:
	- Replace `bcld_cmds.sh` with `bcld_test.sh`
	- Will be used only in TEST
* `2023-04-06 18:59:05`: 
	- Added `scripts/bcld_vendor.sh` configuration script
	- Increase startup timer for readability (3s to 5s)
* `2023-04-04 12:50:04`: [OAC-597] 'MULTIVENDOR REFACTOR'
	- Rsyslogger service now included in every vendor, but only enabled for `facet`
	- `BCLD_VENDOR` removed from `ISO-builder.sh`
* `2023-04-04 10:59:37`: 'BUGFIXES'
	- Rsyslog
	- Rsyslog TLS
	- Hostname
	- Certificate Management

### March
* `2023-03-28 17:08:30`: 
	- Fixed bug for BCLD-crosdump service
	- Add firewall rules for DHCP
* `2023-03-27 14:45:31`: [OAC-593] Started refactoring `qBCLD`/`uBCLD` back to `BCLD`
* `2023-03-22 10:11:26`: 
	- qBCLD now using `BCLD_VENDOR` to select Chrome vendor package
	- qBCLD can now use a single artifact for multiple vendors
* `2023-03-21 12:03:28`: 
	- `script/autocert.sh` now only works for WFT (hardcoded)
* `2023-03-21 12:03:28`: 
	- Refactor hostname: qBCLD now picks a random physical MAC address from /sys
	- This ensures the hostname in case there is no default MAC address
* `2023-03-17 12:01:11`: Added new qBCLD Boot Parameter: `bcld.afname.shutdown`
	- Allows shutting down the client after inactivity inside the app
* `2023-03-09 16:01:53`: Added `qBCLD_PARAM` command to add ENVs manually in TEST
* `2023-03-09 12:38:31`: [OAC-522] Fixed typo in Rsyslog configuration
* `2023-03-08 16:49:12`: [OAC-565] Added automatic certificate selection
* `2023-03-08 13:22:54`: [OAC-581] Hostname changed to vendor name with MAC identifier for remote logging

### Februari
* `2023-02-22 10:24:35`: 
	- [OAC-522] `rsyslog` encryption and `iptables` changed to `10514` > `6514`
	- [KERNEL] patched to `5.15.0-57` (from `Pegasus`)
	- [OAC-522] `BCLD_CLIENT_KEY_1`, `BCLD_CLIENT_KEY_2`, `BCLD_CLIENT_KEY_3`, and `BCLD_CLIENT_KEY_4` can now be used to store qBCLD client key segments
* `2023-02-20 18:14:05`: 
	- [OAC-522] Added new certificate chains and removed keys from source
* `2023-02-09 15:04:50`: 
	- [OAC-522] Added certificate request and key for the client
	- [OAC-522] `facet` and `wft` `BCLD_VENDORS` now have preconfigured NSS databases
	- [OAC-522] Also added CA and client certificates signed with CA key
	- [OAC-522] The CA keys are not in this repository, but the client key that was used for signing the client certificates is
	  - This key is necessary for Rsyslog
	  - The Rsyslog server must have the same CA
* `2023-02-08 14:25:38`: 
	- [OAC-514] New qBCLD Boot Parameter for microphone recording volume: `bcld.audio.default_recording_vol`
	- [OAC-514] Will interact with default source selection (system will select if none selected): `bcld.audio.default_source`
* `2023-02-08 11:20:45`: 
	- `README.md` renamed to `CHANGELOG.md`
	- [OAC-561] `connect_lan` augmented with `detect_lan` for multiple interface detection
* `2023-02-07 17:57:22`:
	- [OAC-522] Certificate managment refactor complete
	- [OAC-522] Added `./cert` for `facet` and `wft` `BCLD_VENDORS`
	- [OAC-522] Added `./cert` to BATS tests
* `2023-02-03 22:26:28`: [OAC-522] Rsyslog encryption implemented on port `10514`
* `2023-02-02 13:31:30`: [OAC-522]`netcat` removed in favor of `rsyslog`

### January
* `2023-01-30 16:50:50`: 
	[OAC-522] `rsyslog` and `rsyslog-gnutils` unable to detect certificates for unknown reason
	[OAC-522] `rsyslog` lacks severe functionality and will be replaced by `syslog-ng`
* `2023-01-26 15:37:23`: 
	- [OAC-522] New dependencies `rsyslog` and `rsyslog-gnutls` added
* `2023-01-26 15:37:23`: 
	- [OAC-522] `./config/rsyslog` added for client Rsyslogging configurations
	- [OAC-522] `README.md` updated with server Rsyslogging configurations
* `2023-01-26 12:22:42`: [OAC-522] Converge certificates in one directory
* `2023-01-25 15:15:15`: [OAC-522] Certificate Management refactor: Only enabled if files are present in `./cert/`
* `2023-01-12 11:50:50`: 
	- [OAC-369] `alsactl restore` has been known to fix audio issues and will be added to the qBCLD Boot Parameters
	- [OAC-369] `bcld.audio.restore` is now available to request ALSA to restore audio devices before loading the app
	- [OAC-541] DHCP `TRIES` increased to 5
	- [OAC-544] `libc6` is a dependency for `libc6-dev` but will still be added to `REQUIRED` packages
* `2023-01-11 16:23:36`: [OAC-522] Rsyslogging disabled on request
* `2023-01-09 11:24:36`:
	- [OAC-469] English translation of source code completed
	- Removed old `paplay` configurations and qBCLD Braam

## 2022

### December
* `2022-12-14 17:10:10`:
`rsyslog` replaced by `netcat`
* `2022-12-13 15:48:33`:
  - Added `minidump_stackwalk` to environment
  - added `config/systemd/system/qBCLD-crosdump.service` to handle Chromium dumps
  - Added `qBCLD_FAO` to `TEST` commands
* `2022-12-12 17:48:31`:
  - Added `netcat` to `TEST`
  - Added `rsyslog` configuration
  - `iptables` extended with `rsyslog` rules
  - Extended `README.md` with `Rsyslog` information
  - Removed `vt.global_cursor_default=0` from `config/grub/grub.cfg.img` because cursor is not visible in `TEST`
* `2022-12-09 13:59:15`:
  - [OAC-522] Added `jq` package for
  - [OAC-453] `script/ubcld_cmds.sh` updated to `script/qbcld_cmds.sh`
* `2022-12-08 15:45:08`:
  - [OAC-522] Added `rsyslog` package
  - [OAC-522] Added `iptables` lines for `rsyslog`
  - [OAC-453] `uBCLD` namechanges to `qBCLD`
  - [OAC-453] `ubcld_logo.png` updated to `qbcld-logo.png`
  - Build configurations updated: `Omniscius 0`
* `2022-12-07 16:36:14`: [OAC-541] DHCP `TRIES` enabled with timer of 3600

### November
* `2022-11-16 13:07:41`:
  - [OAC-418] New parameter: `bcld.wwan.enable`
  - [OAC-418] WWAN is disabled unless this parameter is enabled
  - [OAC-415] Updated example link in `bcld.cfg`
* `2022-11-15 15:39:51`: `/VERSION` now displays shortened version of `BCLD_VERSION` (`BCLD_VERSION_FILE`)
* `2022-11-14 13:27:34`: Split `trap_shutdown` from `connect_lan` to allow LAN to be prioritized
* `2022-11-08 14:39:19`: Grub fix for ISO boot
* `2022-11-02 13:03:42`: Disable WWAN on every machine at runtime
* `2022-11-01 15:07:36`: Install `tlp` to enable/disable WWAN

### October
* `2022-10-31 18:29:03`: DHCP `TRIES` can be set to reconnect a number of tries
* `2022-10-31 14:08:28`:
  - `dhclient` timeout of 300 > 30
  - Searching for connection will retry instead of hanging (12x with 5s in between)
* `2022-10-31 10:14:59`:
  - `bcld.wifi.eap.auth` is now optional; default value is `mschapv2`
  - `bcld.cfg` NETWORK section updated
  - Updated `./README.md` with `bcld.wifi.eap.method`
* `2022-10-25 14:17:07`: Replacing `resolveconf` with `avahi-daemon` with regards to mDNS Service Discovery and auto-configuration
* `2022-10-24 17:40:12`: Added `BCLD_USER` to `README.md`
* `2022-10-24 13:22:04`:
  - `BCLD_USER` reintroduced as `BCLD_MODEL`
  - changed `hostname` back to `BCLD_VENDOR`
* `2022-10-24 12:24:11`: Logging extended with `Packages`
* `2022-10-20 17:37:11`: `BCLD_REMOTE` refactor: code separated from `./script/startup.sh` and shortened considerably
* `2022-10-20 17:02:41`: Removed packages `bind9-dnsutils`, `bind9-host` and `bind9-libs`
* `2022-10-20 15:49:44 `:
  - Openbox configurations separated by `BCLD_MODEL`
  - Hotfix for Openbox bug in RELEASE
* `2022-10-20 11:53:19`: Added missing TCP `iptables` lines for other `BCLD_MODEL`s
* `2022-10-19 15:53:29`: added `language-pack-nl`
* `2022-10-18 15:40:36`:
  - `graphical.target` set as default target
  - Grub now forces `systemd.unit=graphical.target` and `5` via `${PRIOMETERS}` (overrides the default)
  - `systemd.unit=graphical.target` is called later than the uBCLD Parameters and overrides it
  - `single` kernel parameter now triggers shutdown
  - `BUG`: Can disable Plymouth and give away information about the boot process
* `2022-10-17 13:43:49`: `nomodeset` is a parameter that occurs at least as often as `snd_hda_intel.dmic_detect=0` and is therefore included in the list of uBCLD Boot Parameters.
* `2022-10-14 17:31:35`: Added `uBCLD_LOGs` to `./script/ubcld_cmds`
* `2022-10-14 16:00:25`:
  - Network feedback improved
  - Casper MD5 check fixed
* `2022-10-13 19:08:05`: Expanded network logging
* `2022-10-10 16:14:45`: `r8168-dkms` enabled again because that wasn't the problem
* `2022-10-13 15:00:17`: `./script/client_logger.sh` refactored to run commands right in the beginning
* `2022-10-10 16:14:45`: `r8168-dkms` disabled again due to problems on other systems
* `2022-10-06 16:14:56`: Contents of `./chroot/nssdb` updated with NSSDB + CERT + KEY
* `2022-10-04 15:55:01`: `./script/ubcld_cmds.sh` extended with `uBCLD_AUDIO`
* `2022-10-04 12:34:27`:
  - `chown` fix for Bamboo
  - NSS database keys now also appear in logging, under certificates
* `2022-10-03 12:43:56`:
  - Moved test element from `uBCLD-BATS` (`uBCLD DEBs`) to build process so that `uBCLD-BATS` can check if `./chroot` is emptied for Bamboo
  - Extended `./script/file_operations.sh` with `clean_chroot` and `clean_art` for `./ISO-builder.sh` and `./IMG-builder.sh`
  - Split-screen functionality for Openbox with `DEBUG` configured

### September
* `2022-09-29 17:34:35`: `BCLD_FLOW.png` updated
* `2022-09-28 17:58:11`: Code refactor:
  - Removed unused methods in `./script/startup.sh`.
  - Boot notifications shortened.
* `2022-09-27 16:11:39`: Major update to documentation `WFT Certificate`
* `2022-09-16 10:17:09`:`bcld.wifi.eap.domain` removed, domain name is now allowed with EAP User
  - EAP User and PW are now base64 decoded
* `2022-09-15 17:17:38`: VM-detection update: Modifying `BCLD_MODEL` is no longer enough to bypass the system
  - uBCLD now also looks at `/VERSION` and the `hostname`
  - `hostname` has been modified and now contains model name
  - Previously: `facet@facet`
  - Current: `facet@ubcld-test-lachesis`
* `2022-09-14 17:56:30`: Interface set for wired connection so system log is not cluttered with DHCP
* `2022-09-14 16:16:10`:
  - USB Logging fix
  - `BCLD-USB` checks for `bcld.cfg` at boot with write permissions
  - If this fails, a new 'BCLD-USB' will be searched for
  - Once a USB has been connected with `bcld.log`, it must not be disconnected
* `2022-09-13 13:53:55`:
  - `tools/IMG-mounter.sh` added
  - `README.md` updated with `tools/IMG-mounter.sh`
  - `inotify-tools` package added
* `2022-09-09 14:29:45`: `README.md` updated with `tools/uHashGen.sh`
* `2022-09-08 13:27:01`:
  - Enable overamplification for `pactl` (default: 125%)
  - `paplay` removed
* `2022-09-08 10:49:30`: [KERNEL] rollback to `5.15.0-40` due to audio issues
* `2022-09-05 14:07:03`: `paplay` now plays a sound on app launch, to test the sound
* `2022-09-01 17:46:44`: Removed `pmount` as it was not working properly
* `2022-09-01 12:53:18`:
  - Converted `FAT-LABEL` to BUILD param.
  - Added `BCLD-USB.service`

### August
* `2022-08-31 17:21:06`: Adding `udev` rules for `usb_logger.sh`
* `2022-08-31 14:18:58`:
	- modified `script/usb_logger.sh` to filter `BCLD-USB` on system attributes
	- added `config/udev/rules.d/BCLD-USB.rules` to kickstart `script/usb_logger.sh`
* `2022-08-29 13:31:02`:
	- WFT-cert trustargs set to `CT,c,c`
	- Added `uBCLD_CERTs` method to `script/ubcld_cmds.sh`
* `2022-08-26 15:14:54`: Removed `bind9` as it causes DNS issues in some networks
* `2022-08-25 11:59:517`:
	- Better stabilization of network handling
	- added `ubcld_cmds.sh`
* `2022-08-24 19:35:37`: Default interface is now forced if not set (for EAP)
* `2022-08-24 13:45:45`: Fixed issue where uBCLD locks after closing the screen
* `2022-08-23 14:46:10`:
	- Reimplemented `r8168-dkms`
	- `bcld.wifi.eap`-parameters reintroduced
	- Added `connect_eduroam` function
* `2022-08-17 17:04:07`:
	- Removed `bcld.dnssec` boot parameter
	- Added BIND9, will automatically validate DNSSEC when present
	- No parameter needed anymore
* `2022-08-17 17:04:07`: Added `./tools/uBCLD-BATS.sh`
* `2022-08-17 16:19:13`: Added `bcld.dnssec` boot parameter
* `2022-08-16 17:14:55`: Added `./tools/ART-exporter.sh`
* `2022-08-16 11:32:53`:
	- DNSSEC disabled, schools don't support it
	- Phasing out dummy repo because the cdrom can't umount
* `2022-08-15 12:11:08`:
	- Changed ISO naming from 'BCLD-USB' to 'bcld'
	- Partition labels of `BCLD-USB` kept (only ISO name changed)
* `2022-08-11 12:33:03`: **Build Configuration** and **uBCLD Configuration** merged into `README.md`
* `2022-08-10 12:41:36`: `bcld.display.scale_factor` changed from floating-point to percentage
* `2022-08-09 13:48:58`: Vendor logo updates
* `2022-08-08 12:00:25`:
	- added uBCLD splash art
	- Grub configuration files moved from `./image/` to `./config/grub/`
* `2022-08-05 19:58:39`: Plymouth splash now shows textual description
* `2022-08-04 13:37:22`: Added `ENV Checker` to BATS tests
* `2022-08-03 16:08:07`:
	- Grub updated to `2.06` and is now also generated locally for UEFI for better control
	- Added `BCLD_VERSION` ENV with the contents of `/VERSION`
* `2022-08-03 13:13:36`:
	- [KERNEL] patch `.41` -> `.43`
	- Header output cleaned up
* `2022-08-02 15:52:34`:
	- Console output cleaned up
	- Added `XTerm` to BATS
* `2022-08-02 12:46:47`:
	- Replace `bcld.decrease.xserver` with `bcld.decrease.verbose`
	- `BCLD_LAUNCH_COMMAND`-refactor
	- Added battery meter in welcome message
* `2022-08-01 12:08:18`: Replace `bcld.big.mouse` with `bcld.decrease.mouse`

### July
* `2022-07-28 20:59:13`: Replacing Plymouth Spinner with ProgressBar, for better feedback
* `2022-07-28 17:27:03`: Added `bcld.decrease.xserver` parameter, for debugging
* `2022-07-28 16:09:01`: Added BATS test for `iptables`
* `2022-07-28 13:37:43`: [KERNEL] patch 41
* `2022-07-28 12:36:40`: `iptables` fix
* `2022-07-27 13:18:47`:
	- **uBCLD Zoom** implemented
	- Added `bcld.decrease.zoom` parameter and updated documentation
* `2022-07-26 17:21:55`:
	- Implemented **uBCLD Big Mouse**
	Added `bcld.big.mouse` parameter and updated documentation
* `2022-07-25 15:55:02`:
    - added `big-cursor` package
* `2022-07-25 12:55:46`: Added `snd_hda_intel.dmic_detect=0` to `KERNEL` parameters in `bcld.cfg`
* `2022-07-22 14:05:54`: Added `alsa-base.conf` to `./config/modprobe/`
* `2022-07-20 13:38:27`: Added `bind9-dnsutils` to `BUILD` packages for `UBCLD-BATS`
* `2022-07-20 11:41:46`: Grub updates
* `2022-07-19 16:03:08`: `BCLD-USB` now visible in Windows 11
* `2022-07-19 15:07:13`: Added `File Integrity` test
* `2022-07-19 12:44:06`: Realtek R8168 (`r8168-dkms`) drivers installed, but conflicting with RTL8821ce
* `2022-07-18 12:33:30`: Added `Label Inspector` to `Testing`
* `2022-07-14 18:27:35`: BATS tests for Bamboo
* `2022-07-13 20:01:04`:
	- Massive BATS-updates
	- New tool: `uHashGen`
	- Added `./test/ubcld.md5` hash
* `2022-07-12 18:22:41`: `README.md` updated met `Testing`
* `2022-07-12 14:39:27`:
    - Added partition flags
    - Added packages `e2fsprogs` for partition labels
* `2022-07-11 15:22:55`: RTC set as local time
* `2022-07-07 15:50:41`: TAG refactoring
* `2022-07-07 15:20:03`: BASH Automated Testing System (BATS) added as Git module
* `2022-07-06 16:44:41`: Shutdown timer decreased to 5 seconds
* `2022-07-05 17:32:13`:
    - Fix for remote logins in `TEST`
    - [KERNEL] patch: `5.15.0-30` > `5.15.0-40`
* `2022-07-04 17:11:30`: Blacklist broken Secure Boot Realtek drivers

### June
* `2022-06-29 16:41:21`: ASCII BCLD art updated
* `2022-06-28 18:28:15`: Stability upgrades for `DEBUG` and `REMOTE` sessions
* `2022-06-28 17:35:39`: WOL check built-in for unsupported systems
* `2022-06-28 14:49:56`: Better cleanup for debug terminals
* `2022-06-27 20:11:57`: Replace `UBCLD_CODE_NAME`, `UBCLD_HOST`, `UBCLD_PATCH` and `UBCLD_RELEASE` with: `BCLD_CODE_NAME`, `BCLD_HOST`, `BCLD_PATCH` and `BCLD_RELEASE`
* `2022-06-27 16:31:59`:
	- Split chroot ENVs to `./config/bash/bash.bashrc`
	- Fixed initialization feedback in local sessions
* `2022-06-27 11:03:25`: Added firewall rules for PixelHunter in `DEBUG` and `TEST`
* `2022-06-24 12:48:32`: Second partition reverted to VFAT for readability on Windows systems
* `2022-06-23 12:42:34`:
	- replace `sfdisk` with `parted`
	- Returned to dual partition
	- `grub-install` working regardless of error
	- `HOTFIX 1`: Windows bootloader
	- `HOTFIX 2`: Wake-on-LAN
* `2022-06-22 20:54:28`: Code refactor to fix `grub-install`
	- Legacy support restored
	- Microsoft bootloaders reverted
* `2022-06-22 16:27:46`: EFI partition rolled back, because GRUB has a huge problem with partitions
* `2022-06-21 19:10:32`: Fix WOL by setting additional states (`failed`, `disabled`) as triggers
* `2022-06-21 14:25:44`: `libcanberra-gtk-module` and `libcanberra-gtk3-module` based on a warning in X11
* `2022-06-20 18:01:35`: Presets added:
	- `4K`
	- `1080p`
	- `HD+`
	- `XGA`
	- `720p` 
	- `VGA`
* `2022-06-20 17:10:17`: Removed `bcld.log` template
* `2022-06-20 15:35:06`: Plymouth images resized
* `2022-06-20 12:38:39`: Added Microsoft bootloaders
* `2022-06-14 15:38:54`:
	- IMG generation separated from ISO generation, because Grub operations are quite volatile
	- Added `./script/file_operations.sh`
* `2022-06-13 20:45:55`:
	- Added extra partition in image (against Grub build errors)
	- Increased disk space
* `2022-06-13 17:10:40`: Added Docker ISO build script
* `2022-06-13 14:43:48`: mDNS fixes to packages and `iptables`
* `2022-06-10 16:06:28`: Use of Debug allowed in VM, for quick testing of Debug port
* `2022-06-10 11:11:58`:
    - Firewall rules added for Multicasting (mDNS)
    - Rights to purchase map granted to vendor
    - Added `libnss-mdns` for mDNS support
* `2022-06-09 13:52:37`: Added logging output for X system configuration
* `2022-06-07 16:51:26`: Completely removed `BCLD_AUTOSTART` so that images always autostart and Release, Debug and Test images are more similar
* `2022-06-07 16:51:26`: Shutdown timer shortened to 20 seconds, to avoid crashes
* `2022-06-01 23:14:18`: `BUG`: WiFi does not work with Secure Boot enabled, because the official Realtek drivers are not signed
* `2022-06-01 22:39:30`: Added `bcld.log` template to image
* `2022-06-01 18:09:53`: Removed `bcld.decrease.start` parameter as it was breaking for `RELEASE` and `DEBUG`
* `2022-06-01 10:59:53`: Signal trapping disabled (console escaping)
* `2022-06-01 10:23:30`: X11 and boot errors further cleaned up
* `2022-06-01 13:54:25`: Grub stabilization with framebuffer and GFX payload for Plymouth

### May
* `2022-05-31 13:24:31`: Improved hypervisor detection
* `2022-05-30 12:19:25`:
    - Cleaned up EFI files, fixed Secure Boot glitch
    - Fixed grub formatting error
* `2022-05-24 10:24:42`: Legacy support enabled
* `2022-05-23 07:40:20`: Grub IMG generation put into build process
* `2022-05-20 12:15:14`: Added bootloader update instructions to `./README.md`
* `2022-05-19 17:56:18`: Grub BIOS added
* `2022-05-19 12:49:42`: Replacing `usbmount` with `usb_logger.sh` script
* `2022-05-19 11:02:34`: Mounting cleaned up (`dev/pts`)
* `2022-05-18 13:58:06`: Added `ubcld_build` tool
* `2022-05-17 14:38:20`: **Daedalus update**
    - [KERNEL] updated to `5.15.0-30`
    - Ubuntu LTS updated to `22.04 (jammy)`
    - Components upgraded:
        - International Unicode Components (v70)
        - Perl (v34)
        - Python (v3.10)
        - RPM tools (v9)
    - Added packages: `libldap-common`, `mailutils-mda`
    - Packages removed: `crda`, `libldap-2.4-2`, `libmailutils6`, `lupin-casper`,
    - The `usbmount` package is not accessible in Jammy
    - Automounting is therefore temporarily disabled (logging only happens locally)
    - Logging clarified when stage is successfully completed
    - uBCLD no longer supports official Hardware Enablement Stack (HWE) but now uses the underlying dependencies
        - Allows uBCLD to retain more freedom in choosing kernel versions
        - We strive not to be too far ahead or behind HWE
* `2022-05-13 09:59:38`:
    - Added `DNSSEC` to `systemd-resolved`
    - `DNSSEC` enabled
    - Added `UBCLD_HOST` to `BUILD.conf`
* `2022-05-12 16:12:19`: `systemd-detect-virt` checks if host is a virtual machine
* `2022-05-11 14:36:58`: WFT cert installed
* `2022-05-10 15:28:36`:
    - Added `/opt` check to abruptly end build when missing Chrome app
    - Better readability of build logs
    - Custom `$HOME` directory for WFT certificate
* `2022-05-10 08:57:20`:
    - Mounts moved to ISO Builder for stability
    - Made `add_user` more robust
    - Fix Getty substitution
* `2022-05-09 13:22:19`:
    - Reducing local repo functionality
    - Check built-in to fail build if memory system and kernel after `chroot` cannot be found
    - Tags incorporated into all scripts to make environment clear in build logging output
    - Clearance improved
* `2022-05-09 08:42:21`:
    - `BCLD_USER` is now the same as `BCLD_VENDOR`
    - Added local user for WFT cert
* `2022-05-04 16:57:02`: `NEXUS-deploy.sh` fixes
* `2022-05-04 12:12:24`:
    - Added error triggers on configurations, build immediately stops if 1 setting is missing
    - Added `echo_tools` to equalize console output across all environments
    - Log output readability improved
* `2022-05-03 15:26:13`:
    - Plymouth fix
    - Vendor logos added
    - Moved Initrd trigger backward: In-memory file system was created too early causing loss of configurations
* `2022-05-02 15:12:48`:
    - uBCLD now automatically logs to `bcld.log`
    - If the file does not exist, `BCLD-USB` is disconnected (makes no difference to the user)
    - When this happens, `usbmount` will look for `bcld.log` on newly connected USB drives
    - This is to prevent error messages from `usbmount`, because otherwise this program detects `BCLD-USB` as 'new disk'
* `2022-05-02 10:49:31`:
    - installed `pmount` for more stable umounts (logging)
    - added `usbmount` configs

### April
* `2022-04-26 12:31:48`:
    - Fixed APT DNS `UBUNTU_REPO` issue by choosing higher domain level
    - Added Plymouth 'facet theme'
* `2022-04-25 14:43:49`:
    - Increased app version to prevent premature spread
    - App version now readable in `bcld.log`
    - Artifact cleanup improved
    - Bigger changes to documentation and naming conventions
    - usbmount installed and configured
* `2022-04-21 16:06:53`:
    - `CLIENT_VERSION` refactored to `UBCLD_RELEASE` and `UBCLD_PATCH`
    - `CLIENT_TAG` refactored to `UBCLD_CODE_NAME`
    - Adjusted naming convention for better readability including code
* `2022-04-21 15:37:41`: New artifacts:
    1. `info` - File needed for metadata on the LiveUSB
    2. `bcld.cfg` - New configuration template with processed version number
* `2022-04-21 15:24:27`:
    - Updated `README.md`
    - Major improvement to readability of `ISO-builder.log`
    - Fixes to escaping in `DEBUG` and `TEST`
    - Added new firewall rules to fix DNS issue
    - Chrome app model is now selected based on BCLD_MODEL
    - Version number now visible in `bcld.cfg`
    - Started refactoring: using full path names for binaries
* `2022-04-21 08:27:23`: Added `NEXUS-deploy.sh` to even out deployment
* `2022-04-20 13:25:07`: Documentation updated with `Tools`
* `2022-04-20 13:14:16`:
    - added grub-efi support to EFI-IMG for ISO
    - added `facet logo`
    - Added 'IMG Exporter'
    - Added `BCLD_MODEL` to `BCLD_VERSION`
* `2022-04-14 16:09:16`: Build configuration documentation.
* `2022-04-14 15:38:07`: Bamboo `BCLD_MODEL` and `BCLD_VENDOR` integration
* `2022-04-13 14:42:59`: Image naming convention updated
* `2022-04-12 12:58:38`: Replace `./VERSION` with BUILD configuration
* `2022-04-06 16:09:59`: APP list removed
* `2022-04-06 15:19:38`: Package list generation moved to `ISO-builder.sh`, added `test` model and cleaned up `chroot.sh`
* `2022-04-05 15:41:05`: WOL override fix
* `2022-04-05 14:46:26`: iptables COMMIT fix
* `2022-04-04 15:19:34`: [OAC-252] uBCLD logging (Chrome app journal)

### March
* `2022-03-30 13:24:20`: Chrome app installation with DPKG replaced with APT-GET. Self-check built-in for SquashFS generation.
* `2022-03-29 16:31:27`: 
	- `autostart_switcher.sh` updated and changed to `param_switcher.sh`. 
	- `BCLD_MODEL` `BUILD.conf` parameter added. `BCLD_VENDOR` `BUILD.conf` parameter added. 
	- `BUILD` changed to `BUILD.conf` for clarification, added `BUILD` package list.
* `2022-03-25 10:39:41`: Added ISO Exporter.
* `2022-03-23 ​​16:10:38`: Added Autostart Switcher.
* `2022-03-22 18:35:25`: [OAC-254] uBCLD firewall
* `2022-03-16 17:37:08`: [OAC-252] uBCLD logging (X11, Plymouth)
* `2022-03-16 17:35:44`: [OAC-260] uBCLD Openbox flash
* `2022-03-14 13:57:13`: WOL override fix
* `2022-03-09 12:35:35`: New uBCLD naming convention: `RELEASE.PATCH-BUILD`
* `2022-03-09 11:54:41`: [OAC-255] uBCLD rendering issue
* `2022-03-04 15:41:20`: [OAC-252] uBCLD logging (static)
* `2022-03-04 10:23:23`: WoL param removed and enabled by default on first interface found

### February
* `2022-02-28 17:27:32`:
    - [OAC-199] uBCLD filesystem check (Casper)
    - [OAC-207] uBCLD validation (Casper)
    - [OAC-239] uBCLD Boot Errors (Apport, keyboard configuration, release/security updates)
* `2022-02-24 16:09:55`: [OAC-239] uBCLD Boot Errors (Remote Debugging)
* `2022-02-21 13:54:16`: uBCLD `./README.md` update.
* `2022-02-21 10:57:58`: [OAC-219] uBCLD Chrome App
* `2022-02-18 12:20:04`: [OAC-226] uBCLD debug port
* `2022-02-16 14:00:07`: [OAC-215] uBCLD Wake-on-LAN
