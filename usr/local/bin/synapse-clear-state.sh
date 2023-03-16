#!/bin/sh
#
# you dont need to stop synapse.
#
# from: https://jo-so.de/2018-03/Matrix.html#state_groups_stateaufrumen
#
# this script used:
# https://github.com/matrix-org/rust-synapse-compress-state
#
## start task via:
# $ sudo systemd-run --nice=4 -pCPUSchedulingPolicy=batch \
#   -pIOSchedulingClass=idle --uid=matrix-synapse --collect \
#   --unit=synapse-clear-state ~/bin/synapse_clear_state
#
## watch task-log via:
# $ journalctl -Stoday -u synapse-clear-state -f
#

set -e -u

username='matrix'
db='matrix'
conn_str="host=localhost user=$username dbname=$db application_name=state_compress"

###

export RUST_BACKTRACE=short LC_ALL=C.UTF-8

if which time >/dev/null
then
        export TIME='%E elapsed %M rss'
        time=time
else
        time=
fi

cd "$(mktemp -d)"
echo "Writing SQL files to $PWD"

if [ $# -eq 0 ]
then
        set -- $(psql -X -t -A -U "$username" -c 'SELECT room_id FROM state_groups
          GROUP BY room_id ORDER BY count(*)' $db)
fi

echo 'Disabling autovacuum on state_groups_state'
psql -X -q -b -U "$username" -c 'alter table state_groups_state set (autovacuum_enabled = false);' $db

no=0
for room in $*
do
        echo '--------------------'
        echo

        sql_file=state-compress-$((no += 1)).sql
        echo "Writing SQL commands to $sql_file"

        $time synapse_compress_state -t -p "$conn_str" -o "$sql_file" -r "$room" -m 1000
        if test -s "$sql_file"
        then
                $time psql -X -q -b -U "$username" -c '\set ON_ERROR_STOP on' -f "$sql_file" $db
        else
                rm "$sql_file"
        fi
done

echo 'Enabling autovacuum on state_groups_state'
psql -X -q -b -U "$username" -c 'alter table state_groups_state set (autovacuum_enabled = true);' $db

echo 'Running VACUUM and ANALYZE for state_groups_state ...'
$time psql -X -q -b -U "$username" -c 'VACUUM FULL ANALYZE state_groups_state' $db

echo "All SQL scripts are in $PWD"

exit 0
