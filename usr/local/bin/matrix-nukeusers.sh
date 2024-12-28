#!/usr/bin/env bash
set -e -u

token=''
domain=''
username='matrix'
db='matrix'
file="$HOME/nukeusers.txt"

ban_dom='frontdomain.org rustyload.com'

for bd in $ban_dom
do
        query="select user_id from user_threepids where address ilike '%$bd' order by added_at"
        psql -q -U "$username" -d "$db" -c "\copy ($query) TO '$file.tmp'"
        cat "$file.tmp" >> "$file"; rm "$file.tmp"
done

nuke_user() {
        for user in $(cat nukeusers.txt)
        do
                curl --header "Authorization: Bearer $token" -X POST "https://$domain/_synapse/admin/v1/deactivate/$user"
                printf ' %s deactivated.\n' "$user"
        done
}

if [ -n "$file" ]; then
        while true; do
            read -p "Do you like to deactivate the user in nukeusers.txt? " ysn
            case $ysn in
                [Yy]* ) nuke_user; break;;
                [Ss]* ) less "$file"; break;;
                [Nn]* ) exit;;
                * ) printf 'Please answer with '"'y'"' (for yes) or '"'n'"' (for no). you can also use '"'s'"' to get a list of all users.\n\n';;
            esac
        done
        rm "$file"
else
        printf 'no entry in %s.\n' "$file"
fi

exit 0
