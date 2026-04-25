#!/bin/bash

# SETUP
set -e
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RENAME_FUNCTION_CALL_COUNT=0
SCANNED_CONTENTS_COUNT=0
FILE_RENAME_COUNT=0
DIR_RENAME_COUNT=0

# FUNCTIONS
validate_input() { # call like `validate_input input --suppress-space-warning`
    local input="$1"
    local suppress_space_warning=false
    
    [[ "${2:-}" == "--suppress-space-warning" ]] && suppress_space_warning=true
    
    if [[ -z "$input" ]]; then
        echo "Input cannot be empty"
        exit 1
    fi
    
    if [[ "$input" == *[/\|\&\$\\]* ]]; then
        echo "Input cannot contain / | & \$ or \\"
        exit 1
    fi
    
    if [[ "$input" == *[[:space:]]* && "$suppress_space_warning" != true ]]; then
        local ignore_space_warning
        echo "Input has a space in it which could cause unexpected bad things."
        read -p "Do you want to continue? [y/N]: " ignore_space_warning
        if [[ ! "$ignore_space_warning" =~ ^[yY]$ ]]; then
            echo "Exiting..."
            exit 1
        fi
    fi
}

validate_url() { # call like `validate_url url`
    url="$1"
    
    if [[ "$url" == *[\|\&\$\\]* ]]; then
        echo "Personal website url cannot contain | & or \\"
        exit 1
    fi
    
    if [[ ! $url =~ ^https?://[^[:space:]]+\.[^[:space:]]+$ ]]; then
        echo "Personal website is not a valid URL"
        exit 1
    fi
}

find_items() { # call like `find_items f` or `find_items d`
    find "$ROOT_DIR" \
        -depth \
        -type "${1}" \
        -not -path "$SCRIPT_DIR" \
        -not -path "$SCRIPT_DIR/*" \
        -not -path "*/.git" \
        -not -path "*/.git/*" \
        -print0
}

escape_bundle_id() { # call like `escape_bundle_id "$PACKAGENAME"`
    local id="$1"
    local preserve_dots=false
    
    if [[ "$id" == *"."* ]]; then
        local preserve_dots_response
        read -p "Preserve dots in bundle identifier? ($id) [y/N]: " preserve_dots_response
        if [[ "$preserve_dots_response" =~ ^[yY]$ ]]; then
            preserve_dots=true
        fi
    fi

    if [[ "$preserve_dots" == true ]]; then
        echo "$id" | tr '_' '-' | tr -cd '[:alnum:].-'
    else
        echo "$id" | tr '_' '-' | tr -cd '[:alnum:]-'
    fi
}

rename_all() { # call like `rename_all old new`
    ((RENAME_FUNCTION_CALL_COUNT++))

    local old="$1"
    local new="$2"
    
    # Originally was checking if old and new match
    # I don't think that's necessary because it's checked below
    
    # Replace INSIDE files
    while IFS= read -r -d '' file; do
        if ! grep -Iq '' "$file"; then
            # echo "Skipping binary: $file"
            continue
        fi
        perl -i -pe "s|\Q$old\E|$new|g" "$file"
        ((SCANNED_CONTENTS_COUNT++))
    done < <(find_items f)
    
    
    # Replace FILE names
    while IFS= read -r -d '' file; do
        # echo ""
        # echo "Processing: $file"
        
        base="$(basename "$file")"
        parent="$(dirname "$file")"
        
        new_base="${base//$old/$new}"
        new_file="$parent/$new_base"
        
        # prevent edge-cases like if you had these two files
        # folder/new.txt
        # folder/old.txt
        # renaming old.txt to new.txt would overwrite new.txt
        if [[ -e "$new_file" ]]; then
            # echo "Skipping (target exists): $new_file"
            continue
        fi
        # prevent redundant renames
        if [[ "$file" == "$new_file" ]]; then
            # echo "Skipping (filename is the same): $new_file"
            continue
        fi
        
        mv "$file" "$new_file"
        # echo "Updated filename to $new_file"
        ((FILE_RENAME_COUNT++))
    done < <(find_items f)
    
    
    # Replace DIRECTORY names
    while IFS= read -r -d '' dir; do
        # echo ""
        # echo "Processing: $dir"
        
        base="$(basename "$dir")"
        parent="$(dirname "$dir")"
        
        new_base="${base//$old/$new}"
        new_dir="$parent/$new_base"
        
        # prevent edge-cases like if you had these two directories
        # folder/new
        # folder/old
        # renaming old.txt to new.txt would overwrite new.txt
        if [[ -e "$new_dir" ]]; then
            # echo "Skipping (target exists): $new_dir"
            continue
        fi
        # prevent redundant renames
        if [[ "$dir" == "$new_dir" ]]; then
            # echo "Skipping (filename is the same): $new_dir"
            continue
        fi
        
        mv "$dir" "$new_dir"
        # echo "Updated directory name to $new_dir"
        ((DIR_RENAME_COUNT++))
    done < <(find_items d)
}


# ----------

# __PACKAGENAME__     -> Project name (preferable no spaces)
# __ORGID__           -> Organization id (like com.ziplyne)
# __GITHUBUSERNAME__  -> GitHub-only
# __USERNAME__        -> Normal online handle
# __PERSONALWEBSITE__ -> like https://ziplyne.dev
# ziplyne1            -> __GITHUBUSERNAME__
# Pax Willoughby      -> Full name
# 2026                -> Copyright year

echo ""
echo "This script will ask for some values to be replaced inside all files, filenames, and directory names in the repo."
echo "Press enter for the example option."
echo ""

read -p "Package name (e.g. MojiPicker): "              PACKAGENAME;     PACKAGENAME="${PACKAGENAME:-MojiPicker}"
read -p "Organization identifier (e.g. com.ziplyne): "  ORGID;           ORGID="${ORGID:-com.ziplyne}"
read -p "GitHub username (e.g. ziplyne1): "             GITHUBUSERNAME;  GITHUBUSERNAME="${GITHUBUSERNAME:-ziplyne1}"
read -p "Online username (e.g. ziplyne): "              USERNAME;        USERNAME="${USERNAME:-ziplyne}"
read -p "Personal website (e.g. https://ziplyne.dev): " PERSONALWEBSITE; PERSONALWEBSITE="${PERSONALWEBSITE:-https://ziplyne.dev}"
read -p "Full name (e.g. Pax Willoughby): "             FULLNAME;        FULLNAME="${FULLNAME:-Pax Willoughby}"
read -p "Copyright year (e.g. 2026): "                  YEAR;            YEAR="${YEAR:-2026}"

validate_input "$PACKAGENAME"
validate_input "$ORGID"
validate_input "$GITHUBUSERNAME"
validate_input "$USERNAME"
validate_url   "$PERSONALWEBSITE"
validate_input "$FULLNAME" --suppress-space-warning
validate_input "$YEAR"

BUNDLE_SAFE_PACKAGENAME="$(escape_bundle_id "$PACKAGENAME")"

if [[ -z "$BUNDLE_SAFE_PACKAGENAME" || "$BUNDLE_SAFE_PACKAGENAME" == -* || "$BUNDLE_SAFE_PACKAGENAME" == *- ]]; then
    echo "Bundle-safe package name is invalid: '$BUNDLE_SAFE_PACKAGENAME'"
    exit 1
fi


rename_all "__PACKAGENAME__"     "$PACKAGENAME"
rename_all "--PACKAGENAME--"     "$BUNDLE_SAFE_PACKAGENAME"
rename_all "YOURORGANIZATIONID"  "$ORGID"
rename_all "__GITHUBUSERNAME__"  "$GITHUBUSERNAME"
rename_all "__USERNAME__"        "$USERNAME"
rename_all "__PERSONALWEBSITE__" "$PERSONALWEBSITE"
rename_all "__FULLNAME__"        "$FULLNAME"
perl -i -pe "s|\Q2026\E|$YEAR|g" "$ROOT_DIR/LICENSE" # Year should only be replaced inside LICENSE

echo ""
echo "Done!"
echo "File scans: $SCANNED_CONTENTS_COUNT"
echo "Unique scanned files: $(($SCANNED_CONTENTS_COUNT / $RENAME_FUNCTION_CALL_COUNT))"
echo "Files renamed: $FILE_RENAME_COUNT"
echo "Directories renamed: $DIR_RENAME_COUNT"
# ----------
