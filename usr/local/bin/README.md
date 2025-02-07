**some useful aliases:**

get a list of all rooms:
```bash
matrix-show_rooms() {
        curl -s --header "Authorization: Bearer $token" -X GET 'https://matrix.envs.net/_synapse/admin/v1/rooms?order_by=state_events&limit=1000000' | jq -Mr . > ~/rooms.txt && nano ~/rooms.txt
}
```

get a list of all users:
```bash
matrix-show_users() {
        curl -s --header "Authorization: Bearer $token" -X GET 'https://matrix.envs.net/_synapse/admin/v2/users?from=0&limit=100000&guests=false' | jq -Mr . > ~/users.txt && nano ~/users.txt
}
```

deactivate a list of user_ids:
```bash
matrix-deactivate-users() {
        while read i; do
        printf '%s\n' "$i"; \
        curl -s --header "Authorization: Bearer $token" -X POST 'https://matrix.envs.net/_synapse/admin/v1/deactivate/'"$i" -d '{"erase": true}'; printf '\n'; done < ~/deactivate_users.txt
}
```

purge and block a list of room_ids:
```bash
matrix-purge-rooms() {
        while read i; do
        printf '%s\n' "$i"; \
        curl -s --header "Authorization: Bearer $token" -X DELETE 'https://matrix.envs.net/_synapse/admin/v1/rooms/'"$i" -d '{"purge": true, "block": true}'; printf '\n'; done < ~/purge_rooms.txt
}
```

get a list of all blocked room_ids:
```bash
matrix-get-blocked_rooms() {
        sudo -iu postgres psql -d matrix -c "SELECT room_id FROM blocked_rooms" > ~/blocked_rooms.tmp
        sed -i -e 's/ //' -e '1,2d' ~/blocked_rooms.tmp
        head -n -2 /root/blocked_rooms.tmp > ~/blocked_rooms.txt
        rm ~/blocked_rooms.tmp
}
```
