#!/usr/bin/env bash
#
# you dont need to stop synapse.
#

DOMAIN=''
TOKEN=''
file_rooms='/tmp/matrix_rooms.txt'
file_obsolet_rooms='/tmp/matrix_obsolet_rooms.txt'

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
jq -M '.rooms[] | .room_id' > $file_rooms
sed -i 's/"//g' $file_rooms

while IFS= read -r room_id
do
    curl -s -X GET -H "Authorization: Bearer $TOKEN" "https://$DOMAIN/_synapse/admin/v1/rooms/$room_id/state" | \
    jq -M '.state[] | select(.type == "m.room.tombstone") | .room_id' >> $file_obsolet_rooms
done < $file_rooms
sed -i 's/"//g' $file_obsolet_rooms

printf '\nobsolet rooms:\n'
cat $file_obsolet_rooms

#while IFS= read -r room_id
#do
#    printf 'remove room %s\n' "$room_id"
#    curl -s -X POST -H "Authorization: Bearer $TOKEN" "https://$DOMAIN/_synapse/admin/v1/rooms/$room_id/delete" \
#    -d "{ \"new_room_user_id\": \"@notices:$DOMAIN\", \"room_name\": \"Content Notification\", \"message\": \"remove obsolet room $room_id.\", \"block\": false, \"purge\": true, \"force-purge\": true }"
#    printf 'done.\n'
#done < $file_obsolet_rooms

rm $file_rooms $file_obsolet_rooms
#
exit 0
