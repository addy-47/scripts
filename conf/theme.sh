#!/bin/bash
# ------------------------------------------------------------------
# Script to apply the custom color theme from your profile
# to a GNOME Terminal profile.
# ------------------------------------------------------------------

# INSTRUCTION: Replace this with your actual profile ID on the target machine.
# Find it with: dconf list /org/gnome/terminal/legacy/profiles:/
PROFILE_ID=":b1dcc9dd-5262-4d8d-a863-c897e6d979b9"

# --- Do not edit below this line ---
if [[ "$PROFILE_ID" == ":xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" ]]; then
    echo "ERROR: Please replace the placeholder PROFILE_ID in the script with your actual profile ID."
    exit 1
fi

PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/${PROFILE_ID}"

# Set the palette (16 colors)
dconf write "$PROFILE_PATH/palette" "[
'#000000', '#879993', '#d1d1d1', '#b9a8c8',
'#a570d2', '#54a4a7', '#27b78e', '#eee8d5',
'#73b0c0', '#b0bbb6', '#597f8b', '#657b83',
'#839496', '#d8239a', '#93a1a1', '#fdf6e3'
]"

# Set Text and Background Colors
dconf write "$PROFILE_PATH/foreground-color" "'#b3f7d8'"
dconf write "$PROFILE_PATH/background-color" "'#000000'"

# Set Bold and Cursor Colors
dconf write "$PROFILE_PATH/bold-color-same-as-fg" "false"
dconf write "$PROFILE_PATH/bold-color" "'#ffffff'"
dconf write "$PROFILE_PATH/cursor-background-color" "'#ffffff'"

# Set Highlight Colors
dconf write "$PROFILE_PATH/highlight-foreground-color" "'#fbfbfb'"
dconf write "$PROFILE_PATH/highlight-background-color" "'#000000'"

# Set Transparency (slider is at ~50%)
dconf write "$PROFILE_PATH/use-transparent-background" "true"
dconf write "$PROFILE_PATH/background-transparency-percent" "50"

# Set the profile name shown in preferences to "addy"
dconf write "$PROFILE_PATH/visible-name" "'addy'"

echo "✅ Success! The color theme has been applied to profile ${PROFILE_ID}."
echo "You may need to close and reopen your terminal to see all changes."
