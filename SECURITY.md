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

## Reporting a Bug or Vulnerability
We try to track as many bugs and vulnerabilities as we can,
but there is no certainty that we will catch everything.
So if any of you find anything smelly in our code,
be sure to post an issue, a ticket or contact the developers!

### Disclosure Policy
The BCLD research team is dedicated to working closely with the open source community and with projects that are affected by a vulnerability, in order to protect users and ensure a coordinated disclosure. When we identify a vulnerability in a project, we will report it by contacting the publicly-listed security contact for the project if one exists; otherwise we will attempt to contact the project maintainers directly.

If the project team responds and agrees the issue poses a security risk, we will work with the project security team or maintainers to communicate the vulnerability in detail, and agree on the process for public disclosure. Responsibility for developing and releasing a patch lies firmly with the project team, though we aim to facilitate this by providing detailed information about the vulnerability.

> Our disclosure deadline for publicly disclosing a vulnerability is: **90 days** after the first report to the project team.

We **appreciate the hard work** maintainers put into fixing vulnerabilities and understand that sometimes more time is required to properly address an issue. We want project maintainers to succeed and because of that we are always open to discuss our disclosure policy to fit your specific requirements, when warranted.

### Report Template
If you are unsure on how to file a report, it may be useful to try the [GitHub Report Template](https://github.com/github/securitylab/blob/main/docs/report-template.md#vulnerability-report). Basically, it comes down to creating the following structure in your report:
  1. Summary of the problem,
  2. Tested product and version number,
  3. Details on any detected vulnerabilities,
  4. Steps to reproduce the problem,
  5. Impact of the problem,
  6. Suggested solution, if available,
  7. Create a private [GitHub Security Advisor](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/creating-a-repository-security-advisory),
  8. Credited developers.

### Bugs, Issues, Incidents, Problems
When reporting a bug through [GitHub Issues](https://github.com/jbbletterman/bcld/issues), you can use the report template above. Aside from this, there are a few other things to think about:
  * Always check known issues on the BCLD Wiki first.
  * Make sure you are using the latest release.
  * Also state which components are actually working.
  * Try to categorize the issue in at least one tag (like `kernel`, `graphics` or `network`).
  
The better you describe the issue, the quicker we will find it!

### Vulnerabilities
Reporting a vulnerability can be done through the button at the top of this page. For more information, see the [GitHub Docs](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability#privately-reporting-a-security-vulnerability). Only the title and description are mandatory, but as much information as possible is recommended.
