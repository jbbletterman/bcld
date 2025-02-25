# Introduction

|||
|---|---|
| This is BCLD (Bootable Client Lockdown).<br/>This project is a follow-up to the Fedora BCLD project.<br/>BCLD was initiated in hopes of advancing hardware support and being able to operate in accordance with Secure Boot.<br/>Below are extensive instructions to the product. | <img title="" src="./assets/bcld-logo.png" alt="logo" width="300" data-align="left"> |

**BCLD Version**: 13.13-2 BCLD (Nemesis)
**BCLD Kernel**: 6.11.0-17-generic

# Index

1. [Repository](#repository)

2. [BCLD Models](#bcld-models)

3. [ISO-builder](#iso-builder)

4. [IMG-builder](#img-builder)

5. [Docker-builder](#docker-builder)

6. [Initialization](#initialization)

7. [Configuration Files](#configuration-files)

8. [Package Lists](#package-lists)

9. [Bootstrap](#bootstrap)

10. [Chroot](#chroot)

11. [Chrome Apps](#chrome-apps)

12. [Image](#image)

13. [Scripts](#scripts)

14. [Versioning](#versioning)

15. [Artifacts](#artifacts)

16. [Logging](#logging)

17. [Debugging](#debugging)

18. [Testing](#testing)

19. [Firewall](#firewall)

20. [Tools](#tools)

21. [Security](#security)

22. [License](#license)

23. [Changelog](#changelog)

# Repository

This repository consists of the following objects:

1. `artifacts` - This folder is created during the build and contains usable artifacts.
2. `chroot` - This folder is created during the build and contains the BCLD file system.
3. `config` - This folder contains all configurable aspects of BCLD.
4. `deb` - This folder can be created for vendor packages for BCLD (Facet, WFT, Default).
5. `image` - This folder is used for building the BCLD images (ISO, IMG).
6. `log` - This folder is created during the build and contains important logs.
7. `opt` - Everything in this folder will be copied to the BCLD file system.
8. `script` - This folder contains important scripts for BCLD.
9. `tools` - This folder contains associated tools, such as `RepoMan`.
10. `.gitignore` - This file contains a list of files and artifacts that must be excluded from the repository.
11. [BCLD_FLOW.png](./assets/BCLD_FLOW.png) - Overview of the build process.
12. [CHANGELOG](./CHANGELOG.md) - Changelog.
13. [IMG-builder.sh](./IMG-builder.sh) - This script is responsible for the generation of the IMG-file during the build process and can be used on its own (as long as there is a `./artifacts/bcld.iso`).
14. [ISO-builder.sh](./ISO-builder.sh) - This script is responsible for the build process.
15. [RepoMan.sh](./RepoMan.sh) - `RepoMan` is the repository management tool for BCLD.

## Git Ignore List

* The [.gitignore](./.gitignore) file consists mainly of artifacts and subfiles that are created during the build process.
* These files do not need to be kept.
* This includes the entire `./chroot` folder.

## Git Modules

* BCLD inherits the following modules:
  1. `bats-core`
  2. `bats-support`
  3. `bats-assert`

# BCLD Models

| **BCLD_MODEL** | **Explanation**                                                                                                                                                                                            |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Release**    | The BCLD Release images are provided with a kiosk mode that cannot be escaped.                                                                                                                             |
| **Debug**      | Debug images have an exposed port for PixelHunter (Chromium Debugging). Kiosk mode is disabled.                                                                                                            |
| **Test**       | Test images are not distributed and are intended for internal usage only. Additional firewall rules have been added to enable SSH and X11 forwarding for log offloading. The app won't boot automatically. |

# ISO-builder

* This repo can be used on an Ubuntu build agent (VM).
* Preferably a machine with the same release (`22.04`,`jammy`).
* Use [ISO-builder.sh](./ISO-builder.sh) to build an image.
* This requires the tools from `./config/packages/BUILD`.
* Installing tools: `apt-get install -y $(cat config/packages/BUILD)`.

# IMG-builder

* The bcld.iso file can be packed into a filesystem BCLD-IMG.
* To do this, start [IMG-builder.sh](./IMG-builder.sh).
* The BCLD-IMG file will be generated and a Secure Boot signed Grub2 will be installed.

# Docker-builder

* It is also possible to run both [ISO-builder.sh](./ISO-builder.sh) and [IMG-builder.sh](./IMG-builder.sh) inside Docker.
* For this script to work, Docker must be installed.
* This script will automatically attempt to install Docker after prompting the user.

# Initialization

* The BCLD build process starts by checking for mounts.
* These mounts are then detached to prevent further errors.
* Many devices are mounted during the build process, for network configuration, image assembly, IMG file partitioning and formatting, etc.
* If the build process crashes, mounts can sometimes hang and cause errors.
* That's why BCLD cleans it up at the beginning of the process, instead of at the end (as it used to be with Fedora).
* During the first build, non-existent folders will be automatically generated, such as `artifacts`, `chroot` and `log`.
* If the above directories already exist, they will be emptied for a clean build.

| DIR         | Description                                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| _artifacts_ | This folder contains post-build artifacts, such as generated package reports, archives, and image files.                             |
| _chroot_    | This directory contains the output of `debootstrap` or `Ubuntu Base`. It then installs packages from the lists in `config/packages`. |
| _log_       | Log output is written to this directory during a build.                                                                              |

# Configuration Files

* These files are freely editable and will be transferred to the new system during the build.
* BCLD can be completely configured using the following file and directories:
  1. `apt`: Configurations for the download mirrors and repositories.
  2. `bash`: Configurations for the build environment.
  3. `casper`: Configurations for the Casper live boot system.
  4. `grub`: Configurations for starting the boot loader.
  5. `iptables`: Configure the firewall settings.
  6. `modprobe`: Configurations for kernel modules (drivers).
  7. `network-manager`: Network configurations.
  8. `nssdb`: Configure the NSS database.
  9. `openbox`: Configurations for auto-launching the Chrome App.
  10. `packages`: Lists of packages required for BCLD.
  11. `plymouth`: Configurations for the splash screen.
  12. `systemd`: Configurations for automatic services.
  13. `udev`: Configure device rules.
  14. `usbmount`: Configure USB-mounting.
  15. `X11`: Configurations for the X screen management system.
  16. [BUILD.conf](./config/BUILD.conf): This file contains important build variables for customization, such as which kernel version to use.

# Package Lists

## `./config/packages`

* BCLD contains a number of package lists:
  1. [DEBUG](./config/packages/DEBUG): Contains additional debug packages.
  2. [KERNEL](./config/packages/KERNEL): Contains the necessary kernel packages.
  3. [REMOVE](./config/packages/REMOVE): Contains packages that will be excluded.
  4. [REQUIRED](./config/packages/REQUIRED): Contains all necessary packages.
  5. [TEST](./config/packages/TEST): Contains extra packages for tests.
  6. [VIRTUAL](./config/packages/VIRTUAL): Contains virtual packages for RepoMan.

# Bootstrap

* BCLD uses `debootstrap` to generate a clean environment:
  - Debootstrap handles a completely fresh Debian-like file system.
  - BCLD is built on top of said file system.
* The setting can be found under [BUILD.conf](./config/BUILD.conf).

# Chroot

## `./chroot` & `./script/chroot.sh`

* After the bootstrap is complete, the [ISO-builder.sh](./ISO-builder.sh) script performs chroot operations within the file system.
* The new environment can then be found within `./chroot`.
* The script that will be executed within this environment can be found in [chroot.sh](./script/chroot.sh).
* You can install various packages through chroot to shape BCLD.
* When chrooted into the new file system, there will be package lists ready in the home directory.
* These will be cleaned up afterwards.
* Within this new environment, all packages are merged, excluding the [REMOVE](./config/packages/REMOVE) packages.
* Then these packages are installed, this is a long process.
* All steps are written to `log/chroot.log`.
* Package installations are written to `log/APT.log`.

# BCLD Apps

## `./app`

* The BCLD repository can detect a special directory: `./app`:

* All files in `./app/RELEASE` are installed in the process.

* `./app/DEBUG` is only used for debug builds.
  
  ## `./opt`

* All files in `./opt` are simply copied to the `/opt` directory within BCLD.

# Image

## `./image`

* This folder contains a conversion of `./chroot` into usable LiveCD files.
* The `./chroot` file system is used to build a LiveCD.
* This is especially done with the following files:
  1. `./image/ISO/casper/`
     - `filesystem.squashfs`: This file is a compressed file system and will be used within the ISO file. `./chroot/boot` is excluded here, because the kernel and RAMFS are loaded via Casper (`./image/ISO/casper`).
     - `initrd`: This is a 'normal' initrd, a small file containing a recording of the RAM file system.
     - `vmlinuz`: This is ultimately the kernel used within BCLD.
  2. `./image/ISO/EFI/BOOT/efi.img`: This is the EFI boot IMG file and contains the boot loader that makes the ISO bootable.
  3. `./image/ISO/.disk`: This folder contains some meta information about the ISO.
  4. [bcld.cfg](./config/bcld/bcld.cfg): A BCLD configuration file will be generated during the build process.

# Scripts

## `./script`

This folder contains important scripts for building a BCLD image.

1. [autocert.sh](./script/autocert.sh) automatically selects the right certificate for the `BCLD_VENDOR`.
2. [bcld_app.sh](./script/bcld_app.sh) uses `Xconfigure.sh` and `Xlogger.sh` to simplify Autostart with Openbox.
3. [bcld_test.sh](./script/bcld_test.sh) are BCLD TEST tools.
4. [chroot.sh](./script/chroot.sh) is only executed within BCLD's new `chroot` environment and mainly consists of installing packages and making configurations.
5. [client_logger.sh](./script/client_logger.sh) uses `log_tools.sh` to log the BCLD client.
6. [crosdump_logger.sh](./script/crosdump_logger.sh) attempts to output Chromium dump files to the journal.
7. [docker_tools.sh](./script/docker_tools.sh) is for local building with Docker.
8. [echo_tools.sh](./script/echo_tools.sh) is responsible for console output.
9. [file_operations.sh](./script/file_operations.sh) takes care of file management and permissions.
10. [log_tools.sh](./script/log_tools.sh) is a script with useful logging functions that can be included in multiple scripts.
11. [param_switcher.sh](./script/param_switcher.sh) is included in `test` builds and is a script for turning `BCLD_AUTOSTART` on and off when debugging boot problems.
12. [rsyslogger.sh](./script/rsyslogger.sh) takes care of remote logging.
13. [startup.sh](./script/startup.sh) is run every time BCLD starts and includes setting up BCLD before each use. This processes boot parameters.
14. [usb_logger.sh](./script/usb_logger.sh) uses `log_tools.sh` to write the journal to `BCLD-USB`.
15. [Xconfigure.sh](./script/Xconfigure.sh) is used by Openbox, before launching the Chrome app, to configure the X screen management system.
16. [Xlogger.sh](./script/Xlogger.sh)  uses log_tools.sh to log activities on the X server.

### USB Logger

* The BCLD USB Logger uses a service that starts a process which then checks for 'BCLD-USB'.
* If `bcld.log` is found on `BCLD-USB`, logging will be written to it.
* This only works on a USB stick with a `BCLD-USB` label, if it also has `bcld.log` on it.
* It also only works once, so `BCLD-USB` may not be disconnected if logging has started.

# Versioning

* As with Fedora BCLD, the version number is kept in a file called `./VERSION`.
* This can be configured in [BUILD.conf](./config/BUILD.conf).
* So use helpful, concise descriptions like: `14-dec-2022_BCLD-Omniscius-3_FACET-TEST.img`
* 
* The `VERSION` file contains a concatenated string: `12.10-3 BCLD Test (Omniscius)`.

# Artifacts

A BCLD build produces the following artifacts:

1. `./artifacts/${BCLD-VERSION}.img`: The ISO file is packed into an IMG file so that users can get a writable partition for `bcld.cfg`.
2. `./artifacts/bcld.cfg`: Template with `VERSION`.
3. `./artifacts/bcld.iso`: The ISO file, usable on hypervisors. BCLD hereby has a bare configuration that is overwritten by the IMG file.
4. `./artifacts/info`: Description of the ISO file.
5. `./artifacts/BATS-REPORT`: The results of the Bash Automated Tests.
6. `./artifacts/BATS-SUCCESS`: Placeholder to tell CI/CD that BATS was successful.
7. `./artifacts/BCLD_REPO.tar.gz`: The BCLD repository (archive) that RepoMan generates.
8. `./artifacts/PKGS.md`: The list of packages that RepoMan inspects.
9. `./artifacts/PKGS_ALL`: List of all packages selected for installation.

# Logging

* Logging in BCLD works similarly to previous releases: by writing the IMG file to a USB, and creating a file called `bcld.log` in the root of the disk.
* BCLD will only write logging to this file if it exists.
  - The idea is that logging is the only reason not to unplug the USB.
  - Normally BCLD works entirely in memory.
  - By performing this check, BCLD knows that another USB disk is connected for transporting the log files.

## Tags

The BCLD log file is generated from the journal and provides the following tags:

| TAG               | Description                                              |
| ----------------- | -------------------------------------------------------- |
|                   |                                                          |
| `BUILD` **TAGs**  | _These TAGs contain information about the build process_ |
|                   |                                                          |
|                   | **ISO Builder**                                          |
| **ISO-INIT**      | Initialization                                           |
| **ISO-PRECLEAN**  | Cleanup                                                  |
| **ISO-PREP**      | Preparations                                             |
| **ISO-BOOTSTRAP** | Ubuntu file system initialization                        |
| **ISO-PRECONF**   | Preconfigurations                                        |
| **ISO-CROS**      | Installing the Chrome app                                |
| **ISO-MOUNT**     | Handling mounts                                          |
| **ISO-CHROOT**    | Handling installations within the client                 |
| **ISO-POSTCONF**  | Post-install configurations                              |
| **ISO-INITRAMFS** | Generating the initial memory system                     |
| **ISO-REPO**      | Generation of the dummy repo                             |
| **ISO-SQUASHFS**  | Generation of the compressed file system                 |
| **ISO-GRUB**      | Installing the file system boot loader                   |
| **ISO-GEN**       | Generation of the BCLD-ISO                               |
|                   |                                                          |
|                   | **IMG Builder**                                          |
| **IMAGE-INIT**    | Generation of the BCLD-IMG                               |
| **IMAGE-GRUB**    | Installing the bootloader on the image                   |
| **IMAGE-BUILD**   | Copy BCLD files to the image                             |
|                   |                                                          |
|                   | **BCLD Tools**                                           |
| **BUILD-PXE**     | Upload artifacts to PXE                                  |
| **BUILD-NEXUS**   | Upload artifacts to Nexus                                |
|                   |                                                          |
| `CLIENT` **TAGs** | _These TAGs contain information about BCLD_              |
|                   |                                                          |
| **RUN-CHROOT**    | Chroot Installation                                      |
| **RUN-CLIENT**    | Operating System Information                             |
| **RUN-LIVE**      | Contains live configuration information                  |
| **RUN APP**       | Chrome app execution                                     |
| **RUN-GRAPHICS**  | Information about the graphics settings                  |

## Components

| Part                 | Description                                                                        |
| -------------------- | ---------------------------------------------------------------------------------- |
| Alternatives         | Configured Standard Programs                                                       |
| Casper boot system   | Casper logs                                                                        |
| Client information   | BCLD version, boot parameters, machine identification                              |
| Sound settings       | PulseAudio and ALSA information                                                    |
| Hardware             | Processor information, architecture, memory usage, connected USB and PCI devices   |
| Journal              | Kernel logs                                                                        |
| Kernel information   | Uname information about kernel (modules) and architecture                          |
| Network connections  | Information about open connections, addresses, routes and available Wi-Fi networks |
| Plymouth             | Information about the splash screen                                                |
| Processes and Memory | Ordered by CPU and Memory Usage                                                    |

## Rsyslog

* BCLD only supports encrypted Rsyslogging on port 6514/tcp.
* Here is an example for Rsyslog server settings:

```
# The logging is best placed in a separate folder for BCLD
# Because the hostname alone is often not enough (facet, wft), an IP address is also used here
# It is possible to use Rsyslog Message Properties
# In the example, however, everything is sent to one file (bcld.log).

template (
    name="RemoteLogs"
    type="string"
    string="/var/log/BCLD/%FROMHOST%/%FROMHOST-IP%/bcld.log"
)

# Declare global directives before loading the TCP module
global(
    DefaultNetstreamDriver="gtls"
    DefaultNetstreamDriverCAFile="/etc/ssl/certs/ca.crt"
    DefaultNetstreamDriverCertFile="/etc/ssl/certs/fao.crt"
    DefaultNetstreamDriverKeyFile="/etc/ssl/certs/fao.key"
)

# Only load the TCP listener and force TLS mode
module(
    load="imtcp"
    StreamDriver.Name="gtls"
    StreamDriver.Mode="1"
    StreamDriver.Authmode="x509/certvalid"
)

# Use port 6514 for the listener
input(
    type="imtcp"
    port="6514"
)


# Log all facilities and levels with the template
*.* -?RemoteLogs

# Stop the process after writing
stop
```

# Debugging

* BCLD has a `DEBUG` edition.
* This mode is enabled with the [`BCLD_MODEL`](#build-configurations) build configuration.
* This configuration changes the condition of BCLD and installs the extra packages from [DEBUG](./config/packages/DEBUG).
* This edition has additional [debug firewall rules](./config/iptables/iptables.firewall.rules.debug) for Chrome debugging.
* In BCLD `DEBUG` you can access the Chrome developer tools via the right mouse button or the `F12` key.

# Testing

* BCLD also has a `TEST` edition.
* It is configured the same way as `DEBUG`, by overriding `BCLD_MODEL`.
* This image will install not only the extra packages from [DEBUG](./config/packages/DEBUG), but also from [TEST](./config/packages/TEST).
* This image has even less secure [test firewall rules](./config/iptables/iptables.firewall.rules.test).
* This image allows not only SSH and HTTP, but even has a rule to allow the results of an [OpenSCAP scan](./test/bcld_test.sh#L276) to be hosted locally.
* Most of the testing done to BCLD is to secure a kiosk environment that users cannot escape.
* Other tests involve testing features, bug fixes and hardware support.

## Bash Automated Testing System

* BCLD uses BASH Automated Testing System (BATS) to unit test the build process during major and large scale builds.
* For the integration of the BATS modules, the repository must be cloned with the `--recursive` flag.
* This can always be done after, with `git submodule update --init` (within the repo).
* During every test, an image is built in the background.
* The tests monitor whether the build process runs successfully.
* Many small tests and checks are carried out during the building process, which immediately interrupt the building process if something goes wrong.
* Sometimes, services are not available or packages do not arrive.
* BATS tests the following :
  - expected output of the build,
  - expected artifacts,
  - availability of network (services),
  - integrity of important files,
  - correct execution of important build stages.

| #   | Test         | Explanation                                                                                 |
|:---:|:------------:| ------------------------------------------------------------------------------------------- |
|     |              |                                                                                             |
| 1   | LicenseCheck | Checks for license text in all scripts and text files.                                      |
| 2   | ShellCheck   | Checks for any errors in Bash syntax.                                                       |
| 3   | TagCheck     | Checks all TAGs for completion after a build.                                               |
| 4   | Grub Monitor | Checks the integrity of all Grub files and the result of the installation during the build. |
| 5   | ArtChecker   | Checks whether all artifacts have been created post-build.                                  |
| 6   | ISOcheck     | Check if the size of the ISO artifact seems correct.                                        |
| 7   | IMGcheck     | Check if the size of the IMG artifact seems correct.                                        |

# Firewall

* BCLD uses `iptables` as firewall.
* In [RELEASE](./config/iptables/iptables.firewall.rules), the following services are allowed:
  - DNS
  - HTTPS
  - Multicast
* In [DEBUG](./config/iptables/iptables.firewall.rules.debug), additional services are allowed:
  - PixelHunter™️
* In [TEST](./config/iptables/iptables.firewall.rules.test), even more services are allowed:
  - HTTP
  - SSH
  - X11 Forwarding

# Tools

## EXPORTER-TOOLKIT.sh

* Script for directly mounting BCLD images and unpacking them.
* Methods available to prepare BCLD for iPXE environments.
* Can unpack images, ISO files and squashfs.
* Can test iPXE by downloading images from a URL.

## NEXUS-DEPLOY.sh

* Script for uploading the artifacts to the Nexus repository

## HashGen.sh

* [HashGen](./tools/HashGen.sh) is the BCLD Hash Generator.
* This script must be run from the root directory to create a hash file: [bcld.md5](./test/bcld.md5).
* This file contains a hash of all important files and is checked in Bamboo before each build.
* The [md5sum](./test/md5sum) file again contains a hash, but of the original hash file (the total).
* Without running `HashGen` BATS will **always** fail.

## RepoMan

* [RepoMan.sh](./RepoMan.sh) is the BCLD Repository Manager.
* This tool can be used to generate a local repository for BCLD.
* All dependencies are considered, including virtual packages.
* RepoMan can also list packages with descriptions for the transparency of BCLD.
* `RepoMan` can be used in the terminal with `./RepoMan [command] [repo name] [force]`, for example `./RepoMan c`.

| Command | Explanation                 |
|:-------:| --------------------------- |
| c       | CREATE a new repo           |
| u       | UPDATE an existing repo     |
| d       | DEPLOY a repo               |
| z       | ZIP a repo                  |
| g       | sign a repo with GPG        |
| s       | SEARCH for virtual packages |
| o       | OUTPUT package lists        |
| x       | clear the Repo Manager      |
| w       | clear the WEB directory     |
| q       | QUIT                        |

# Security

* There is a BCLD [Security Policy](./SECURITY.md) available

# <img src="https://europa.eu/webtools/images/flag.svg?t=1695039139" width="40" /> License

* Bootable Client Lockdown (BCLD) is licensed under the terms of the EUPL license.
* See the [LICENSE](./LICENSE.eupl) file for license rights and limitations (EUPL).
* See the [COPYING](./COPYING) file for a local copy of EUPL.

# Changelog

* The [CHANGELOG](./CHANGELOG.md) file contains a short description of all major changes to BCLD.
