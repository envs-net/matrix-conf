#!/usr/bin/env bash
#
# Before you execude the script better remove all rooms without local members.
# see script "matrix-remove-empty-rooms.sh".
#
# now you can run synapse_auto_compressor via:
#   synapse_auto_compressor -p "user=postgres dbname=matrix host=/var/run/postgresql" -c 500 -n 100
#
# for the first time on a HS with ~50.000 rooms you need to run the script round about 500 times:
#   for run in {1..500}; do sudo -u postgres synapse_auto_compressor -p "user=postgres dbname=matrix host=/var/run/postgresql" -c 500 -n 100; done
# you can see the already "initialized" rooms in the DB table "state_compressor_progress".
#
# after all rooms are processed you can run a:
#   REINDEX (VERBOSE) DATABASE CONCURRENTLY DATABASENAME
# to free your discspace.
#
###

# clean up synapse_auto_compressor state tables to prevent issue:
# https://github.com/matrix-org/rust-synapse-compress-state/issues/78.
#
# The compressor doesn't take into account
# - deleted rooms
# - state groups which got deleted either as unreferenced
#   or due to retention time
#
# Procedure:
# 1. Delete progress related to deleted rooms
# 2. Delete progress for rooms where one of the referenced state groups
#    no longer exist
# 3. Replicate changes from state_compressor_state to state_compressor_progress
# 4. run synapse_auto_compressor for 1 time or use $1

set -e -u -o pipefail

date="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

printf '[%s INFO  cleanup synapse_auto_compressor DB] Starting\n' "$date"
sudo -i -u postgres psql -d matrix <<_EOF
BEGIN;

DELETE
FROM state_compressor_state AS scs
WHERE NOT EXISTS
    (SELECT *
     FROM rooms AS r
     WHERE r.room_id = scs.room_id);

DELETE
FROM state_compressor_state AS scs
WHERE scs.room_id in
    (SELECT DISTINCT room_id
     FROM state_compressor_state AS scs2
     WHERE scs2.current_head IS NOT NULL
       AND NOT EXISTS
         (SELECT *
          FROM state_groups AS sg
          WHERE sg.id = scs2.current_head));

DELETE
FROM state_compressor_progress AS scp
WHERE NOT EXISTS
    (SELECT *
     FROM state_compressor_state AS scs
     WHERE scs.room_id = scp.room_id);

COMMIT;
_EOF
printf '[%s INFO  cleanup synapse_auto_compressor DB] Finished\n' "$date"

# compress state in synapse database
c="$1"
[[ "$c" == ?(-)+([0-9]) ]] || c='1'

run_synapse_auto_compressor() { sudo -u postgres synapse_auto_compressor -p "user=postgres dbname=matrix host=/var/run/postgresql" -c 500 -n 100; }

if [ "$c" -gt '1' ]; then
        printf '[%s INFO  synapse_auto_compressor] Starting for %s times\n' "$date" "$c"
        for ((i=1; i <= "$c"; i++)); do
                run_synapse_auto_compressor ; sleep 2
        done
else
        printf '[%s INFO  synapse_auto_compressor] Starting for 1 time\n' "$date"
        run_synapse_auto_compressor
fi
printf '[%s INFO  synapse_auto_compressor]" Finished\n' "$date"

exit 0
