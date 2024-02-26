#!/bin/bash
# Script for ShellCheck automation

# Function to add to SHELL_REPORT
function append_report () {
    /usr/bin/echo -e "${1}" | /usr/bin/tee -a "${SHELL_REPORT}"
}

# Function to output description if too long
# 1: warn, error id
# 2: description
function output_desc () {

    if [[ $(/usr/bin/echo "${2}" | /usr/bin/wc -l) -eq 1 ]]; then
        append_report " - ${1}:${2}"
    else
        append_report " - ${1}:"
        append_report_silent '\n```'
        append_report " - ${2}"
        append_report_silent '```\n'
    fi
}

function append_report_silent () {
    /usr/bin/echo -e "${1}" >> "${SHELL_REPORT}"
}

if [[ -x /usr/bin/shellcheck ]] && [[ -f ./test/00_BCLD-BUILD.bats ]]; then
    SHELL_REPORT='./test/SHELL-REPORT.md'
    
    /usr/bin/echo -e '\n# Starting BCLD ShellCheck' | /usr/bin/tee "${SHELL_REPORT}"
    
    append_report_silent '\n```'
    
    # Make necessary directories
    /usr/bin/mkdir -p "$(/usr/bin/dirname ${SHELL_REPORT})"
    
    /usr/bin/find . -type f \
        -name "*.sh" \
        -not \( -path './chroot' -o -path './modules' \) \
        -exec shellcheck -S warning {} \; >> "${SHELL_REPORT}"
        
    append_report_silent '```\n'

    # Warnings
    SHELL_WARN="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c '(warning)')"

    append_report "\n# ShellCheck Warnings: ${SHELL_WARN}"

    ## If ShellCheck finds warnings...    
    if [[ ${SHELL_WARN} -gt 0 ]]; then
        append_report '\n## Common warnings found:\n'
        
        COMMON_WARNINGS="$(/usr/bin/cat ${SHELL_REPORT} | /usr/bin/grep '(warning)' | /usr/bin/awk '{ print $2 }' | /usr/bin/sort -u)"
        
        for warn in ${COMMON_WARNINGS}; do
            
            description="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep "${warn}" | /usr/bin/grep -v 'https' | /usr/bin/cut -d ':' -f2 | /usr/bin/sort -u)"
            
            output_desc "${warn}" "${description}"
        done 
    fi
    
    # ERRORS
    SHELL_ERROR="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c '(error)')"
    
    append_report "\n# ShellCheck ERRORS: ${SHELL_ERROR}"
    
    ## If ShellCheck finds errors...    
    if [[ ${SHELL_ERROR} -gt 0 ]]; then
        append_report '\n## Common ERRORS found!:\n'
        
        COMMON_ERRORS=$(/usr/bin/cat ${SHELL_REPORT} | /usr/bin/grep '(error)' | /usr/bin/awk '{ print $2 }' | /usr/bin/sort -u)
        
        for error in ${COMMON_ERRORS}; do
            
            description="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep "${error}" | /usr/bin/grep -v 'https' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
            
            output_desc "${error}" "${description}"
        done

        exit 1    
    fi

    append_report "# ShellCheck report: ${SHELL_REPORT}"

else
    /usr/bin/echo 'ShellCheck could not be found!'
    exit 1
fi
