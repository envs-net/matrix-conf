#!/usr/bin/env bash
#
# you dont need to stop synapse.
#

DOMAIN=''
TOKEN=''
tmp_file='/tmp/matrix_rooms_to_purge.txt'

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
      d) DOMAIN="$OPTARG" ;;
      t) TOKEN="$OPTARG" ;;
      \?) printf 'Invalid option: -%s\n\n' "$OPTARG" ; print_usage ;;
      h|*) print_usage ;;
    esac
done

if [ -z "$DOMAIN" ] || [ "$DOMAIN" == '-t' ]; then print_usage; fi
if [ -z "$TOKEN" ] || [ "$TOKEN" == '-d' ]; then print_usage; fi

curl -s -X GET -H "Authorization: Bearer $TOKEN" "https://$DOMAIN/_synapse/admin/v1/rooms?limit=10000" | \
jq -M '.rooms[] | select(.joined_local_members == 0) | .room_id' > $tmp_file
sed -i 's/"//g' $tmp_file

while IFS= read -r room_id
do
    printf 'remove room %s ' "$room_id"
    curl -s -X POST -H "Authorization: Bearer $TOKEN" "https://$DOMAIN/_synapse/admin/v1/purge_room" \
    -H "Content-Type: application/json" -d "{ \"room_id\": \"$room_id\" }"
    printf ' done.\n'
done < $tmp_file

rm $tmp_file
#
exit 0
