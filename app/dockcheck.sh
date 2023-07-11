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
 for e in "${Excludes[@]}" ; do [[ "$i" == "$e" ]] && continue 2 ; done # Skip if the container is excluded
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

# ### Sort arrays alphabetically
IFS=$'\n'  
((${#NoUpdates[@]})) && NoUpdates=($(sort <<<"${NoUpdates[*]}"))
((${#GotErrors[@]})) && GotUpdates=($(sort <<<"${GotUpdates[*]}"))
((${#GotUpdates[@]})) && GotErrors=($(sort <<<"${GotErrors[*]}"))
unset IFS

((${#NoUpdates[@]})) && printf "%s\n" "${NoUpdates[@]}" > NoUpdates.txt || touch NoUpdates.txt
((${#GotErrors[@]})) && printf "%s\n" "${GotErrors[@]}" > GotErrors.txt || touch GotErrors.txt
((${#GotUpdates[@]})) && printf "%s\n" "${GotUpdates[@]}" > GotUpdates.txt || touch GotUpdates.txt
