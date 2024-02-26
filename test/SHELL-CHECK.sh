#!/bin/bash
# Script for ShellCheck automation

if [[ -x /usr/bin/shellcheck ]] && [[ -f ./test/00_BCLD-BUILD.bats ]]; then
    SHELL_REPORT='./test/SHELL-REPORT.txt'
    
    /usr/bin/echo 'Starting BCLD ShellCheck'
    
    # Make necessary directories
    /usr/bin/mkdir -p "$(/usr/bin/dirname ${SHELL_REPORT})"
    
    /usr/bin/find . -type f \
        -name "*.sh" \
        -not \( -path './chroot' -o -path './modules' \) \
        -exec shellcheck -S warning {} \; > "${SHELL_REPORT}"
    
    SHELL_ERROR="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c 'error')"
    SHELL_WARN="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c 'warning')"
    
    /usr/bin/echo -e '\n' >> "${SHELL_REPORT}"
    /usr/bin/echo -e "# ShellCheck Errors: ${SHELL_ERROR}\n" | /usr/bin/tee -a "${SHELL_REPORT}"
    /usr/bin/echo -e "# ShellCheck Warnings: ${SHELL_WARN}\n" | /usr/bin/tee -a "${SHELL_REPORT}"
    /usr/bin/echo "# ShellCheck report: ${SHELL_REPORT}" | /usr/bin/tee -a "${SHELL_REPORT}"
    
    if [[ ${SHELL_ERROR} -gt 0 ]]; then
        /usr/bin/echo -e '\n# ShellCheck found errors!' | /usr/bin/tee -a "${SHELL_REPORT}"
        exit 1    
    fi
    
else
    /usr/bin/echo 'ShellCheck could not be found!'
    exit 1
fi
