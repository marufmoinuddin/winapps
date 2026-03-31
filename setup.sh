#!/usr/bin/env bash

# shellcheck disable=SC2034           # Silence warnings regarding unused variables globally.

### GLOBAL CONSTANTS ###
# ANSI ESCAPE SEQUENCES
readonly BOLD_TEXT="\033[1m"          # Bold
readonly CLEAR_TEXT="\033[0m"         # Clear
readonly COMMAND_TEXT="\033[0;37m"    # Grey
readonly DONE_TEXT="\033[0;32m"       # Green
readonly ERROR_TEXT="\033[1;31m"      # Bold + Red
readonly EXIT_TEXT="\033[1;41;37m"    # Bold + White + Red Background
readonly FAIL_TEXT="\033[0;91m"       # Bright Red
readonly INFO_TEXT="\033[0;33m"       # Orange/Yellow
readonly SUCCESS_TEXT="\033[1;42;37m" # Bold + White + Green Background
readonly WARNING_TEXT="\033[1;33m"    # Bold + Orange/Yellow

# ERROR CODES
readonly EC_FAILED_CD="1"        # Failed to change directory to location of script.
readonly EC_BAD_ARGUMENT="2"     # Unsupported argument passed to script.
readonly EC_EXISTING_INSTALL="3" # Existing conflicting WinApps installation.
readonly EC_NO_CONFIG="4"        # Absence of a valid WinApps configuration file.
readonly EC_MISSING_DEPS="5"     # Missing dependencies.
readonly EC_NO_SUDO="6"          # Insufficient privileges to invoke superuser access.
readonly EC_NOT_IN_GROUP="7"     # Current user not in group 'libvirt' and/or 'kvm'.
readonly EC_VM_OFF="8"           # Windows 'libvirt' VM powered off.
readonly EC_VM_PAUSED="9"        # Windows 'libvirt' VM paused.
readonly EC_VM_ABSENT="10"       # Windows 'libvirt' VM does not exist.
readonly EC_CONTAINER_OFF="11"   # Windows Docker container is not running.
readonly EC_NO_IP="12"           # Windows does not have an IP address.
readonly EC_BAD_PORT="13"        # Windows is unreachable via RDP_PORT.
readonly EC_RDP_FAIL="14"        # FreeRDP failed to establish a connection with Windows.
readonly EC_APPQUERY_FAIL="15"   # Failed to query Windows for installed applications.
readonly EC_INVALID_FLAVOR="16"  # Backend specified is not 'libvirt', 'docker' or 'podman'.

# PATHS
# 'BIN'
readonly SYS_BIN_PATH="/usr/local/bin"                  # UNIX path to 'bin' directory for a '--system' WinApps installation.
readonly USER_BIN_PATH="${HOME}/.local/bin"             # UNIX path to 'bin' directory for a '--user' WinApps installation.
readonly USER_BIN_PATH_WIN='\\tsclient\home\.local\bin' # WINDOWS path to 'bin' directory for a '--user' WinApps installation.
# 'SOURCE'
readonly SYS_SOURCE_PATH="${SYS_BIN_PATH}/winapps-src" # UNIX path to WinApps source directory for a '--system' WinApps installation.
readonly USER_SOURCE_PATH="${USER_BIN_PATH}/winapps-src" # UNIX path to WinApps source directory for a '--user' WinApps installation.
# 'APP'
readonly SYS_APP_PATH="/usr/share/applications"                        # UNIX path to 'applications' directory for a '--system' WinApps installation.
readonly USER_APP_PATH="${HOME}/.local/share/applications"             # UNIX path to 'applications' directory for a '--user' WinApps installation.
readonly USER_APP_PATH_WIN='\\tsclient\home\.local\share\applications' # WINDOWS path to 'applications' directory for a '--user' WinApps installation.
# 'APPDATA'
readonly SYS_APPDATA_PATH="/usr/local/share/winapps"                  # UNIX path to 'application data' directory for a '--system' WinApps installation.
readonly USER_APPDATA_PATH="${HOME}/.local/share/winapps"             # UNIX path to 'application data' directory for a '--user' WinApps installation.
readonly USER_APPDATA_PATH_WIN='\\tsclient\home\.local\share\winapps' # WINDOWS path to 'application data' directory for a '--user' WinApps installation.
# 'Installed Batch Script'
readonly BATCH_SCRIPT_PATH="${USER_APPDATA_PATH}/installed.bat"          # UNIX path to a batch script used to search Windows for applications.
readonly BATCH_SCRIPT_PATH_WIN="${USER_APPDATA_PATH_WIN}\\installed.bat" # WINDOWS path to a batch script used to search Windows for applications.
# 'Installed File'
readonly TMP_INST_FILE_PATH="${USER_APPDATA_PATH}/installed.tmp"          # UNIX path to a temporary file containing the names of detected officially supported applications.
readonly TMP_INST_FILE_PATH_WIN="${USER_APPDATA_PATH_WIN}\\installed.tmp" # WINDOWS path to a temporary file containing the names of detected officially supported applications.
readonly INST_FILE_PATH="${USER_APPDATA_PATH}/installed"                  # UNIX path to a file containing the names of detected officially supported applications.
readonly INST_FILE_PATH_WIN="${USER_APPDATA_PATH_WIN}\\installed"         # WINDOWS path to a file containing the names of detected officially supported applications.
# 'PowerShell Script'
readonly PS_SCRIPT_PATH="./install/ExtractPrograms.ps1"                          # UNIX path to a PowerShell script used to store the names, executable paths and icons (base64) of detected applications.
readonly PS_SCRIPT_HOME_PATH="${USER_APPDATA_PATH}/ExtractPrograms.ps1"          # UNIX path to a copy of the PowerShell script within the user's home directory to enable access by Windows.
readonly PS_SCRIPT_HOME_PATH_WIN="${USER_APPDATA_PATH_WIN}\\ExtractPrograms.ps1" # WINDOWS path to a copy of the PowerShell script within the user's home directory to enable access by Windows.
# 'Detected File'
readonly DETECTED_FILE_PATH="${USER_APPDATA_PATH}/detected"          # UNIX path to a file containing the output generated by the PowerShell script, formatted to define bash arrays.
readonly DETECTED_FILE_PATH_WIN="${USER_APPDATA_PATH_WIN}\\detected" # WINDOWS path to a file containing the output generated by the PowerShell script, formatted to define bash arrays.
# 'FreeRDP Connection Test File'
readonly TEST_PATH="${USER_APPDATA_PATH}/FreeRDP_Connection_Test"          # UNIX path to temporary file whose existence is used to confirm a successful RDP connection was established.
readonly TEST_PATH_WIN="${USER_APPDATA_PATH_WIN}\\FreeRDP_Connection_Test" # WINDOWS path to temporary file whose existence is used to confirm a successful RDP connection was established.
# 'WinApps Configuration File'
readonly CONFIG_PATH="${HOME}/.config/winapps/winapps.conf" # UNIX path to the WinApps configuration file.
# 'Inquirer Bash Script'
readonly INQUIRER_PATH="./install/inquirer.sh" # UNIX path to the 'inquirer' script, which is used to produce selection menus.

# REMOTE DESKTOP CONFIGURATION
readonly RDP_PORT=3389         # Port used for RDP on Windows.
readonly DOCKER_IP="127.0.0.1" # Localhost.

### GLOBAL VARIABLES ###
# USER INPUT
OPT_SYSTEM=0    # Set to '1' if the user specifies '--system'.
OPT_USER=0      # Set to '1' if the user specifies '--user'.
OPT_UNINSTALL=0 # Set to '1' if the user specifies '--uninstall'.
OPT_AOSA=0      # Set to '1' if the user specifies '--setupAllOfficiallySupportedApps'.
OPT_ADD_APPS=0  # Set to '1' if the user specifies '--add-apps'.
OPT_DIAG=0      # Set to '1' if the user specifies '--diagnose-rdp-drive'.
OPT_START_RDP=0 # Set to '1' if the user specifies '--start-rdp-session'.

# WINAPPS CONFIGURATION FILE
RDP_USER=""          # Imported variable.
RDP_PASS=""          # Imported variable.
RDP_DOMAIN=""        # Imported variable.
RDP_IP=""            # Imported variable.
VM_NAME="RDPWindows" # Name of the Windows VM (FOR 'libvirt' ONLY).
WAFLAVOR="docker"    # Imported variable.
RDP_SCALE=100        # Imported variable.
RDP_FLAGS=""         # Imported variable.
RDP_FLAGS_WINDOWS=""     # Imported variable.
RDP_FLAGS_NON_WINDOWS="" # Imported variable.
RDP_FLAGS_SETUP_SAFE=""  # Derived variable used by setup checks and scans.
DEBUG="true"         # Imported variable.
FREERDP_COMMAND=""   # Imported variable.

PORT_TIMEOUT=5      # Default port check timeout.
RDP_TIMEOUT=30      # Default RDP connection test timeout.
APP_SCAN_TIMEOUT=60 # Default application scan timeout.

# PERMISSIONS AND DIRECTORIES
SUDO=""         # Set to "sudo" if the user specifies '--system', or "" if the user specifies '--user'.
BIN_PATH=""     # Set to $SYS_BIN_PATH if the user specifies '--system', or $USER_BIN_PATH if the user specifies '--user'.
APP_PATH=""     # Set to $SYS_APP_PATH if the user specifies '--system', or $USER_APP_PATH if the user specifies '--user'.
APPDATA_PATH="" # Set to $SYS_APPDATA_PATH if the user specifies '--system', or $USER_APPDATA_PATH if the user specifies '--user'.
SOURCE_PATH=""  # Set to $SYS_SOURCE_PATH if the user specifies '--system', or $USER_SOURCE_PATH if the user specifies '--user'.

# INSTALLATION PROCESS
INSTALLED_EXES=() # List of executable file names of officially supported applications that have already been configured during the current installation process.

### TRAPS ###
set -o errtrace              # Ensure traps are inherited by all shell functions and subshells.
trap "waTerminateScript" ERR # Catch non-zero return values.

### FUNCTIONS ###
# Name: 'waTerminateScript'
# Role: Terminates the script when a non-zero return value is encountered.
# shellcheck disable=SC2329 # Silence warning regarding this function never being invoked (shellCheck is currently bad at figuring out functions that are invoked via trap).
function waTerminateScript() {
    # Store the non-zero exit status received by the trap.
    local EXIT_STATUS=$?

    # Display the exit status.
    echo -e "${EXIT_TEXT}Exiting with status '${EXIT_STATUS}'.${CLEAR_TEXT}"

    # Terminate the script.
    exit "$EXIT_STATUS"
}
# Name: 'waUsage'
# Role: Displays usage information for the script.
function waUsage() {
    echo -e "Usage:
  ${COMMAND_TEXT}    --user${CLEAR_TEXT}                                        # Install WinApps and selected applications in ${HOME}
  ${COMMAND_TEXT}    --system${CLEAR_TEXT}                                      # Install WinApps and selected applications in /usr
  ${COMMAND_TEXT}    --user --setupAllOfficiallySupportedApps${CLEAR_TEXT}      # Install WinApps and all officially supported applications in ${HOME}
  ${COMMAND_TEXT}    --system --setupAllOfficiallySupportedApps${CLEAR_TEXT}    # Install WinApps and all officially supported applications in /usr
  ${COMMAND_TEXT}    --user --uninstall${CLEAR_TEXT}                            # Uninstall everything in ${HOME}
  ${COMMAND_TEXT}    --system --uninstall${CLEAR_TEXT}                          # Uninstall everything in /usr
  ${COMMAND_TEXT}    --user --add-apps${CLEAR_TEXT}                             # Add new applications to existing installation in ${HOME}
  ${COMMAND_TEXT}    --system --add-apps${CLEAR_TEXT}                           # Add new applications to existing installation in /usr
    ${COMMAND_TEXT}    --user --diagnose-rdp-drive${CLEAR_TEXT}                   # Diagnose RDP drive redirection/write-back for current user
    ${COMMAND_TEXT}    --system --diagnose-rdp-drive${CLEAR_TEXT}                 # Diagnose RDP drive redirection/write-back for system install
    ${COMMAND_TEXT}    --user --start-rdp-session${CLEAR_TEXT}                    # Start an interactive full Windows RDP session
    ${COMMAND_TEXT}    --system --start-rdp-session${CLEAR_TEXT}                  # Start an interactive full Windows RDP session
  ${COMMAND_TEXT}    --help${CLEAR_TEXT}                                        # Display this usage message."
}


