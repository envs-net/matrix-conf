# useful aliases

simple add it to your alias file.

**deps.:**
```
source "$HOME/.token" # contains $token
server='server.tld'
```

## get a list of all rooms

```bash
matrix-show_rooms() {
	curl -s -H "Authorization: Bearer $token" -X GET 'https://'"$server"'/_synapse/admin/v1/rooms?order_by=state_events&limit=1000000' | jq -Mr . > ~/rooms.txt && $EDITOR ~/rooms.txt
}
```

## get a list of all users

```bash
matrix-show_users() {
	curl -s -H "Authorization: Bearer $token" -X GET 'https://'"$server"'/_synapse/admin/v2/users?from=0&limit=100000&guests=false' | jq -Mr . > ~/users.txt && $EDITOR ~/users.txt
}
```

## deactivate a list of user_ids

```bash
matrix-deactivate-users() {
	while read i; do
		printf '%s\n' "$i"; \
		curl -s -H "Authorization: Bearer $token" -X POST 'https://'"$server"'/_synapse/admin/v1/deactivate/'"$i" -d '{"erase": true}'; printf '\n'
	done < ~/deactivate_users.txt
	echo > ~/deactivate_users.txt
}
```

## remove all rooms without local members

```bash
matrix-remove-empty-rooms() {
	TOPURGE=$(curl -s -H "Authorization: Bearer $token" -X GET \
	  'https://'"$server"'/_synapse/admin/v1/rooms?limit=1000000' | jq -Mr '.rooms[] | select(.joined_local_members == 0) | .room_id')

	for i in $TOPURGE; do
		printf 'processing room %s ..\n' "$i"
		curl -s -w "\nResponse code: %{response_code}\n" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -X DELETE -d '{}' \
		  'https://'"$server"'/_synapse/admin/v1/rooms/'"$i"''
	done
}
```

## purge and block a list of room_ids and also deactivate all local users in this rooms

```bash
matrix-purge-rooms() {
	echo > ~/blocked_members.txt
	while read i; do
		printf '%s\n' "$i"
		curl -s -H "Authorization: Bearer $token" -X GET 'https://'"$server"'/_synapse/admin/v1/rooms/'"$i"'/members' | jq -Mr .members[] >> ~/blocked_members.txt
		curl -s -H "Authorization: Bearer $token" -X DELETE 'https://'"$server"'/_synapse/admin/v1/rooms/'"$i" -d '{"purge": true, "block": true}'
		printf '\n'
	done < ~/purge_rooms.txt
	sed -i -e '/^$/d' ~/blocked_members.txt
	sort -u -o ~/blocked_members.txt{,}
	for i in $(grep "$server" ~/blocked_members.txt); do
		printf '%s\n' "$i"
		curl -s -H "Authorization: Bearer $token" -X POST 'https://'"$server"'/_synapse/admin/v1/deactivate/'"$i" -d '{"erase": true}'
	done
	sed -i '/'"$server"'/d' ~/blocked_members.txt
}
```

## get a list of all blocked room_ids

```bash
matrix-get-blocked_rooms() {
	sudo -iu postgres psql -d matrix -c "SELECT room_id FROM blocked_rooms" > ~/blocked_rooms.tmp
	sed -i -e 's/ //' -e '1,2d' ~/blocked_rooms.tmp
	head -n -2 ~/blocked_rooms.tmp > ~/blocked_rooms.txt
	rm ~/blocked_rooms.tmp
}
```
