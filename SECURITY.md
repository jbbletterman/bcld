# Security Policy
BCLD is built on a snapshot of the official [Ubuntu package repositories](https://packages.ubuntu.com/).
Packages are automatically updated with each build.
Packages do NOT update automatically once the image has been built.
The reason for this is to save bandwith during runtime, and not overload client networks.

## Updating BCLD manually
To use BCLD with fully updated packages, build a fresh image from source.
Follow the instructions in the [README](./README.md#bcld-models) file.
Older images will generally contain outdated packages, which may have become exposed to vulnerabilities over time.
> **Always try to use the latest release.**

## Vulnerability Scanning
A BCLD TEST image can be built from source, using [BCLD_MODEL=test](./README.md#build-configuration).
BCLD TEST images contain the [BCLD TEST package](./test/bcld_test.sh).
This package contains a method called `BCLD_OVAL`, which performs an OpenSCAP OVAL vulnerability test on a live BCLD TEST image.
This test can be used to host an OpenSCAP report over HTTP using BCLD TEST.
The test will display common vulnerabilities on the Ubuntu platform that BCLD is based on.
OpenSCAP will detect vulnerabilities for Ubuntu systems using OVAL content.
Aside from common vulnerabilities on Ubuntu systems, ShellCheck is used in conjunction with [RepoMan](./RepoMan.sh), our BCLD repository management tool.

## Reporting a Vulnerability
We try to track as many bugs, glitches and vulnerabilities as we can,
but there is no certainty that we will catch everything.
So if any of you find anything smelly in our code,
be sure to post an issue, a ticket or contact the developers!
> **We thank you for your cooperation!**
