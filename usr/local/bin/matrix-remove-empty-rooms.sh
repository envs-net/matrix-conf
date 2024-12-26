#!/usr/bin/env bash
# this script removed all room's without local members.
#

domain=''
token=''

print_usage() {
    printf '%s\n\n' "${0##*/}"
    printf 'usage:\n'
    printf '  -h    print this help\n'
    printf '  -d    domain\n'
    printf '  -t    token\n'
    printf 'example:\n'
    printf '  %s -d "domain.com" -t "token"\n' "${0##*/}"
    exit 1
}

while getopts ":d:t:h" opt "${@}"; do
    case $opt in
      d) domain="$OPTARG" ;;
      t) token="$OPTARG" ;;
      \?) printf 'Invalid option: -%s\n\n' "$OPTARG" ; print_usage ;;
      h|*) print_usage ;;
    esac
done

if [ -z "$domain" ] || [ "$domain" == '-t' ]; then print_usage; fi
if [ -z "$token" ] || [ "$token" == '-d' ]; then print_usage; fi

TOPURGE=$(curl -s -X GET -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d '{}' \
  'https://'"$domain"'/_synapse/admin/v1/rooms?limit=1000000' | jq -Mr '.rooms[] | select(.joined_local_members == 0) | .room_id')

for room in $TOPURGE
do
  printf 'processing room %s ..\n' "$room"
  curl -w "\nResponse code: %{response_code}\n\n" -s \
    -X DELETE \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{}' \
    'https://'"$domain"'/_synapse/admin/v1/rooms/'"$room"''
done

#
exit 0
