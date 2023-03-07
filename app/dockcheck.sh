#!/usr/bin/env bash

### If not in PATH, set full path. Else just "regctl"
regbin="regctl"
### options to allow exclude:
while getopts "e:" options; do
  case "${options}" in
    e) Exclude=${OPTARG} ;;
    *) exit 0 ;;
  esac
done
shift "$((OPTIND-1))"
### Create array of excludes
IFS=',' read -r -a Excludes <<< "$Exclude" ; unset IFS

SearchName="$1"

for i in $(docker ps --filter "name=$SearchName" --format '{{.Names}}') ; do
  [[ " ${Excludes[*]} " =~ ${i} ]] && continue; # Skip if the container is excluded
  printf ". "
  RepoUrl=$(docker inspect "$i" --format='{{.Config.Image}}')
  LocalHash=$(docker image inspect "$RepoUrl" --format '{{.RepoDigests}}')
  ### Checking for errors while setting the variable:
  if RegHash=$($regbin image digest --list "$RepoUrl" 2>/dev/null) ; then
    if [[ "$LocalHash" = *"$RegHash"* ]] ; then NoUpdates+=("$i"); else GotUpdates+=("$i"); fi
  else
    GotErrors+=("$i")
  fi
done

### Sort arrays alphabetically
IFS=$'\n' 
NoUpdates=($(sort <<<"${NoUpdates[*]}"))
GotUpdates=($(sort <<<"${GotUpdates[*]}"))
GotErrors=($(sort <<<"${GotErrors[*]}"))
unset IFS

printf "%s\n" "${NoUpdates[@]}" > NoUpdates.txt
printf "%s\n" "${GotErrors[@]}" > GotErrors.txt
printf "%s\n" "${GotUpdates[@]}" > GotUpdates.txt