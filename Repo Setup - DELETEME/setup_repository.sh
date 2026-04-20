#!/bin/bash

# SETUP
set -e
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"


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
        echo "Input has a space in it which could cause unexpected bad things."
        echo "Do you want to continue? [y/N]"
        read ignore_space_warning
        if [[ ! "$ignore_space_warning" =~ ^[yY]$ ]]; then
            echo "Exiting..."
            exit 1
        fi
    fi
}

validate_url() {
    url="$1"
    
    if [[ ! $url =~ ^https?://[^[:space:]]+\.[^[:space:]]+$ ]]; then
        echo "Personal website URL is not valid"
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

rename_all() { # call like `rename_all old new`
    local old="$1"
    local new="$2"
    
    # Originally was checking if old and new match
    # I don't think that's necessary because it's checked below
    
    # Replace INSIDE files
    find_items f |
    while IFS= read -r -d '' file; do
        if ! grep -Iq '' "$file"; then
            # echo "Skipping binary: $file"
            continue
        fi
        perl -i -pe "s/\Q$old\E/$new/g" "$file"
    done
    
    
    # Replace FILE names
    find_items f |
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
    done
    
    
    # Replace DIRECTORY names
    find_items d |
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
    done
}


# ----------

# __PACKAGENAME__     -> Project name (preferable no spaces)
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
#echo "$PACKAGENAME"
read -p "GitHub username (e.g. ziplyne1): "             GITHUBUSERNAME;  GITHUBUSERNAME="${GITHUBUSERNAME:-ziplyne1}"
#echo "$GITHUBUSERNAME"
read -p "Online username (e.g. ziplyne): "              USERNAME;        USERNAME="${USERNAME:-ziplyne}"
#echo "$USERNAME"
read -p "Personal website (e.g. https://ziplyne.dev): " PERSONALWEBSITE; PERSONALWEBSITE="${PERSONALWEBSITE:-https://ziplyne.dev}"
#echo "$PERSONALWEBSITE"
read -p "Full name (e.g. Pax Willoughby): "             FULLNAME;        FULLNAME="${FULLNAME:-Pax Willoughby}"
#echo "$FULLNAME"
read -p "Copyright year (e.g. 2026): "                  YEAR;            YEAR="${YEAR:-2026}"
#echo "$YEAR"

validate_input "$PACKAGENAME"
validate_input "$GITHUBUSERNAME"
validate_input "$USERNAME"
validate_url   "$PERSONALWEBSITE"
validate_input "$FULLNAME" --suppress-space-warning
validate_input "$YEAR"

rename_all "__PACKAGENAME__"     "$PACKAGENAME"
rename_all "--PACKAGENAME--"     "$PACKAGENAME" # For stuff like bundle ids
rename_all "__GITHUBUSERNAME__"  "$GITHUBUSERNAME"
rename_all "__USERNAME__"        "$USERNAME"
rename_all "__PERSONALWEBSITE__" "$PERSONALWEBSITE"
rename_all "__FULLNAME__"        "$FULLNAME"
perl -i -pe "s/\Q2026\E/$YEAR/g" "$ROOT_DIR/LICENSE" # Year should only be replaced inside LICENSE

# ----------