# Name: 'waGetSourceCode'
# Role: Grab the WinApps source code using Git.
function waGetSourceCode() {
    # Declare variables.
    local SCRIPT_DIR_PATH="" # Stores the absolute path of the directory containing the script.
    local SCRIPT_SOURCE_VALID=1 # Set to '0' if the directory containing this script is a valid WinApps source tree.
    local GIT_TOPLEVEL=""      # Stores the Git toplevel path for the directory containing this script.

    # Determine the absolute path to the directory containing the script.
    SCRIPT_DIR_PATH=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")

    # Verify whether the script is being executed from a valid WinApps source tree.
    if [[ -f "$SCRIPT_DIR_PATH/setup.sh" && -f "$SCRIPT_DIR_PATH/bin/winapps" && -d "$SCRIPT_DIR_PATH/apps" && -d "$SCRIPT_DIR_PATH/install" ]]; then
        if git -C "$SCRIPT_DIR_PATH" rev-parse --show-toplevel &>/dev/null; then
            GIT_TOPLEVEL=$(git -C "$SCRIPT_DIR_PATH" rev-parse --show-toplevel 2>/dev/null)
            if [[ "$GIT_TOPLEVEL" == "$SCRIPT_DIR_PATH" ]]; then
                SCRIPT_SOURCE_VALID=0
            fi
        fi
    fi

    # If this script is being executed from a verified source tree, reuse it and skip clone/pull.
    if [[ "$SCRIPT_SOURCE_VALID" -eq 0 ]]; then
        SOURCE_PATH="$SCRIPT_DIR_PATH"
        echo -e "${INFO_TEXT}Verified local WinApps source at ${CLEAR_TEXT}${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT}${INFO_TEXT}. Skipping clone/update.${CLEAR_TEXT}"

        # Silently change the working directory.
        if ! cd "$SOURCE_PATH" &>/dev/null; then
            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}DIRECTORY CHANGE FAILURE.${CLEAR_TEXT}"

            # Display error details.
            echo -e "${INFO_TEXT}Failed to change the working directory to ${CLEAR_TEXT}${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT}${INFO_TEXT}.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Ensure:"
            echo -e "  - ${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT} exists."
            echo -e "  - ${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT} has been cloned and checked out properly."
            echo -e "  - The current user has sufficient permissions to access and write to ${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT}."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_FAILED_CD"
        fi

        return 0
    fi

    # Check if winapps is currently installed on $SOURCE_PATH
    if [[ -f "$SCRIPT_DIR_PATH/winapps" && "$SCRIPT_DIR_PATH" != "$SOURCE_PATH" ]]; then
        # Display a warning.
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} You are running a WinApps installation located outside of default location '${SOURCE_PATH}'. A new installation will be created."
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} You might want to remove your old installation on '${SCRIPT_DIR_PATH}'."
    fi

    if [[ ! -d "$SOURCE_PATH" ]]; then
        $SUDO git clone --recurse-submodules --remote-submodules https://github.com/winapps-org/winapps.git "$SOURCE_PATH"
    else
        echo -e "${INFO_TEXT}WinApps installation already present at ${CLEAR_TEXT}${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT}${INFO_TEXT}. Updating...${CLEAR_TEXT}"
        $SUDO git -C "$SOURCE_PATH" pull --no-rebase
    fi

    # Silently change the working directory.
    if ! cd "$SOURCE_PATH" &>/dev/null; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}DIRECTORY CHANGE FAILURE.${CLEAR_TEXT}"

        # Display error details.
        echo -e "${INFO_TEXT}Failed to change the working directory to ${CLEAR_TEXT}${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT}${INFO_TEXT}.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Ensure:"
        echo -e "  - ${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT} exists."
        echo -e "  - ${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT} has been cloned and checked out properly."
        echo -e "  - The current user has sufficient permissions to access and write to ${COMMAND_TEXT}${SOURCE_PATH}${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_FAILED_CD"
    fi
}

# Name: 'waGetInquirer'
# Role: Loads the inquirer script, even if the source isn't cloned yet
function waGetInquirer() {
    local INQUIRER=$INQUIRER_PATH

    if [ -d "$SYS_SOURCE_PATH" ]; then
        INQUIRER=$SYS_SOURCE_PATH/$INQUIRER_PATH
    elif [ -d "$USER_SOURCE_PATH" ] ; then
        INQUIRER=$USER_SOURCE_PATH/$INQUIRER_PATH
    else
        INQUIRER="/tmp/waInquirer.sh"
        rm -f "$INQUIRER"

        curl -o "$INQUIRER" "https://raw.githubusercontent.com/winapps-org/winapps/main/install/inquirer.sh"
    fi

    # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
    source "$INQUIRER"
}

