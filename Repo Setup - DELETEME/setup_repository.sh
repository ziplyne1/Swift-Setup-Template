#!/usr/bin/env bash

set -e

echo ""
echo "This script will ask you for a few parameters to fill out the template."
echo "Please ensure it is being run from inside the 'Repo Setup – DELETEME' directory."
echo "Note: this script uses macOS specific sed -i '' syntax."
echo ""

# --- Input ---
read -p "Package name (e.g. MojiPicker): " PACKAGENAME
read -p "GitHub username (e.g. ziplyne1): " GITHUBUSERNAME
read -p "Online username (e.g. ziplyne): " USERNAME
read -p "Personal website (e.g. https://ziplyne.dev): " PERSONALWEBSITE
read -p "Full name (e.g. Pax Willoughby): " FULLNAME
YEAR=$(date +%Y)


# --- Normalize ---
PACKAGENAME_SAFE=$(echo "$PACKAGENAME" | tr -d ' ')

escape() {
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

PACKAGENAME_SAFE_ESCAPED=$(escape "$PACKAGENAME_SAFE")
USERNAME_ESCAPED=$(escape "$USERNAME")
GITHUBUSERNAME_ESCAPED=$(escape "$GITHUBUSERNAME")
PERSONALWEBSITE_ESCAPED=$(escape "$PERSONALWEBSITE")
FULLNAME_ESCAPED=$(escape "$FULLNAME")


# --- Replace everywhere ---
echo ""
echo "Replacing global placeholders..."

echo "Replacing global placeholders..."

find .. -type f \
  ! -path "../.git/*" \
  ! -path "../Repo Setup - DELETEME/*" \
  -print0 | while IFS= read -r -d '' file; do
    sed -i '' \
      -e "s/__PACKAGENAME__/$PACKAGENAME_SAFE_ESCAPED/g" \
      -e "s/__USERNAME__/$USERNAME_ESCAPED/g" \
      -e "s/__GITHUBUSERNAME__/$GITHUBUSERNAME_ESCAPED/g" \
      -e "s|__PERSONALWEBSITE__|$PERSONALWEBSITE_ESCAPED|g" \
      "$file"
done
  
find .. -depth \
  ! -path "../.git/*" \
  -name "*__PACKAGENAME__*" -print0 | while IFS= read -r -d '' file; do
    new=$(echo "$file" | sed "s/__PACKAGENAME__/$PACKAGENAME_SAFE_ESCAPED/g")
    mkdir -p "$(dirname "$new")"
    mv "$file" "$new"
done


# --- Special: CODEOWNERS ---
if [ -f "../.github/CODEOWNERS" ]; then
  echo "Updating CODEOWNERS..."
  sed -i '' \
    -e "s/ziplyne1/$GITHUBUSERNAME_ESCAPED/g" \
    "../.github/CODEOWNERS"
fi


# --- Special: LICENSE ---
if [ -f "../LICENSE" ]; then
  echo "Updating LICENSE..."
  sed -i '' \
    -e "s/Pax Willoughby/$FULLNAME_ESCAPED/g" \
    -e "s/2026/$YEAR/g" \
    "../LICENSE"
fi

echo "Done."


# --- Remove git history ---
echo
read -p "Remove existing git history (.git folder)? (y/N): " confirm

if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  rm -rf ../.git
  echo "Removed .git directory."

  read -p "Initialize a new git repository? (y/N): " init_confirm
  if [[ "$init_confirm" == "y" || "$init_confirm" == "Y" ]]; then
    (cd .. && git init)
    echo "Initialized new git repository."
  fi
else
  echo "Skipped removing .git."
fi


# --- Prompt to run devsetup.sh ---
echo ""
echo "All done!"
echo "Your repository is now set up. Before building the demo app, please run devsetup.sh."
