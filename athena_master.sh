#!/bin/bash
# SINGLE-INSTANCE Athena sweep runner.
# Takes an exclusive lock on .athena_sweep.lock; any second invocation (from any
# agent, human, or session) exits immediately instead of double-running.
cd /home/Drew/selfcorr-bench
exec 9>.athena_sweep.lock
flock -n 9 || { echo "$(date '+%F %T') LOCKED: another athena sweep is already running — exiting" >> athena_watch.log; exit 0; }
echo "$(date '+%F %T') lock acquired — launching 6 shards" >> athena_watch.log
for i in 1 2 3 4 5 6; do bash athena_x$i.sh & done
wait
echo "$(date '+%F %T') all shards exited — lock released" >> athena_watch.log