# Name: 'waCheckInput'
# Role: Sanitises input and guides users through selecting appropriate options if no arguments are provided.
function waCheckInput() {
    # Declare variables.
    local OPTIONS=()      # Stores the options.
    local SELECTED_OPTION # Stores the option selected by the user.

    if [[ $# -gt 0 ]]; then
        # Parse arguments.
        for argument in "$@"; do
            case "$argument" in
            "--user")
                OPT_USER=1
                ;;
            "--system")
                OPT_SYSTEM=1
                ;;
            "--setupAllOfficiallySupportedApps")
                OPT_AOSA=1
                ;;
            "--uninstall")
                OPT_UNINSTALL=1
                ;;
            "--add-apps")
                OPT_ADD_APPS=1
                ;;
            "--diagnose-rdp-drive")
                OPT_DIAG=1
                ;;
            "--start-rdp-session")
                OPT_START_RDP=1
                ;;
            "--help")
                waUsage
                exit 0
                ;;
            *)
                # Display the error type.
                echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INVALID ARGUMENT.${CLEAR_TEXT}"

                # Display the error details.
                echo -e "${INFO_TEXT}Unsupported argument${CLEAR_TEXT} ${COMMAND_TEXT}${argument}${CLEAR_TEXT}${INFO_TEXT}.${CLEAR_TEXT}"

                # Display the suggested action(s).
                echo "--------------------------------------------------------------------------------"
                waUsage
                echo "--------------------------------------------------------------------------------"

                # Terminate the script.
                return "$EC_BAD_ARGUMENT"
                ;;
            esac
        done
    else
        # Install vs. uninstall?
        OPTIONS=("Install" "Uninstall")
        inqMenu "Install or uninstall WinApps?" OPTIONS SELECTED_OPTION

        # Set flags.
        if [[ $SELECTED_OPTION == "Uninstall" ]]; then
            OPT_UNINSTALL=1
        fi

        # User vs. system?
        OPTIONS=("Current User" "System")
        inqMenu "Configure WinApps for the current user '$(whoami)' or the whole system?" OPTIONS SELECTED_OPTION

        # Set flags.
        if [[ $SELECTED_OPTION == "Current User" ]]; then
            OPT_USER=1
        elif [[ $SELECTED_OPTION == "System" ]]; then
            OPT_SYSTEM=1
        fi

        # Automatic vs. manual?
        if [ "$OPT_UNINSTALL" -eq 0 ]; then
            OPTIONS=("Manual (Default)" "Automatic")
            inqMenu "Automatically install supported applications or choose manually?" OPTIONS SELECTED_OPTION

            # Set flags.
            if [[ $SELECTED_OPTION == "Automatic" ]]; then
                OPT_AOSA=1
            fi
        fi

        # Newline.
        echo ""
    fi

    # Simultaneous 'User' and 'System'.
    if [ "$OPT_SYSTEM" -eq 1 ] && [ "$OPT_USER" -eq 1 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You cannot specify both${CLEAR_TEXT} ${COMMAND_TEXT}--user${CLEAR_TEXT} ${INFO_TEXT}and${CLEAR_TEXT} ${COMMAND_TEXT}--system${CLEAR_TEXT} ${INFO_TEXT}simultaneously.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi

    # Simultaneous 'Uninstall' and 'AOSA'.
    if [ "$OPT_UNINSTALL" -eq 1 ] && [ "$OPT_AOSA" -eq 1 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You cannot specify both${CLEAR_TEXT} ${COMMAND_TEXT}--uninstall${CLEAR_TEXT} ${INFO_TEXT}and${CLEAR_TEXT} ${COMMAND_TEXT}--aosa${CLEAR_TEXT} ${INFO_TEXT}simultaneously.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi

    # Simultaneous 'Uninstall' and 'Add Apps'.
    if [ "$OPT_UNINSTALL" -eq 1 ] && [ "$OPT_ADD_APPS" -eq 1 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You cannot specify both${CLEAR_TEXT} ${COMMAND_TEXT}--uninstall${CLEAR_TEXT} ${INFO_TEXT}and${CLEAR_TEXT} ${COMMAND_TEXT}--add-apps${CLEAR_TEXT} ${INFO_TEXT}simultaneously.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi

    # Simultaneous 'AOSA' and 'Add Apps'.
    if [ "$OPT_AOSA" -eq 1 ] && [ "$OPT_ADD_APPS" -eq 1 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You cannot specify both${CLEAR_TEXT} ${COMMAND_TEXT}--setupAllOfficiallySupportedApps${CLEAR_TEXT} ${INFO_TEXT}and${CLEAR_TEXT} ${COMMAND_TEXT}--add-apps${CLEAR_TEXT} ${INFO_TEXT}simultaneously.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi

    # Diagnostic mode conflicts with install/uninstall/app-add actions.
    if [ "$OPT_DIAG" -eq 1 ] && { [ "$OPT_UNINSTALL" -eq 1 ] || [ "$OPT_AOSA" -eq 1 ] || [ "$OPT_ADD_APPS" -eq 1 ]; }; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The option${CLEAR_TEXT} ${COMMAND_TEXT}--diagnose-rdp-drive${CLEAR_TEXT} ${INFO_TEXT}cannot be combined with installation action flags.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi

    # RDP session starter mode conflicts with install/uninstall/app-add actions.
    if [ "$OPT_START_RDP" -eq 1 ] && { [ "$OPT_UNINSTALL" -eq 1 ] || [ "$OPT_AOSA" -eq 1 ] || [ "$OPT_ADD_APPS" -eq 1 ]; }; then
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"
        echo -e "${INFO_TEXT}The option${CLEAR_TEXT} ${COMMAND_TEXT}--start-rdp-session${CLEAR_TEXT} ${INFO_TEXT}cannot be combined with installation action flags.${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"
        return "$EC_BAD_ARGUMENT"
    fi

    # Diagnostic mode and RDP session starter mode cannot be combined.
    if [ "$OPT_DIAG" -eq 1 ] && [ "$OPT_START_RDP" -eq 1 ]; then
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONFLICTING ARGUMENTS.${CLEAR_TEXT}"
        echo -e "${INFO_TEXT}You cannot specify both${CLEAR_TEXT} ${COMMAND_TEXT}--diagnose-rdp-drive${CLEAR_TEXT} ${INFO_TEXT}and${CLEAR_TEXT} ${COMMAND_TEXT}--start-rdp-session${CLEAR_TEXT} ${INFO_TEXT}simultaneously.${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"
        return "$EC_BAD_ARGUMENT"
    fi

    # No 'User' or 'System'.
    if [ "$OPT_SYSTEM" -eq 0 ] && [ "$OPT_USER" -eq 0 ]; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INSUFFICIENT ARGUMENTS.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}You must specify either${CLEAR_TEXT} ${COMMAND_TEXT}--user${CLEAR_TEXT} ${INFO_TEXT}or${CLEAR_TEXT} ${COMMAND_TEXT}--system${CLEAR_TEXT} ${INFO_TEXT}to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        waUsage
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_ARGUMENT"
    fi
}

# Name: 'waConfigurePathsAndPermissions'
# Role: Sets paths and adjusts permissions as specified.
function waConfigurePathsAndPermissions() {
    if [ "$OPT_USER" -eq 1 ]; then
        SUDO=""
        SOURCE_PATH="$USER_SOURCE_PATH"
        BIN_PATH="$USER_BIN_PATH"
        APP_PATH="$USER_APP_PATH"
        APPDATA_PATH="$USER_APPDATA_PATH"
    elif [ "$OPT_SYSTEM" -eq 1 ]; then
        SUDO="sudo"
        SOURCE_PATH="$SYS_SOURCE_PATH"
        BIN_PATH="$SYS_BIN_PATH"
        APP_PATH="$SYS_APP_PATH"
        APPDATA_PATH="$SYS_APPDATA_PATH"

        # Preemptively obtain superuser privileges.
        sudo -v || {
            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}AUTHENTICATION FAILURE.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Failed to gain superuser privileges.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please check your password and try again."
            echo "If you continue to experience issues, contact your system administrator."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_NO_SUDO"
        }
    fi
}
# Name: 'waCheckExistingInstall'
# Role: Identifies any existing WinApps installations that may conflict with the new installation.
function waCheckExistingInstall() {
    # Print feedback.
    echo -n "Checking for existing conflicting WinApps installations... "

    # If --add-apps is specified, we don't want to fail if an installation exists
    if [ "$OPT_ADD_APPS" -eq 1 ]; then
        # Check for an existing 'user' installation.
        if [[ -f "${USER_BIN_PATH}/winapps" && -d "${USER_SOURCE_PATH}/winapps" ]]; then
            # Complete the previous line.
            echo -e "${DONE_TEXT}Found!${CLEAR_TEXT}"
            echo -e "${INFO_TEXT}Adding new applications to existing user installation.${CLEAR_TEXT}"
            return 0
        fi

        # Check for an existing 'system' installation.
        if [[ -f "${SYS_BIN_PATH}/winapps" && -d "${SYS_SOURCE_PATH}/winapps" ]]; then
            # Complete the previous line.
            echo -e "${DONE_TEXT}Found!${CLEAR_TEXT}"
            echo -e "${INFO_TEXT}Adding new applications to existing system installation.${CLEAR_TEXT}"
            return 0
        fi

        # If we're adding apps but no installation exists, that's an error
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}NO EXISTING WINAPPS INSTALLATION.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}No existing WinApps installation was detected.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please install WinApps first using ${COMMAND_TEXT}winapps-setup --user${CLEAR_TEXT} or ${COMMAND_TEXT}winapps-setup --system${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_EXISTING_INSTALL"
    fi

    # Check for an existing 'user' installation.
    if [[ -f "${USER_BIN_PATH}/winapps" || -d "${USER_SOURCE_PATH}/winapps" ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}EXISTING 'USER' WINAPPS INSTALLATION.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}A previous WinApps installation was detected for the current user.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please remove the existing WinApps installation using ${COMMAND_TEXT}winapps-setup --user --uninstall${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_EXISTING_INSTALL"
    fi

    # Check for an existing 'system' installation.
    if [[ -f "${SYS_BIN_PATH}/winapps" || -d "${SYS_SOURCE_PATH}/winapps" ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}EXISTING 'SYSTEM' WINAPPS INSTALLATION.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}A previous system-wide WinApps installation was detected.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please remove the existing WinApps installation using ${COMMAND_TEXT}winapps-setup --system --uninstall${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_EXISTING_INSTALL"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}


# Name: 'waFixScale'
# Role: Since FreeRDP only supports '/scale' values of 100, 140 or 180, find the closest supported argument to the user's configuration.
function waFixScale() {
    # Define variables.
    local OLD_SCALE=100
    local VALID_SCALE_1=100
    local VALID_SCALE_2=140
    local VALID_SCALE_3=180

    # Check for an unsupported value.
    if [ "$RDP_SCALE" != "$VALID_SCALE_1" ] && [ "$RDP_SCALE" != "$VALID_SCALE_2" ] && [ "$RDP_SCALE" != "$VALID_SCALE_3" ]; then
        # Save the unsupported scale.
        OLD_SCALE="$RDP_SCALE"

        # Calculate the absolute differences.
        local DIFF_1=$(( RDP_SCALE > VALID_SCALE_1 ? RDP_SCALE - VALID_SCALE_1 : VALID_SCALE_1 - RDP_SCALE ))
        local DIFF_2=$(( RDP_SCALE > VALID_SCALE_2 ? RDP_SCALE - VALID_SCALE_2 : VALID_SCALE_2 - RDP_SCALE ))
        local DIFF_3=$(( RDP_SCALE > VALID_SCALE_3 ? RDP_SCALE - VALID_SCALE_3 : VALID_SCALE_3 - RDP_SCALE ))

        # Set the final scale to the valid scale value with the smallest absolute difference.
        if (( DIFF_1 <= DIFF_2 && DIFF_1 <= DIFF_3 )); then
            RDP_SCALE="$VALID_SCALE_1"
        elif (( DIFF_2 <= DIFF_1 && DIFF_2 <= DIFF_3 )); then
            RDP_SCALE="$VALID_SCALE_2"
        else
            RDP_SCALE="$VALID_SCALE_3"
        fi

        # Print feedback.
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} Unsupported RDP_SCALE value '${OLD_SCALE}' detected. Defaulting to '${RDP_SCALE}'."
    fi
}

# Name: 'waLoadConfig'
# Role: Loads settings specified within the WinApps configuration file.
function waLoadConfig() {
    # Print feedback.
    echo -n "Attempting to load WinApps configuration file... "

    if [ ! -f "$CONFIG_PATH" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING CONFIGURATION FILE.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}A valid WinApps configuration file was not found.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please create a configuration file at ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
        echo -e "See https://github.com/winapps-org/winapps?tab=readme-ov-file#step-3-create-a-winapps-configuration-file"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_NO_CONFIG"
    else
        # Load the WinApps configuration file.
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "$CONFIG_PATH"

        # Backward compatibility: older config files use a single 'RDP_FLAGS' value.
        # Prefer session-specific flags when provided.
        if [[ -z "$RDP_FLAGS_NON_WINDOWS" && -n "$RDP_FLAGS" ]]; then
            RDP_FLAGS_NON_WINDOWS="$RDP_FLAGS"
        fi

        # Setup-safe flag set for RemoteApp checks/scans.
        # Strip modern flags that can cause issues on older Windows versions (e.g., 8.1).
        RDP_FLAGS_SETUP_SAFE=$(echo "$RDP_FLAGS_NON_WINDOWS" | sed -E \
            -e 's/(^|[[:space:]])\+dynamic-resolution([[:space:]]|$)/ /g' \
            -e 's/(^|[[:space:]])\+async-update([[:space:]]|$)/ /g' \
            -e 's/(^|[[:space:]])\/gfx:[^[:space:]]+([[:space:]]|$)/ /g' \
            -e 's/(^|[[:space:]])\/gdi:hw([[:space:]]|$)/ /g' \
            -e 's/[[:space:]]+/ /g' \
            -e 's/^[[:space:]]+//' \
            -e 's/[[:space:]]+$//')
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckScriptDependencies'
# Role: Terminate script if dependencies are missing.
function waCheckScriptDependencies() {
    # 'Git'
    if ! command -v git &>/dev/null; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'git' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install git${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install git${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S git${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask dev-vcs/git${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'curl'
    if ! command -v curl &>/dev/null; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'curl' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install curl${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install curl${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S curl${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask net-misc/curl${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'Dialog'.
    if ! command -v dialog &>/dev/null; then
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'dialog' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install dialog${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install dialog${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S dialog${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask dialog${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi
}

# Name: 'waCheckInstallDependencies'
# Role: Terminate script if dependencies required to install WinApps are missing.
function waCheckInstallDependencies() {
    # Declare variables.
    local FREERDP_MAJOR_VERSION="" # Stores the major version of the installed copy of FreeRDP.

    # Print feedback.
    echo -n "Checking whether dependencies are installed... "

    # 'libnotify'
    if ! command -v notify-send &>/dev/null; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'libnotify' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install libnotify-bin${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install libnotify${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S libnotify${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask x11-libs/libnotify${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'Netcat'
    if ! command -v nc &>/dev/null; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'netcat' to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install netcat${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install nmap-ncat${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S openbsd-netcat${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask net-analyzer/netcat${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'FreeRDP' (Version 2+).
    # Attempt to set a FreeRDP command if the command variable is empty.
    if [ -z "$FREERDP_COMMAND" ]; then
        # Check common commands used to launch FreeRDP.
        if command -v xfreerdp &>/dev/null; then
            # Check FreeRDP major version is 2 or greater.
            FREERDP_MAJOR_VERSION=$(xfreerdp --version | head -n 1 | grep -o -m 1 '\b[0-9]\S*' | head -n 1 | cut -d'.' -f1)
            if [[ $FREERDP_MAJOR_VERSION =~ ^[0-9]+$ ]] && ((FREERDP_MAJOR_VERSION >= 2)); then
                FREERDP_COMMAND="xfreerdp"
            fi
        fi

        # Check for xfreerdp3 command as a fallback option.
        if [ -z "$FREERDP_COMMAND" ]; then
            if command -v xfreerdp3 &>/dev/null; then
                # Check FreeRDP major version is 2 or greater.
                FREERDP_MAJOR_VERSION=$(xfreerdp3 --version | head -n 1 | grep -o -m 1 '\b[0-9]\S*' | head -n 1 | cut -d'.' -f1)
                if [[ $FREERDP_MAJOR_VERSION =~ ^[0-9]+$ ]] && ((FREERDP_MAJOR_VERSION >= 2)); then
                    FREERDP_COMMAND="xfreerdp3"
                fi
            fi
        fi

        # Check for FreeRDP flatpak as a fallback option.
        if [ -z "$FREERDP_COMMAND" ]; then
            if command -v flatpak &>/dev/null; then
                if flatpak list --columns=application | grep -q "^com.freerdp.FreeRDP$"; then
                    # Check FreeRDP major version is 2 or greater.
                    FREERDP_MAJOR_VERSION=$(flatpak list --columns=application,version | grep "^com.freerdp.FreeRDP" | awk '{print $2}' | cut -d'.' -f1)
                    if [[ $FREERDP_MAJOR_VERSION =~ ^[0-9]+$ ]] && ((FREERDP_MAJOR_VERSION >= 2)); then
                        FREERDP_COMMAND="flatpak run --command=xfreerdp com.freerdp.FreeRDP"
                    fi
                fi
            fi
        fi
    fi

    if ! command -v "$FREERDP_COMMAND" &>/dev/null && [ "$FREERDP_COMMAND" != "flatpak run --command=xfreerdp com.freerdp.FreeRDP" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Please install 'FreeRDP' version 2 or newer to proceed.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Debian/Ubuntu-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo apt install freerdp3-x11${CLEAR_TEXT}"
        echo "Red Hat/Fedora-based systems:"
        echo -e "  ${COMMAND_TEXT}sudo dnf install freerdp${CLEAR_TEXT}"
        echo "Arch Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo pacman -S freerdp${CLEAR_TEXT}"
        echo "Gentoo Linux systems:"
        echo -e "  ${COMMAND_TEXT}sudo emerge --ask net-misc/freerdp${CLEAR_TEXT}"
        echo ""
        echo "You can also install FreeRDP as a Flatpak."
        echo "Install Flatpak, add the Flathub repository and then install FreeRDP:"
        echo -e "${COMMAND_TEXT}flatpak install flathub com.freerdp.FreeRDP${CLEAR_TEXT}"
        echo -e "${COMMAND_TEXT}sudo flatpak override --filesystem=home com.freerdp.FreeRDP${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_MISSING_DEPS"
    fi

    # 'libvirt'/'virt-manager' + 'iproute2'.
    if [ "$WAFLAVOR" = "libvirt" ]; then
        if ! command -v virsh &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'Virtual Machine Manager' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Debian/Ubuntu-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo apt install virt-manager${CLEAR_TEXT}"
            echo "Red Hat/Fedora-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo dnf install virt-manager${CLEAR_TEXT}"
            echo "Arch Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo pacman -S virt-manager${CLEAR_TEXT}"
            echo "Gentoo Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo emerge --ask app-emulation/virt-manager${CLEAR_TEXT}"
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi

        if ! command -v ip &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'iproute2' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Debian/Ubuntu-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo apt install iproute2${CLEAR_TEXT}"
            echo "Red Hat/Fedora-based systems:"
            echo -e "  ${COMMAND_TEXT}sudo dnf install iproute${CLEAR_TEXT}"
            echo "Arch Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo pacman -S iproute2${CLEAR_TEXT}"
            echo "Gentoo Linux systems:"
            echo -e "  ${COMMAND_TEXT}sudo emerge --ask net-misc/iproute2${CLEAR_TEXT}"
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi
    elif [ "$WAFLAVOR" = "docker" ]; then
        if ! command -v docker &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'Docker Engine' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please visit https://docs.docker.com/engine/install/ for more information."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi
    elif [ "$WAFLAVOR" = "podman" ]; then
        if ! command -v podman-compose &>/dev/null || ! command -v podman &>/dev/null; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}MISSING DEPENDENCIES.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}Please install 'podman' and 'podman-compose' to proceed.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please visit https://podman.io/docs/installation for more information."
            echo "Please visit https://github.com/containers/podman-compose for more information."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_MISSING_DEPS"
        fi
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waGetFreeRDPMajorVersion'
# Role: Determine the FreeRDP major version for a command string.
function waGetFreeRDPMajorVersion() {
    local FREERDP_CMD="$1"
    local MAJOR_VERSION="0"

    # Podman wrapper support.
    if [[ "$FREERDP_CMD" == podman\ unshare\ --rootless-netns\ * ]]; then
        FREERDP_CMD="${FREERDP_CMD#podman unshare --rootless-netns }"
    fi

    if [ "$FREERDP_CMD" = "flatpak run --command=xfreerdp com.freerdp.FreeRDP" ]; then
        if command -v flatpak &>/dev/null; then
            MAJOR_VERSION=$(flatpak list --columns=application,version | grep "^com.freerdp.FreeRDP" | awk '{print $2}' | cut -d'.' -f1)
        fi
    elif command -v "$FREERDP_CMD" &>/dev/null; then
        MAJOR_VERSION=$($FREERDP_CMD --version 2>/dev/null | head -n 1 | grep -o -m 1 '\b[0-9]\S*' | head -n 1 | cut -d'.' -f1)
    fi

    if [[ ! $MAJOR_VERSION =~ ^[0-9]+$ ]]; then
        MAJOR_VERSION="0"
    fi

    echo "$MAJOR_VERSION"
}

# Name: 'waBuildAuthPkgArgs'
# Role: Build auth package filter arguments only for FreeRDP v3+.
function waBuildAuthPkgArgs() {
    local FREERDP_CMD="$1"
    local FREERDP_MAJOR_VERSION="0"

    WA_AUTH_PKG_ARGS=()
    FREERDP_MAJOR_VERSION=$(waGetFreeRDPMajorVersion "$FREERDP_CMD")
    if (( FREERDP_MAJOR_VERSION >= 3 )); then
        WA_AUTH_PKG_ARGS=("/auth-pkg-list:!kerberos")
    fi
}

# Name: 'waBuildRemoteAppArgs'
# Role: Build FreeRDP RemoteApp arguments compatible with v2 and v3 syntax.
function waBuildRemoteAppArgs() {
    local FREERDP_CMD="$1"
    local APP_PROGRAM="$2"
    local APP_CMD="$3"
    local FREERDP_MAJOR_VERSION="0"

    WA_REMOTEAPP_ARGS=()
    FREERDP_MAJOR_VERSION=$(waGetFreeRDPMajorVersion "$FREERDP_CMD")

    if (( FREERDP_MAJOR_VERSION >= 3 )); then
        WA_REMOTEAPP_ARGS=("/app:program:${APP_PROGRAM},cmd:${APP_CMD}")
    else
        WA_REMOTEAPP_ARGS=("/app:${APP_PROGRAM}" "/app-cmd:${APP_CMD}")
    fi
}

# Name: 'waCheckGroupMembership'
# Role: Ensures the current user is part of the required groups.
function waCheckGroupMembership() {
    # Print feedback.
    echo -n "Checking whether the user '$(whoami)' is part of the required groups... "

    # Declare variables.
    local USER_GROUPS="" # Stores groups the current user belongs to.

    # Identify groups the current user belongs to.
    USER_GROUPS=$(groups "$(whoami)")

    if ! (echo "$USER_GROUPS" | grep -q -E "\blibvirt\b") || ! (echo "$USER_GROUPS" | grep -q -E "\bkvm\b"); then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}GROUP MEMBERSHIP CHECK ERROR.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The current user '$(whoami)' is not part of group 'libvirt' and/or group 'kvm'.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please run the below commands, followed by a system reboot:"
        echo -e "${COMMAND_TEXT}sudo usermod -a -G libvirt $(whoami)${CLEAR_TEXT}"
        echo -e "${COMMAND_TEXT}sudo usermod -a -G kvm $(whoami)${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_NOT_IN_GROUP"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckVMRunning'
# Role: Checks the state of the Windows 'libvirt' VM to ensure it is running.
function waCheckVMRunning() {
    # Print feedback.
    echo -n "Checking the status of the Windows VM... "

    # Obtain VM Status
    VM_PAUSED=0
    virsh list --state-paused --name | grep -Fxq -- "$VM_NAME" || VM_PAUSED="$?"
    VM_RUNNING=0
    virsh list --state-running --name | grep -Fxq -- "$VM_NAME" || VM_RUNNING="$?"
    VM_SHUTOFF=0
    virsh list --state-shutoff --name | grep -Fxq -- "$VM_NAME" || VM_SHUTOFF="$?"

    if [[ $VM_SHUTOFF == "0" ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}WINDOWS VM NOT RUNNING.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The Windows VM '${VM_NAME}' is powered off.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please run the below command to start the Windows VM:"
        echo -e "${COMMAND_TEXT}virsh start ${VM_NAME}${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_VM_OFF"
    elif [[ $VM_PAUSED == "0" ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}WINDOWS VM NOT RUNNING.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The Windows VM '${VM_NAME}' is paused.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please run the below command to resume the Windows VM:"
        echo -e "${COMMAND_TEXT}virsh resume ${VM_NAME}${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_VM_PAUSED"
    elif [[ $VM_RUNNING != "0" ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}WINDOWS VM DOES NOT EXIST.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}The Windows VM '${VM_NAME}' could not be found.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please ensure a Windows VM with the name '${VM_NAME}' exists."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_VM_ABSENT"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckContainerRunning'
# Role: Throw an error if the Docker/Podman container is not running.
function waCheckContainerRunning() {
    # Print feedback.
    echo -n "Checking container status... "

    # Declare variables.
    local CONTAINER_STATE=""
    local COMPOSE_COMMAND=""

    # Determine the state of the container.
    CONTAINER_STATE=$("$WAFLAVOR" ps --all --filter name="WinApps" --format '{{.Status}}')
    CONTAINER_STATE=${CONTAINER_STATE,,} # Convert the string to lowercase.
    CONTAINER_STATE=${CONTAINER_STATE%% *} # Extract the first word.

    # Determine the compose command.
    case "$WAFLAVOR" in
        "docker") COMPOSE_COMMAND="docker compose" ;;
        "podman") COMPOSE_COMMAND="podman-compose" ;;
    esac

    # Check container state.
    if [[ "$CONTAINER_STATE" != "up" ]]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}CONTAINER NOT RUNNING.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Windows is not running.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please ensure Windows is powered on:"
        echo -e "${COMMAND_TEXT}${COMPOSE_COMMAND} --file ~/.config/winapps/compose.yaml start${CLEAR_TEXT}"
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_CONTAINER_OFF"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckPortOpen'
# Role: Assesses whether the RDP port on Windows is open.
function waCheckPortOpen() {
    # Print feedback.
    echo -n "Checking for an open RDP Port on Windows... "

    # Declare variables.
    local VM_MAC="" # Stores the MAC address of the Windows VM.

    # Obtain Windows VM IP Address (FOR 'libvirt' ONLY)
    # Note: 'RDP_IP' should not be empty if 'WAFLAVOR' is 'docker', since it is set to localhost before this function is called.
    if [ -z "$RDP_IP" ] && [ "$WAFLAVOR" = "libvirt" ]; then
        VM_MAC=$(virsh domiflist "$VM_NAME" | grep -oE "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") # VM MAC address.
        RDP_IP=$(ip neigh show | grep "$VM_MAC" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")         # VM IP address.

        if [ -z "$RDP_IP" ]; then
            # Complete the previous line.
            echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

            # Display the error type.
            echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}NETWORK CONFIGURATION ERROR.${CLEAR_TEXT}"

            # Display the error details.
            echo -e "${INFO_TEXT}The IP address of the Windows VM '${VM_NAME}' could not be found.${CLEAR_TEXT}"

            # Display the suggested action(s).
            echo "--------------------------------------------------------------------------------"
            echo "Please ensure networking is properly configured for the Windows VM."
            echo "--------------------------------------------------------------------------------"

            # Terminate the script.
            return "$EC_NO_IP"
        fi
    fi

    # Check for an open RDP port.
    if ! timeout "$PORT_TIMEOUT" nc -z "$RDP_IP" "$RDP_PORT" &>/dev/null; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}NETWORK CONFIGURATION ERROR.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Failed to establish a connection with Windows at '${RDP_IP}:${RDP_PORT}'.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo "Please ensure Remote Desktop is configured on Windows as per the WinApps README."
        echo -e "Then you can try increasing the ${COMMAND_TEXT}PORT_TIMEOUT${CLEAR_TEXT} in ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_BAD_PORT"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waCheckRDPAccess'
# Role: Tests if Windows is accessible via RDP.
function waCheckRDPAccess() {
    # Print feedback.
    echo -n "Attempting to establish a Remote Desktop connection with Windows... "

    # Declare variables.
    local FREERDP_LOG=""  # Stores the path of the FreeRDP log file.
    local FREERDP_PROC="" # Stores the FreeRDP process ID.
    local ELAPSED_TIME="" # Stores the time counter.
    local PRIMARY_FREERDP_COMMAND="$FREERDP_COMMAND"
    local FALLBACK_FREERDP_COMMAND=""
    local CURRENT_FREERDP_COMMAND=""
    local ATTEMPT_COUNT=0

    # Some systems have both xfreerdp and xfreerdp3, and one may be more stable for RemoteApp checks.
    # Keep configured/autodetected command as primary and only fallback to the sibling command when available.
    if [ "$PRIMARY_FREERDP_COMMAND" = "xfreerdp" ] && command -v xfreerdp3 &>/dev/null; then
        FALLBACK_FREERDP_COMMAND="xfreerdp3"
    elif [ "$PRIMARY_FREERDP_COMMAND" = "xfreerdp3" ] && command -v xfreerdp &>/dev/null; then
        FALLBACK_FREERDP_COMMAND="xfreerdp"
    fi

    # Try primary command first, then fallback command if needed.
    for CURRENT_FREERDP_COMMAND in "$PRIMARY_FREERDP_COMMAND" "$FALLBACK_FREERDP_COMMAND"; do
        if [ -z "$CURRENT_FREERDP_COMMAND" ]; then
            continue
        fi

        ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))

        # Log file path.
        FREERDP_LOG="${USER_APPDATA_PATH}/FreeRDP_Test_$(date +'%Y%m%d_%H%M_%N')_${CURRENT_FREERDP_COMMAND}.log"

        # Ensure the output directory exists.
        mkdir -p "$USER_APPDATA_PATH"

        # Remove existing 'FreeRDP Connection Test' file.
        rm -f "$TEST_PATH"

        # This command should create a file on the host filesystem before terminating the RDP session. This command is silently executed as a background process.
        # If the file is created, it means Windows received the command via FreeRDP successfully and can read and write to the Linux home folder.
        # Note: The following final line is expected within the log, indicating successful execution of the 'tsdiscon' command and termination of the RDP session.
        # [INFO][com.freerdp.core] - [rdp_print_errinfo]: ERRINFO_LOGOFF_BY_USER (0x0000000C):The disconnection was initiated by the user logging off their session on the server.
        waBuildAuthPkgArgs "$CURRENT_FREERDP_COMMAND"
        waBuildRemoteAppArgs "$CURRENT_FREERDP_COMMAND" "C:\Windows\System32\cmd.exe" "/C copy /Y NUL $TEST_PATH_WIN >NUL && tsdiscon"
        # shellcheck disable=SC2140,SC2027,SC2086 # Disable warnings regarding unquoted strings.
        $CURRENT_FREERDP_COMMAND \
            $RDP_FLAGS_SETUP_SAFE \
            /cert:tofu \
            "${WA_AUTH_PKG_ARGS[@]}" \
            /d:"$RDP_DOMAIN" \
            /u:"$RDP_USER" \
            /p:"$RDP_PASS" \
            /scale:"$RDP_SCALE" \
            +auto-reconnect \
            +home-drive \
            "${WA_REMOTEAPP_ARGS[@]}" \
            /v:"$RDP_IP" &>"$FREERDP_LOG" &

        # Store the FreeRDP process ID.
        FREERDP_PROC=$!

        # Initialise the time counter.
        ELAPSED_TIME=0

        # Wait a maximum of $RDP_TIMEOUT seconds for the background process to complete.
        while [ "$ELAPSED_TIME" -lt "$RDP_TIMEOUT" ]; do
            # Check if the FreeRDP process is complete or if the test file exists.
            if ! ps -p "$FREERDP_PROC" &>/dev/null || [ -f "$TEST_PATH" ]; then
                break
            fi

            # Wait for 5 seconds.
            sleep 5
            ELAPSED_TIME=$((ELAPSED_TIME + 5))
        done

        # Check if FreeRDP process is not complete.
        if ps -p "$FREERDP_PROC" &>/dev/null; then
            # SIGKILL FreeRDP.
            kill -9 "$FREERDP_PROC" &>/dev/null
        fi

        # A successful marker means this command worked.
        if [ -f "$TEST_PATH" ]; then
            rm -f "$TEST_PATH"
            FREERDP_COMMAND="$CURRENT_FREERDP_COMMAND"
            echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
            return 0
        fi

        # Compatibility fallback: some Windows/RemoteApp combinations complete transport and drive registration,
        # but fail to execute/write marker commands reliably in probe mode.
        local HAS_DRIVE_REG=1
        local HAS_CLEAN_LOGOFF=1
        local HAS_REMOTEAPP_LIFECYCLE=1
        local HAS_SESSION_ESTABLISHED=1

        grep -q -E "registered \[[[:space:]]*drive\] device #[0-9]+:[[:space:]]+home|Loading device service drive \[home\]" "$FREERDP_LOG" || HAS_DRIVE_REG=$?
        grep -q "ERRINFO_LOGOFF_BY_USER" "$FREERDP_LOG" || HAS_CLEAN_LOGOFF=$?
        grep -q -E "xf_rail_server_system_param|client_auto_reconnect_ex|ERRCONNECT_CONNECT_TRANSPORT_FAILED" "$FREERDP_LOG" || HAS_REMOTEAPP_LIFECYCLE=$?
        grep -q -E "gdi_init_ex]: Local framebuffer format|Loading device service drive \[home\]" "$FREERDP_LOG" || HAS_SESSION_ESTABLISHED=$?

        # Prefer explicit clean RemoteApp completion. Some FreeRDP builds omit the exact drive-registration line.
        # Also accept established-session markers to avoid false failures when logoff/marker write is delayed.
        if [ "$HAS_CLEAN_LOGOFF" -eq 0 ] || [ "$HAS_SESSION_ESTABLISHED" -eq 0 ] || { [ "$HAS_DRIVE_REG" -eq 0 ] && [ "$HAS_REMOTEAPP_LIFECYCLE" -eq 0 ]; }; then
            FREERDP_COMMAND="$CURRENT_FREERDP_COMMAND"
            echo -e "${INFO_TEXT}Note:${CLEAR_TEXT} RDP session connected, but marker-file write was skipped (compatibility fallback)."
            echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} Continuing setup; if app scan fails, use ${COMMAND_TEXT}--start-rdp-session${CLEAR_TEXT} once, then rerun setup."
            echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
            return 0
        fi

        # Show retry hint if we have an alternate command to test next.
        if [ "$ATTEMPT_COUNT" -eq 1 ] && [ -n "$FALLBACK_FREERDP_COMMAND" ]; then
            echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} RDP probe with ${COMMAND_TEXT}${CURRENT_FREERDP_COMMAND}${CLEAR_TEXT} failed. Retrying with ${COMMAND_TEXT}${FALLBACK_FREERDP_COMMAND}${CLEAR_TEXT}..."
        fi
    done

    # Complete the previous line.
    echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

    # Display the error type.
    echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}REMOTE DESKTOP PROTOCOL FAILURE.${CLEAR_TEXT}"

    # Display the error details.
    echo -e "${INFO_TEXT}FreeRDP failed to establish a connection with Windows.${CLEAR_TEXT}"
    if [ -n "$FALLBACK_FREERDP_COMMAND" ]; then
        echo -e "${INFO_TEXT}Tried commands:${CLEAR_TEXT} ${COMMAND_TEXT}${PRIMARY_FREERDP_COMMAND}${CLEAR_TEXT}${INFO_TEXT} and${CLEAR_TEXT} ${COMMAND_TEXT}${FALLBACK_FREERDP_COMMAND}${CLEAR_TEXT}${INFO_TEXT}.${CLEAR_TEXT}"
    fi

    # Display the suggested action(s).
    echo "--------------------------------------------------------------------------------"
    echo -e "Please view the log at ${COMMAND_TEXT}${FREERDP_LOG}${CLEAR_TEXT}."
    echo "Troubleshooting Tips:"
    echo "  - Ensure the user is logged out of Windows prior to initiating the WinApps installation."
    echo "  - Ensure the credentials within the WinApps configuration file are correct."
    echo -e "  - Utilise a new certificate by removing relevant certificate(s) in ${COMMAND_TEXT}${HOME}/.config/freerdp/server${CLEAR_TEXT}."
    echo -e "  - Try increasing the ${COMMAND_TEXT}RDP_TIMEOUT${CLEAR_TEXT} in ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
    echo "  - If using 'libvirt', ensure the Windows VM is correctly named as specified within the README."
    echo "  - If using 'libvirt', ensure 'Remote Desktop' is enabled within the Windows VM."
    echo "  - If using 'libvirt', ensure you have merged 'RDPApps.reg' into the Windows VM's registry."
    echo "  - If using 'libvirt', try logging into and back out of the Windows VM within 'virt-manager' prior to initiating the WinApps installation."
    echo "--------------------------------------------------------------------------------"

    # Terminate the script.
    return "$EC_RDP_FAIL"
}

# Name: 'waDiagnoseRDPDrive'
# Role: Runs a focused diagnostic for RDP drive redirection/write-back issues.
function waDiagnoseRDPDrive() {
    echo -e "${BOLD_TEXT}RDP Drive Redirection Diagnostic${CLEAR_TEXT}"

    local DIAG_LOG=""
    local DIAG_PROC=""
    local ELAPSED_TIME=""
    local DIAG_ROOT_PATH="${HOME}/winapps_rdp_diag_root"
    local DIAG_NESTED_PATH="${USER_APPDATA_PATH}/winapps_rdp_diag_nested"
    local DIAG_ROOT_PATH_WIN='\\tsclient\home\winapps_rdp_diag_root'
    local DIAG_NESTED_PATH_WIN="${USER_APPDATA_PATH_WIN}\\winapps_rdp_diag_nested"

    # Load config and prerequisites exactly as in setup mode.
    waLoadConfig
    waCheckInstallDependencies
    waFixScale

    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        RDP_IP="$DOCKER_IP"
    fi

    if [ "$WAFLAVOR" = "podman" ]; then
        FREERDP_COMMAND="podman unshare --rootless-netns ${FREERDP_COMMAND}"
    fi

    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        waCheckContainerRunning
    elif [ "$WAFLAVOR" = "libvirt" ]; then
        waCheckGroupMembership
        waCheckVMRunning
    elif [ "$WAFLAVOR" = "manual" ]; then
        :
    else
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INVALID WINAPPS BACKEND.${CLEAR_TEXT}"
        echo -e "${INFO_TEXT}An invalid WinApps backend '${WAFLAVOR}' was specified.${CLEAR_TEXT}"
        return "$EC_INVALID_FLAVOR"
    fi

    waCheckPortOpen
    mkdir -p "$USER_APPDATA_PATH"
    rm -f "$DIAG_ROOT_PATH" "$DIAG_NESTED_PATH"

    DIAG_LOG="${USER_APPDATA_PATH}/FreeRDP_DriveDiag_$(date +'%Y%m%d_%H%M_%N').log"

    echo -n "Running RemoteApp write-back probe... "
    waBuildAuthPkgArgs "$FREERDP_COMMAND"
    waBuildRemoteAppArgs "$FREERDP_COMMAND" "C:\Windows\System32\cmd.exe" "/C copy /Y NUL ${DIAG_ROOT_PATH_WIN} >NUL && copy /Y NUL ${DIAG_NESTED_PATH_WIN} >NUL && tsdiscon"
    # shellcheck disable=SC2140,SC2027,SC2086
    $FREERDP_COMMAND \
        $RDP_FLAGS_SETUP_SAFE \
        /cert:tofu \
        "${WA_AUTH_PKG_ARGS[@]}" \
        /d:"$RDP_DOMAIN" \
        /u:"$RDP_USER" \
        /p:"$RDP_PASS" \
        /scale:"$RDP_SCALE" \
        +auto-reconnect \
        +home-drive \
        "${WA_REMOTEAPP_ARGS[@]}" \
        /v:"$RDP_IP" &>"$DIAG_LOG" &

    DIAG_PROC=$!
    ELAPSED_TIME=0

    while [ "$ELAPSED_TIME" -lt "$RDP_TIMEOUT" ]; do
        if ! ps -p "$DIAG_PROC" &>/dev/null || [ -f "$DIAG_ROOT_PATH" ] || [ -f "$DIAG_NESTED_PATH" ]; then
            break
        fi

        sleep 5
        ELAPSED_TIME=$((ELAPSED_TIME + 5))
    done

    if ps -p "$DIAG_PROC" &>/dev/null; then
        kill -9 "$DIAG_PROC" &>/dev/null
    fi

    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"

    echo "--------------------------------------------------------------------------------"
    echo -e "Diagnostic log: ${COMMAND_TEXT}${DIAG_LOG}${CLEAR_TEXT}"
    if [ -f "$DIAG_ROOT_PATH" ]; then
        echo -e "Root write (${COMMAND_TEXT}${DIAG_ROOT_PATH_WIN}${CLEAR_TEXT}): ${DONE_TEXT}PASS${CLEAR_TEXT}"
    else
        echo -e "Root write (${COMMAND_TEXT}${DIAG_ROOT_PATH_WIN}${CLEAR_TEXT}): ${FAIL_TEXT}FAIL${CLEAR_TEXT}"
    fi

    if [ -f "$DIAG_NESTED_PATH" ]; then
        echo -e "Nested write (${COMMAND_TEXT}${DIAG_NESTED_PATH_WIN}${CLEAR_TEXT}): ${DONE_TEXT}PASS${CLEAR_TEXT}"
    else
        echo -e "Nested write (${COMMAND_TEXT}${DIAG_NESTED_PATH_WIN}${CLEAR_TEXT}): ${FAIL_TEXT}FAIL${CLEAR_TEXT}"
    fi

    if grep -q "registered \[    drive\] device #1:  home" "$DIAG_LOG"; then
        echo -e "RDP drive registration: ${DONE_TEXT}PASS${CLEAR_TEXT}"
    else
        echo -e "RDP drive registration: ${FAIL_TEXT}FAIL${CLEAR_TEXT}"
    fi

    if grep -q "ERRINFO_LOGOFF_BY_USER" "$DIAG_LOG"; then
        echo -e "RemoteApp command session: ${DONE_TEXT}COMPLETED${CLEAR_TEXT}"
    else
        echo -e "RemoteApp command session: ${WARNING_TEXT}INCOMPLETE${CLEAR_TEXT}"
    fi
    echo "--------------------------------------------------------------------------------"

    if [ -f "$DIAG_ROOT_PATH" ] && [ -f "$DIAG_NESTED_PATH" ]; then
        echo -e "${SUCCESS_TEXT}DIAGNOSTIC RESULT: PASS${CLEAR_TEXT}"
        rm -f "$DIAG_ROOT_PATH" "$DIAG_NESTED_PATH"
        return 0
    fi

    echo -e "${ERROR_TEXT}DIAGNOSTIC RESULT: FAIL${CLEAR_TEXT}"
    echo "Likely cause: RemoteApp session could not write back to redirected drive (\\tsclient)."
    echo "Note: Full desktop RDP sessions can still work even when this RemoteApp probe fails."
    echo "Suggested checks on Windows:"
    echo "  - Ensure drive redirection is allowed in RDP host policy/settings."
    echo "  - In cmd.exe on Windows, test: dir \\tsclient\\home"
    echo "  - In cmd.exe on Windows, test: copy /Y NUL \\tsclient\\home\\winapps_manual_probe"

    return "$EC_APPQUERY_FAIL"
}

# Name: 'waStartRDPSession'
# Role: Starts an interactive full Windows RDP desktop session.
function waStartRDPSession() {
    echo -e "${BOLD_TEXT}Starting Interactive Windows RDP Session${CLEAR_TEXT}"
    local RDP_EXIT_CODE=0

    waLoadConfig
    waCheckInstallDependencies
    waFixScale

    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        RDP_IP="$DOCKER_IP"
    fi

    if [ "$WAFLAVOR" = "podman" ]; then
        FREERDP_COMMAND="podman unshare --rootless-netns ${FREERDP_COMMAND}"
    fi

    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        waCheckContainerRunning
    elif [ "$WAFLAVOR" = "libvirt" ]; then
        waCheckGroupMembership
        waCheckVMRunning
    elif [ "$WAFLAVOR" = "manual" ]; then
        :
    else
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INVALID WINAPPS BACKEND.${CLEAR_TEXT}"
        echo -e "${INFO_TEXT}An invalid WinApps backend '${WAFLAVOR}' was specified.${CLEAR_TEXT}"
        return "$EC_INVALID_FLAVOR"
    fi

    waCheckPortOpen

    echo "--------------------------------------------------------------------------------"
    echo "Launching full desktop session."
    echo "Tips:"
    echo "  - To prepare WinApps on older Windows versions, sign in to Windows first."
    echo "  - Then disconnect from inside Windows (Start Menu > Sign out, or run 'tsdiscon')."
    echo "--------------------------------------------------------------------------------"

    waBuildAuthPkgArgs "$FREERDP_COMMAND"
    # shellcheck disable=SC2086
    $FREERDP_COMMAND \
        $RDP_FLAGS_SETUP_SAFE \
        /cert:tofu \
        "${WA_AUTH_PKG_ARGS[@]}" \
        /d:"$RDP_DOMAIN" \
        /u:"$RDP_USER" \
        /p:"$RDP_PASS" \
        /scale:"$RDP_SCALE" \
        +auto-reconnect \
        +home-drive \
        /v:"$RDP_IP"

    RDP_EXIT_CODE=$?

    # FreeRDP commonly returns 12 when the session is intentionally disconnected (e.g., via tsdiscon).
    if [ "$RDP_EXIT_CODE" -ne 0 ] && [ "$RDP_EXIT_CODE" -ne 12 ]; then
        return "$RDP_EXIT_CODE"
    fi

    echo -e "${DONE_TEXT}RDP session exited.${CLEAR_TEXT}"
    return 0
}

# Name: 'waFindInstalled'
# Role: Identifies installed applications on Windows.
function waFindInstalled() {
    # Print feedback.
    echo -n "Checking for installed Windows applications... "

    # Declare variables.
    local FREERDP_LOG=""   # Stores the path of the FreeRDP log file.
    local FREERDP_PROC=""  # Stores the FreeRDP process ID.
    local ELAPSED_TIME=""  # Stores the time counter.
    local WARMUP_LOG=""    # Stores the path of a temporary FreeRDP warm-up log file.
    local STAGE_BATCH_PATH="" # Stores the UNIX path of a root-level staged batch script.
    local STAGE_PS_PATH="" # Stores the UNIX path of a root-level staged PowerShell script.
    local STAGE_INST_PATH="" # Stores the UNIX path of a root-level staged installed file.
    local STAGE_DET_PATH=""  # Stores the UNIX path of a root-level staged detected file.
    local MANUAL_SCAN_BATCH_PATH="" # Stores the UNIX path of a full-session manual scan batch script.
    local STAGE_BATCH_PATH_WIN='\\tsclient\home\winapps_installed.bat' # WINDOWS path of staged batch script.
    local STAGE_PS_PATH_WIN='\\tsclient\home\winapps_extractprograms.ps1' # WINDOWS path of staged PowerShell script.
    local STAGE_INST_PATH_WIN='\\tsclient\home\winapps_installed' # WINDOWS path of staged installed file.
    local STAGE_DET_PATH_WIN='\\tsclient\home\winapps_detected' # WINDOWS path of staged detected file.
    local MANUAL_SCAN_BATCH_PATH_WIN='\\tsclient\home\winapps_fullsession_scan.bat' # WINDOWS path of full-session manual scan batch.

    # Log file path.
    FREERDP_LOG="${USER_APPDATA_PATH}/FreeRDP_Scan_$(date +'%Y%m%d_%H%M_%N').log"
    WARMUP_LOG="${USER_APPDATA_PATH}/FreeRDP_ScanWarmup_$(date +'%Y%m%d_%H%M_%N').log"
    STAGE_BATCH_PATH="${HOME}/winapps_installed.bat"
    STAGE_PS_PATH="${HOME}/winapps_extractprograms.ps1"
    STAGE_INST_PATH="${HOME}/winapps_installed"
    STAGE_DET_PATH="${HOME}/winapps_detected"
    MANUAL_SCAN_BATCH_PATH="${HOME}/winapps_fullsession_scan.bat"

    # Import staged scan results from a prior full desktop RDP session if available.
    if [ -f "$STAGE_INST_PATH" ] && [ -f "$STAGE_DET_PATH" ]; then
        mv -f "$STAGE_INST_PATH" "$INST_FILE_PATH"
        mv -f "$STAGE_DET_PATH" "$DETECTED_FILE_PATH"
        echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
        return 0
    fi

    # Make the output directory if required.
    mkdir -p "$USER_APPDATA_PATH"

    # Remove temporary files from previous WinApps installations.
    rm -f "$BATCH_SCRIPT_PATH" "$TMP_INST_FILE_PATH" "$INST_FILE_PATH" "$PS_SCRIPT_HOME_PATH" "$DETECTED_FILE_PATH" "$STAGE_BATCH_PATH" "$STAGE_PS_PATH" "$STAGE_INST_PATH" "$STAGE_DET_PATH"

    # Copy PowerShell script to a directory within the user's home folder.
    # This will enable the PowerShell script to be accessed and executed by Windows.
    cp "$PS_SCRIPT_PATH" "$PS_SCRIPT_HOME_PATH"
    # Also stage a root-level copy to avoid nested redirected-path issues on older Windows versions.
    cp "$PS_SCRIPT_PATH" "$STAGE_PS_PATH"

    # Build results in local Windows temp files first.
    # This is more reliable on older Windows versions where repeated UNC writes can be flaky.
    echo "SET \"WA_TMP_INST=%TEMP%\\winapps-installed.tmp\"" >>"$BATCH_SCRIPT_PATH"
    echo "SET \"WA_TMP_DET=%TEMP%\\winapps-detected.tmp\"" >>"$BATCH_SCRIPT_PATH"
    echo "SET \"WA_TMP_PS=%TEMP%\\winapps-ExtractPrograms.ps1\"" >>"$BATCH_SCRIPT_PATH"
    echo "DEL /F /Q \"%WA_TMP_INST%\" \"%WA_TMP_DET%\" \"%WA_TMP_PS%\" >NUL 2>&1" >>"$BATCH_SCRIPT_PATH"
    echo "COPY /Y NUL \"%WA_TMP_INST%\" >NUL" >>"$BATCH_SCRIPT_PATH"

    # Enumerate over each officially supported application.
    for APPLICATION in ./apps/*; do
        # Extract the name of the application from the absolute path of the folder.
        APPLICATION="$(basename "$APPLICATION")"

        if [[ "$APPLICATION" == "ms-office-protocol-handler.desktop" ]]; then
            continue
        fi

        # Source 'Info' File Containing:
        # - The Application Name          (FULL_NAME)
        # - The Shortcut Name             (NAME)
        # - Application Categories        (CATEGORIES)
        # - Executable Path               (WIN_EXECUTABLE)
        # - Supported MIME Types          (MIME_TYPES)
        # - Application Icon              (ICON)
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "./apps/${APPLICATION}/info"

        # Append commands to batch file.
        echo "IF EXIST \"${WIN_EXECUTABLE}\" ECHO ${APPLICATION}^|^|^|${WIN_EXECUTABLE} >> \"%WA_TMP_INST%\"" >>"$BATCH_SCRIPT_PATH"
    done

    # Run the PowerShell scanner locally, then copy all outputs back to Linux with retries.
    # shellcheck disable=SC2129 # Silence warning regarding repeated redirects.
    echo "COPY /Y ${STAGE_PS_PATH_WIN} \"%WA_TMP_PS%\" >NUL" >>"$BATCH_SCRIPT_PATH"
    echo "powershell.exe -ExecutionPolicy Bypass -File \"%WA_TMP_PS%\" > \"%WA_TMP_DET%\"" >>"$BATCH_SCRIPT_PATH"
    echo "SET /A WA_TRIES=0" >>"$BATCH_SCRIPT_PATH"
    echo ":WA_COPY_BACK" >>"$BATCH_SCRIPT_PATH"
    echo "COPY /Y \"%WA_TMP_INST%\" ${STAGE_INST_PATH_WIN} >NUL" >>"$BATCH_SCRIPT_PATH"
    echo "COPY /Y \"%WA_TMP_DET%\" ${STAGE_DET_PATH_WIN} >NUL" >>"$BATCH_SCRIPT_PATH"
    echo "IF EXIST ${STAGE_INST_PATH_WIN} IF EXIST ${STAGE_DET_PATH_WIN} GOTO WA_DONE" >>"$BATCH_SCRIPT_PATH"
    echo "SET /A WA_TRIES+=1" >>"$BATCH_SCRIPT_PATH"
    echo "IF %WA_TRIES% GEQ 15 GOTO WA_DONE" >>"$BATCH_SCRIPT_PATH"
    echo "PING -n 2 127.0.0.1 >NUL" >>"$BATCH_SCRIPT_PATH"
    echo "GOTO WA_COPY_BACK" >>"$BATCH_SCRIPT_PATH"
    echo ":WA_DONE" >>"$BATCH_SCRIPT_PATH"

    # Append a command to the batch script to terminate the remote desktop session once all previous commands are complete.
    echo "tsdiscon" >>"$BATCH_SCRIPT_PATH"

    # Stage the generated batch at a root-level redirected path.
    cp "$BATCH_SCRIPT_PATH" "$STAGE_BATCH_PATH"
    cp "$BATCH_SCRIPT_PATH" "$MANUAL_SCAN_BATCH_PATH"

    # Warm up a RemoteApp session (without UNC access) before the actual scan.
    # This improves reliability of redirected drive access on the subsequent reconnect session.
    waBuildAuthPkgArgs "$FREERDP_COMMAND"
    waBuildRemoteAppArgs "$FREERDP_COMMAND" "C:\Windows\System32\cmd.exe" "/C PING -n 6 127.0.0.1 >NUL && tsdiscon"
    # shellcheck disable=SC2140,SC2027,SC2086 # Disable warnings regarding unquoted strings.
    $FREERDP_COMMAND \
        $RDP_FLAGS_SETUP_SAFE \
        /cert:tofu \
        "${WA_AUTH_PKG_ARGS[@]}" \
        /d:"$RDP_DOMAIN" \
        /u:"$RDP_USER" \
        /p:"$RDP_PASS" \
        /scale:"$RDP_SCALE" \
        +auto-reconnect \
        +home-drive \
        "${WA_REMOTEAPP_ARGS[@]}" \
        /v:"$RDP_IP" &>"$WARMUP_LOG" || true

    # Give Windows a brief moment to settle before starting the scan command.
    sleep 2

    # Silently execute the batch script within Windows in the background (Log Output To File)
    # Note: The following final line is expected within the log, indicating successful execution of the 'tsdiscon' command and termination of the RDP session.
    # [INFO][com.freerdp.core] - [rdp_print_errinfo]: ERRINFO_LOGOFF_BY_USER (0x0000000C):The disconnection was initiated by the user logging off their session on the server.
    # The batch script is copied to a local Windows %TEMP% path before execution to avoid restrictions on running scripts from UNC network paths.
    waBuildRemoteAppArgs "$FREERDP_COMMAND" "C:\Windows\System32\cmd.exe" "/C copy $STAGE_BATCH_PATH_WIN %TEMP%\\wa_scan.bat && call %TEMP%\\wa_scan.bat"
    # shellcheck disable=SC2140,SC2027,SC2086 # Disable warnings regarding unquoted strings.
    $FREERDP_COMMAND \
        $RDP_FLAGS_SETUP_SAFE \
        /cert:tofu \
        "${WA_AUTH_PKG_ARGS[@]}" \
        /d:"$RDP_DOMAIN" \
        /u:"$RDP_USER" \
        /p:"$RDP_PASS" \
        /scale:"$RDP_SCALE" \
        +auto-reconnect \
        +home-drive \
        "${WA_REMOTEAPP_ARGS[@]}" \
        /v:"$RDP_IP" &>"$FREERDP_LOG" &

    # Store the FreeRDP process ID.
    FREERDP_PROC=$!

    # Initialise the time counter.
    ELAPSED_TIME=0

    # Wait a maximum of $APP_SCAN_TIMEOUT seconds for the batch script to finish running.
    while [ $ELAPSED_TIME -lt "$APP_SCAN_TIMEOUT" ]; do
        # Check if the FreeRDP process is complete or if the 'installed' file exists.
        if ! ps -p "$FREERDP_PROC" &>/dev/null || [ -f "$INST_FILE_PATH" ]; then
            break
        fi

        # Wait for 5 seconds.
        sleep 5
        ELAPSED_TIME=$((ELAPSED_TIME + 5))
    done

    # Check if the FreeRDP process is not complete.
    if ps -p "$FREERDP_PROC" &>/dev/null; then
        # SIGKILL FreeRDP.
        kill -9 "$FREERDP_PROC" &>/dev/null
    fi

    # If stage files exist at root-level tsclient paths, promote them to expected WinApps paths.
    if [ -f "$STAGE_INST_PATH" ]; then
        mv -f "$STAGE_INST_PATH" "$INST_FILE_PATH"
    fi
    if [ -f "$STAGE_DET_PATH" ]; then
        mv -f "$STAGE_DET_PATH" "$DETECTED_FILE_PATH"
    fi

    # Check if test file does not exist.
    if ! [ -f "$INST_FILE_PATH" ]; then
        # Complete the previous line.
        echo -e "${FAIL_TEXT}Failed!${CLEAR_TEXT}\n"

        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}APPLICATION QUERY FAILURE.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}Failed to query Windows for installed applications.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please view the log at ${COMMAND_TEXT}${FREERDP_LOG}${CLEAR_TEXT}."
        echo -e "You can try increasing the ${COMMAND_TEXT}APP_SCAN_TIMEOUT${CLEAR_TEXT} in ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
        echo -e "If full desktop RDP works on your Windows version, run this inside a desktop session:"
        echo -e "  ${COMMAND_TEXT}${MANUAL_SCAN_BATCH_PATH_WIN}${CLEAR_TEXT}"
        echo -e "Then rerun setup; staged results at ${COMMAND_TEXT}${STAGE_INST_PATH_WIN}${CLEAR_TEXT} and ${COMMAND_TEXT}${STAGE_DET_PATH_WIN}${CLEAR_TEXT} will be imported automatically."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_APPQUERY_FAIL"
    fi

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waConfigureWindows'
# Role: Create an application entry for launching Windows via Remote Desktop.
function waConfigureWindows() {
    # Print feedback.
    echo -n "Creating an application entry for Windows... "

    # Declare variables.
    local WIN_BASH=""    # Stores the bash script to launch a Windows RDP session.
    local WIN_DESKTOP="" # Stores the '.desktop' file to launch a Windows RDP session.

    # Populate variables.
    WIN_BASH="\
#!/usr/bin/env bash
${BIN_PATH}/winapps windows"
    WIN_DESKTOP="\
[Desktop Entry]
Name=Windows
Exec=${BIN_PATH}/winapps windows %F
Terminal=false
Type=Application
Icon=${APPDATA_PATH}/icons/windows.svg
StartupWMClass=Microsoft Windows
Comment=Microsoft Windows RDP Session"

    # Copy the 'Windows' icon.
    $SUDO cp "./install/windows.svg" "${APPDATA_PATH}/icons/windows.svg"

    # Write the desktop entry content to a file.
    echo "$WIN_DESKTOP" | $SUDO tee "${APP_PATH}/windows.desktop" &>/dev/null

    # Write the bash script to a file.
    echo "$WIN_BASH" | $SUDO tee "${BIN_PATH}/windows" &>/dev/null

    # Mark the bash script as executable.
    $SUDO chmod a+x "${BIN_PATH}/windows"

    # Print feedback.
    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
}

# Name: 'waConfigureApp'
# Role: Create application entries for a given application installed on Windows.
function waConfigureApp() {
    # Declare variables.
    local APP_ICON=""         # Stores the path to the application icon.
    local APP_BASH=""         # Stores the bash script used to launch the application.
    local APP_DESKTOP_FILE="" # Stores the '.desktop' file used to launch the application.

    # Source 'Info' File Containing:
    # - The Application Name          (FULL_NAME)
    # - The Shortcut Name             (NAME)
    # - Application Categories        (CATEGORIES)
    # - Executable Path               (WIN_EXECUTABLE)
    # - Supported MIME Types          (MIME_TYPES)
    # - Application Icon              (ICON)
    # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
    source "${APPDATA_PATH}/apps/${1}/info"

    # Determine path to application icon using arguments passed to function.
    APP_ICON="${APPDATA_PATH}/apps/${1}/icon.${2}"

    # Determine the content of the bash script for the application.
    APP_BASH="\
#!/usr/bin/env bash
${BIN_PATH}/winapps ${1}"

    # Determine the content of the '.desktop' file for the application.
    APP_DESKTOP_FILE="\
[Desktop Entry]
Name=${NAME}
Exec=${BIN_PATH}/winapps ${1} %F
Terminal=false
Type=Application
Icon=${APP_ICON}
StartupWMClass=${FULL_NAME}
Comment=${FULL_NAME}
Categories=${CATEGORIES}
MimeType=${MIME_TYPES}"

    # Store the '.desktop' file for the application.
    echo "$APP_DESKTOP_FILE" | $SUDO tee "${APP_PATH}/${1}.desktop" &>/dev/null

    # Store the bash script for the application.
    echo "$APP_BASH" | $SUDO tee "${BIN_PATH}/${1}" &>/dev/null

    # Mark bash script as executable.
    $SUDO chmod a+x "${BIN_PATH}/${1}"
}

# Name: 'waConfigureOfficiallySupported'
# Role: Create application entries for officially supported applications installed on Windows.
function waConfigureOfficiallySupported() {
    # Declare variables.
    local OSA_LIST=() # Stores a list of all officially supported applications installed on Windows.
    local OFFICE_APPS=("access" "access-o365" "access-o365-x86" "access-x86" "adobe-cc" "acrobat9" "acrobat-x-pro" "aftereffects-cc" "audition-cc" "bridge-cc" "bridge-cc-x86" "bridge-cs6" "bridge-cs6-x86" "cmd" "dymo-connect" "excel" "excel-o365" "excel-o365-x86" "excel-x86" "excel-x86-2010" "explorer" "iexplorer" "illustrator-cc" "lightroom-cc" "linqpad8" "mirc" "mspaint" "onenote" "onenote-o365" "onenote-o365-x86" "onenote-x86" "outlook" "outlook-o365" "outlook-o365-x86" "powerbi" "powerbi-store" "powerpoint" "powerpoint-o365" "powerpoint-o365-x86" "powerpoint-x86" "publisher" "publisher-o365" "publisher-o365-x86" "publisher-x86" "project" "project-x86" "remarkable-desktop" "ssms20" "visual-studio-comm" "visual-studio-ent" "visual-studio-pro" "visio" "visio-x86" "word" "word-o365" "word-o365-x86" "word-x86" "word-x86-2010")

    # Read the list of officially supported applications that are installed on Windows into an array, returning an empty array if no such files exist.
    readarray -t OSA_LIST < <(grep -v '^[[:space:]]*$' "$INST_FILE_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' 2>/dev/null || true)

    # Create application entries for each officially supported application.
    for OSA in "${OSA_LIST[@]}"; do
        # Split the line by the '|||' delimiter
        local APP_NAME="${OSA%%|||*}"
        local ACTUAL_WIN_EXECUTABLE="${OSA##*|||}"

        # If splitting failed for some reason, skip this line to be safe.
        if [[ -z "$APP_NAME" || -z "$ACTUAL_WIN_EXECUTABLE" ]]; then
            continue
        fi

        # Print feedback using the clean application name.
        echo -n "Creating an application entry for ${APP_NAME}... "

        # Copy the original, unmodified application assets.
        # --no-preserve=mode is needed to avoid missing write permissions when copying from Nix store.
        $SUDO cp -r --no-preserve=mode "./apps/${APP_NAME}" "${APPDATA_PATH}/apps"

        local DESTINATION_INFO_FILE="${APPDATA_PATH}/apps/${APP_NAME}/info"

        # Sanitize the string using pure Bash. This is fast and safe.
        local SED_SAFE_PATH="${ACTUAL_WIN_EXECUTABLE//&/\\&}"
        SED_SAFE_PATH="${SED_SAFE_PATH//\\/\\\\}"

        # Use the sanitized string to safely edit the file.
        $SUDO sed -i "s|^WIN_EXECUTABLE=.*|WIN_EXECUTABLE=\"${SED_SAFE_PATH}\"|" "$DESTINATION_INFO_FILE"

        # Configure the application using the clean name.
        waConfigureApp "$APP_NAME" svg

        # Check if the application is an Office app and copy the protocol handler.
        if [[ " ${OFFICE_APPS[*]} " == *" $APP_NAME "* ]]; then
            # Determine the target directory based on whether the installation is for the system or user.
            if [[ "$OPT_SYSTEM" -eq 1 ]]; then
                TARGET_DIR="$SYS_APP_PATH"
            else
                TARGET_DIR="$USER_APP_PATH"
            fi

            # Copy the protocol handler to the appropriate directory.
            $SUDO cp "./apps/ms-office-protocol-handler.desktop" "$TARGET_DIR/ms-office-protocol-handler.desktop"
        fi

        # Print feedback.
        echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
    done

    # Delete 'install' file.
    rm -f "$INST_FILE_PATH"
}

# Name: 'waConfigureApps'
# Role: Allow the user to select which officially supported applications to configure.
function waConfigureApps() {
    # Declare variables.
    local OSA_LIST=()      # Stores a list of all officially supported applications installed on Windows.
    local APPS=()          # Stores a list of both the simplified and full names of each installed officially supported application.
    local OPTIONS=()       # Stores a list of options presented to the user.
    local APP_INSTALL=""   # Stores the option selected by the user.
    local SELECTED_APPS=() # Stores the officially supported applications selected by the user.
    local TEMP_ARRAY=()    # Temporary array used for sorting elements of an array.
    declare -A APP_DATA_MAP # Associative array to map short names back to their full data line.

    # Read the list of officially supported applications that are installed on Windows into an array, returning an empty array if no such files exist.
    # This will remove leading and trailing whitespace characters as well as ignore empty lines.
    readarray -t OSA_LIST < <(grep -v '^[[:space:]]*$' "$INST_FILE_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' 2>/dev/null || true)

    # Loop over each officially supported application installed on Windows.
    for OSA in "${OSA_LIST[@]}"; do
        # Source 'Info' File Containing:
        # - The Application Name          (FULL_NAME)
        # - The Shortcut Name             (NAME)
        # - Application Categories        (CATEGORIES)
        # - Executable Path               (WIN_EXECUTABLE)
        # - Supported MIME Types          (MIME_TYPES)
        # - Application Icon              (ICON)

        # Split the line to get the clean application name
        local APP_NAME="${OSA%%|||*}"
        local ACTUAL_WIN_EXECUTABLE="${OSA##*|||*}"

        # If splitting failed, skip this entry.
        if [[ -z "$APP_NAME" ]]; then
            continue
        fi

        # Use the clean APP_NAME to source the info file
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "./apps/${APP_NAME}/info"

        # Add both the simplified and full name of the application to an array.
        APPS+=("${FULL_NAME} (${APP_NAME})")

        # Store the original data line in our map so we can retrieve it later.
        APP_DATA_MAP["$APP_NAME"]="$OSA"

        # Extract the executable file name (e.g. 'MyApp.exe') from the absolute path.
        WIN_EXECUTABLE="${ACTUAL_WIN_EXECUTABLE##*\\}"

        # Trim any leading or trailing whitespace characters from the executable file name.
        read -r WIN_EXECUTABLE <<<"$(echo "$WIN_EXECUTABLE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # Add the executable file name (in lowercase) to the array.
        INSTALLED_EXES+=("${WIN_EXECUTABLE,,}")
    done

    # Sort the 'APPS' array in alphabetical order.
    IFS=$'\n'
    # shellcheck disable=SC2207 # Silence warnings regarding preferred use of 'mapfile' or 'read -a'.
    TEMP_ARRAY=($(sort <<<"${APPS[*]}"))
    unset IFS
    APPS=("${TEMP_ARRAY[@]}")

    # Prompt user to select which officially supported applications to configure.
    OPTIONS=(
        "Set up all detected officially supported applications"
        "Choose specific officially supported applications to set up"
        "Skip setting up any officially supported applications"
    )
    inqMenu "How would you like to handle officially supported applications?" OPTIONS APP_INSTALL

    # Remove unselected officially supported applications from the 'install' file.
    if [[ $APP_INSTALL == "Choose specific officially supported applications to set up" ]]; then
        inqChkBx "Which officially supported applications would you like to set up?" APPS SELECTED_APPS

        # Clear/create the 'install' file.
        echo "" >"$INST_FILE_PATH"

        # Add each selected officially supported application back to the 'install' file.
        for SELECTED_APP in "${SELECTED_APPS[@]}"; do
            # Capture the substring within (but not including) the parentheses.
            # This substring represents the officially supported application name (see above loop).
            local SHORT_NAME="${SELECTED_APP##*(}"
            SHORT_NAME="${SHORT_NAME%%)}"

            # Use the map to find the original data line (e.g., "word|||C:\...") and write it back.
            echo "${APP_DATA_MAP[$SHORT_NAME]}" >>"$INST_FILE_PATH"
        done
    fi

    # Configure selected (or all) officially supported applications.
    if [[ $APP_INSTALL != "Skip setting up any officially supported applications" ]]; then
        waConfigureOfficiallySupported
    fi
}

# Name: 'waConfigureDetectedApps'
# Role: Allow the user to select which detected applications to configure.
function waConfigureDetectedApps() {
    # Declare variables.
    local APPS=()                   # Stores a list of both the simplified and full names of each detected application.
    local EXE_FILENAME=""           # Stores the executable filename of a given detected application.
    local EXE_FILENAME_NOEXT=""     # Stores the executable filename without the file extension of a given detected application.
    local EXE_FILENAME_LOWERCASE="" # Stores the executable filename of a given detected application in lowercase letters only.
    local OPTIONS=()                # Stores a list of options presented to the user.
    local APP_INSTALL=""            # Stores the option selected by the user.
    local SELECTED_APPS=()          # Detected applications selected by the user.
    local APP_DESKTOP_FILE=""       # Stores the '.desktop' file used to launch the application.
    local TEMP_ARRAY=()             # Temporary array used for sorting elements of an array.

    if [ -f "$DETECTED_FILE_PATH" ]; then
        # On UNIX systems, lines are terminated with a newline character (\n).
        # On WINDOWS systems, lines are terminated with both a carriage return (\r) and a newline (\n) character.
        # Remove all carriage returns (\r) within the 'detected' file, as the file was written by Windows.
        sed -i 's/\r//g' "$DETECTED_FILE_PATH"

        # Import the detected application information:
        # - Application Names               (NAMES)
        # - Application Icons in base64     (ICONS)
        # - Application Executable Paths    (EXES)
        # shellcheck source=/dev/null # Exclude this file from being checked by ShellCheck.
        source "$DETECTED_FILE_PATH"

        # shellcheck disable=SC2153 # Silence warnings regarding possible misspellings.
        for INDEX in "${!NAMES[@]}"; do
            # Extract the executable file name (e.g. 'MyApp.exe').
            EXE_FILENAME=${EXES[$INDEX]##*\\}

            # Convert the executable file name to lower-case (e.g. 'myapp.exe').
            EXE_FILENAME_LOWERCASE="${EXE_FILENAME,,}"

            # Remove the file extension (e.g. 'MyApp').
            EXE_FILENAME_NOEXT="${EXE_FILENAME%.*}"

            # Check if the executable was previously configured as part of setting up officially supported applications.
            if [[ " ${INSTALLED_EXES[*]} " != *" ${EXE_FILENAME_LOWERCASE} "* ]]; then
                # If not previously configured, add the application to the list of detected applications.
                APPS+=("${NAMES[$INDEX]} (${EXE_FILENAME_NOEXT})")
            fi
        done

        # Sort the 'APPS' array in alphabetical order.
        IFS=$'\n'
        # shellcheck disable=SC2207 # Silence warnings regarding preferred use of 'mapfile' or 'read -a'.
        TEMP_ARRAY=($(sort <<<"${APPS[*]}"))
        unset IFS
        APPS=("${TEMP_ARRAY[@]}")

        # Prompt user to select which other detected applications to configure.
        OPTIONS=(
            "Set up all detected applications"
            "Select which applications to set up"
            "Do not set up any applications"
        )
        inqMenu "How would you like to handle other detected applications?" OPTIONS APP_INSTALL

        # Store selected detected applications.
        if [[ $APP_INSTALL == "Select which applications to set up" ]]; then
            inqChkBx "Which other applications would you like to set up?" APPS SELECTED_APPS
        elif [[ $APP_INSTALL == "Set up all detected applications" ]]; then
            for APP in "${APPS[@]}"; do
                SELECTED_APPS+=("$APP")
            done
        fi

        for SELECTED_APP in "${SELECTED_APPS[@]}"; do
            # Capture the substring within (but not including) the parentheses.
            # This substring represents the executable filename without the file extension (see above loop).
            EXE_FILENAME_NOEXT="${SELECTED_APP##*(}"
            EXE_FILENAME_NOEXT="${EXE_FILENAME_NOEXT%%)}"

            # Capture the substring prior to the space and parentheses.
            # This substring represents the detected application name (see above loop).
            PROGRAM_NAME="${SELECTED_APP% (*}"

            # Loop through all detected applications to find the detected application being processed.
            for INDEX in "${!NAMES[@]}"; do
                # Check for a matching detected application entry.
                if [[ ${NAMES[$INDEX]} == "$PROGRAM_NAME" ]] && [[ ${EXES[$INDEX]} == *"\\$EXE_FILENAME_NOEXT"* ]]; then
                    # Print feedback.
                    echo -n "Creating an application entry for ${PROGRAM_NAME}... "

                    # Create directory to store application icon and information.
                    $SUDO mkdir -p "${APPDATA_PATH}/apps/${EXE_FILENAME_NOEXT}"

                    # Determine the content of the '.desktop' file for the application.
                    APP_DESKTOP_FILE="\
# GNOME Shortcut Name
NAME=\"${PROGRAM_NAME}\"
# Used for Descriptions and Window Class
FULL_NAME=\"${PROGRAM_NAME}\"
# Path to executable inside Windows
WIN_EXECUTABLE=\"${EXES[$INDEX]}\"
# GNOME Categories
CATEGORIES=\"WinApps\"
# GNOME MIME Types
MIME_TYPES=\"\""

                    # Store the '.desktop' file for the application.
                    echo "$APP_DESKTOP_FILE" | $SUDO tee "${APPDATA_PATH}/apps/${EXE_FILENAME_NOEXT}/info" &>/dev/null

                    # Write application icon to file.
                    echo "${ICONS[$INDEX]}" | base64 -d | $SUDO tee "${APPDATA_PATH}/apps/${EXE_FILENAME_NOEXT}/icon.png" &>/dev/null

                    # Configure the application.
                    waConfigureApp "$EXE_FILENAME_NOEXT" png

                    # Print feedback.
                    echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
                fi
            done
        done
    fi
}

# Name: 'waInstall'
# Role: Installs WinApps.
function waInstall() {
    # Print feedback.
    echo -e "${BOLD_TEXT}Installing WinApps.${CLEAR_TEXT}"

    # Check for existing conflicting WinApps installations.
    waCheckExistingInstall

    # Load the WinApps configuration file.
    waLoadConfig

    # Check for missing dependencies.
    waCheckInstallDependencies

    # Update $RDP_SCALE.
    waFixScale

    # If using 'docker' or 'podman', set RDP_IP to localhost.
    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        RDP_IP="$DOCKER_IP"
    fi

    # If using podman backend, modify the FreeRDP command to enter a new namespace.
    if [ "$WAFLAVOR" = "podman" ]; then
        FREERDP_COMMAND="podman unshare --rootless-netns ${FREERDP_COMMAND}"
    fi

    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        # Check if Windows is powered on.
        waCheckContainerRunning
    elif [ "$WAFLAVOR" = "libvirt" ]; then
        # Verify the current user's group membership.
        waCheckGroupMembership

        # Check if the Windows VM is powered on.
        waCheckVMRunning
    elif [ "$WAFLAVOR" = "manual" ]; then
        waCheckPortOpen
    else
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INVALID WINAPPS BACKEND.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}An invalid WinApps backend '${WAFLAVOR}' was specified.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please ensure 'WAFLAVOR' is set to 'docker', 'podman' or 'libvirt' in ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_INVALID_FLAVOR"
    fi

    # Check if the RDP port on Windows is open.
    waCheckPortOpen

    # Test RDP access to Windows.
    waCheckRDPAccess

    # Create required directories.
    $SUDO mkdir -p "$BIN_PATH"
    $SUDO mkdir -p "$APP_PATH"
    $SUDO mkdir -p "$APPDATA_PATH/apps"
    $SUDO mkdir -p "$APPDATA_PATH/icons"

    # Check for installed applications.
    waFindInstalled

    # Install the WinApps bash scripts.
    $SUDO ln -sf "${SOURCE_PATH}/bin/winapps" "${BIN_PATH}/winapps"
    $SUDO ln -sf "${SOURCE_PATH}/setup.sh" "${BIN_PATH}/winapps-setup"

    # Configure the Windows RDP session application launcher.
    waConfigureWindows

    if [ "$OPT_AOSA" -eq 1 ]; then
        # Automatically configure all officially supported applications.
        waConfigureOfficiallySupported
    else
        # Configure officially supported applications.
        waConfigureApps

        # Configure other detected applications.
        waConfigureDetectedApps
    fi

    # Ensure BIN_PATH is on PATH
    waEnsureOnPath

    # Print feedback.
    echo -e "${SUCCESS_TEXT}INSTALLATION COMPLETE.${CLEAR_TEXT}"
}

# Name: 'waEnsureOnPath'
# Role: Ensures that $BIN_PATH is on $PATH.
function waEnsureOnPath() {
    if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} It seems like '${BIN_PATH}' is not on PATH."
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} You can add it by running:"
        # shellcheck disable=SC2086
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT}   - For Bash: ${COMMAND_TEXT}echo 'export PATH="${BIN_PATH}:\$PATH"' >> ~/.bashrc && source ~/.bashrc${CLEAR_TEXT}"
        # shellcheck disable=SC2086
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT}   - For ZSH: ${COMMAND_TEXT}echo 'export PATH="${BIN_PATH}:\$PATH"' >> ~/.zshrc && source ~/.zshrc${CLEAR_TEXT}"
        echo -e "${WARNING_TEXT}[WARNING]${CLEAR_TEXT} Make sure to restart your Terminal afterwards.\n"
    fi
}

# Name: 'waUninstall'
# Role: Uninstalls WinApps.
function waUninstall() {

    # Print feedback.
    [ "$OPT_SYSTEM" -eq 1 ] && echo -e "${BOLD_TEXT}REMOVING SYSTEM INSTALLATION.${CLEAR_TEXT}"
    [ "$OPT_USER" -eq 1 ] && echo -e "${BOLD_TEXT}REMOVING USER INSTALLATION.${CLEAR_TEXT}"

    # Determine the target directory for the protocol handler based on the installation type.
    if [[ "$OPT_SYSTEM" -eq 1 ]]; then
        TARGET_DIR="$SYS_APP_PATH"
    else
        TARGET_DIR="$USER_APP_PATH"
    fi

    # Remove the 'ms-office-protocol-handler.desktop' file if it exists.
    $SUDO rm -f "$TARGET_DIR/ms-office-protocol-handler.desktop"

    # Declare variables.
    local WINAPPS_DESKTOP_FILES=()    # Stores a list of '.desktop' file paths.
    local WINAPPS_APP_BASH_SCRIPTS=() # Stores a list of bash script paths.
    local DESKTOP_FILE_NAME=""        # Stores the name of the '.desktop' file for the application.
    local BASH_SCRIPT_NAME=""         # Stores the name of the application.

    # Remove the 'WinApps' bash scripts.
    $SUDO rm -f "${BIN_PATH}/winapps"
    $SUDO rm -f "${BIN_PATH}/winapps-setup"

    # Remove WinApps configuration data, temporary files and logs.
    rm -rf "$USER_APPDATA_PATH"

    # Remove application icons and shortcuts.
    $SUDO rm -rf "$APPDATA_PATH"

    # Store '.desktop' files containing "${BIN_PATH}/winapps" in an array, returning an empty array if no such files exist.
    readarray -t WINAPPS_DESKTOP_FILES < <(grep -l -d skip "${BIN_PATH}/winapps" "${APP_PATH}/"* 2>/dev/null || true)

    # Remove each '.desktop' file.
    for DESKTOP_FILE_PATH in "${WINAPPS_DESKTOP_FILES[@]}"; do
        # Trim leading and trailing whitespace from '.desktop' file path.
        DESKTOP_FILE_PATH=$(echo "$DESKTOP_FILE_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        # Extract the file name.
        DESKTOP_FILE_NAME=$(basename "$DESKTOP_FILE_PATH" | sed 's/\.[^.]*$//')

        # Print feedback.
        echo -n "Removing '.desktop' file for '${DESKTOP_FILE_NAME}'... "

        # Delete the file.
        $SUDO rm "$DESKTOP_FILE_PATH"

        # Print feedback.
        echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
    done

    # Store the paths of bash scripts calling 'WinApps' to launch specific applications in an array, returning an empty array if no such files exist.
    readarray -t WINAPPS_APP_BASH_SCRIPTS < <(grep -l -d skip "${BIN_PATH}/winapps" "${BIN_PATH}/"* 2>/dev/null || true)

    # Remove each bash script.
    for BASH_SCRIPT_PATH in "${WINAPPS_APP_BASH_SCRIPTS[@]}"; do
        # Trim leading and trailing whitespace from bash script path.
        BASH_SCRIPT_PATH=$(echo "$BASH_SCRIPT_PATH" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        # Extract the file name.
        BASH_SCRIPT_NAME=$(basename "$BASH_SCRIPT_PATH" | sed 's/\.[^.]*$//')

        # Print feedback.
        echo -n "Removing bash script for '${BASH_SCRIPT_NAME}'... "

        # Delete the file.
        $SUDO rm "$BASH_SCRIPT_PATH"

        # Print feedback.
        echo -e "${DONE_TEXT}Done!${CLEAR_TEXT}"
    done

    # Print caveats.
    echo -e "\n${INFO_TEXT}Please note that your WinApps configuration and the WinApps source code were not removed.${CLEAR_TEXT}"
    echo -e "${INFO_TEXT}You can remove these manually by running:${CLEAR_TEXT}"
    echo -e "${COMMAND_TEXT}rm -r $(dirname "$CONFIG_PATH")${CLEAR_TEXT}"
    echo -e "${COMMAND_TEXT}rm -r ${SOURCE_PATH}${CLEAR_TEXT}\n"

    # Print feedback.
    echo -e "${SUCCESS_TEXT}UNINSTALLATION COMPLETE.${CLEAR_TEXT}"
}

# Name: 'waAddApps'
# Role: Adds new applications to an existing WinApps installation.
function waAddApps() {
    # Print feedback.
    echo -e "${BOLD_TEXT}Adding new applications to existing WinApps installation.${CLEAR_TEXT}"

    # Load the WinApps configuration file.
    waLoadConfig

    # Check for missing dependencies.
    waCheckInstallDependencies

    # Update $RDP_SCALE.
    waFixScale

    # If using 'docker' or 'podman', set RDP_IP to localhost.
    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        RDP_IP="$DOCKER_IP"
    fi

    # If using podman backend, modify the FreeRDP command to enter a new namespace.
    if [ "$WAFLAVOR" = "podman" ]; then
        FREERDP_COMMAND="podman unshare --rootless-netns ${FREERDP_COMMAND}"
    fi

    if [ "$WAFLAVOR" = "docker" ] || [ "$WAFLAVOR" = "podman" ]; then
        # Check if Windows is powered on.
        waCheckContainerRunning
    elif [ "$WAFLAVOR" = "libvirt" ]; then
        # Verify the current user's group membership.
        waCheckGroupMembership

        # Check if the Windows VM is powered on.
        waCheckVMRunning
    elif [ "$WAFLAVOR" = "manual" ]; then
        waCheckPortOpen
    else
        # Display the error type.
        echo -e "${ERROR_TEXT}ERROR:${CLEAR_TEXT} ${BOLD_TEXT}INVALID WINAPPS BACKEND.${CLEAR_TEXT}"

        # Display the error details.
        echo -e "${INFO_TEXT}An invalid WinApps backend '${WAFLAVOR}' was specified.${CLEAR_TEXT}"

        # Display the suggested action(s).
        echo "--------------------------------------------------------------------------------"
        echo -e "Please ensure 'WAFLAVOR' is set to 'docker', 'podman' or 'libvirt' in ${COMMAND_TEXT}${CONFIG_PATH}${CLEAR_TEXT}."
        echo "--------------------------------------------------------------------------------"

        # Terminate the script.
        return "$EC_INVALID_FLAVOR"
    fi

    # Check if the RDP port on Windows is open.
    waCheckPortOpen

    # Test RDP access to Windows.
    waCheckRDPAccess

    # Check for installed applications.
    waFindInstalled

    # Configure officially supported applications.
    waConfigureApps

    # Configure other detected applications.
    waConfigureDetectedApps
    # Print feedback.
    echo -e "${SUCCESS_TEXT}ADDING NEW APPS COMPLETE.${CLEAR_TEXT}"
}



### SEQUENTIAL LOGIC ###
# Welcome the user.
echo -e "${BOLD_TEXT}\
################################################################################
#                                                                              #
#                            WinApps Install Wizard                            #
#                                                                              #
################################################################################
${CLEAR_TEXT}"

# Check dependencies for the script.
waCheckScriptDependencies

# Source the contents of 'inquirer.sh'.
waGetInquirer

# Sanitise and parse the user input.
waCheckInput "$@"

# Configure paths and permissions.
waConfigurePathsAndPermissions

# Run diagnostic mode and exit.
if [ "$OPT_DIAG" -eq 1 ]; then
    waDiagnoseRDPDrive
    exit $?
fi

# Run interactive RDP starter mode and exit.
if [ "$OPT_START_RDP" -eq 1 ]; then
    waStartRDPSession
    exit $?
fi

# Get the source code
if [ "$OPT_UNINSTALL" -eq 0 ]; then
    waGetSourceCode
fi
# Install or uninstall WinApps.
if [ "$OPT_UNINSTALL" -eq 1 ]; then
    waUninstall
elif [ "$OPT_ADD_APPS" -eq 1 ]; then
    waAddApps
else
    waInstall
fi

exit 0
