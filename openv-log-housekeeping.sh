#!/usr/bin/ksh
#set -x

DISK_USAGE_THRESHOLD=70

USED=`df -h | awk '/\/usr\/openv/{ print $5 }' | sed s/%//`
LOG_FILES_COUNT_BEFORE=`ls -1 /usr/openv/logs/|awk 'END { print NR }'`
SIZE_BEFORE=`du -sh /usr/openv`
FILES2REMOVE_FILE="/tmp/openv-logs2remove"

# Disk usage below or equal to threshold => exit
if [[ $USED -lt $DISK_USAGE_THRESHOLD || $USED -eq $DISK_USAGE_THRESHOLD ]] ; then
	print "Disk usage for /usr/openv is below threshold ${DISK_USAGE_THRESHOLD} percent."
       	exit 0	
fi

################################################################
# Find log files for removal if disk usage > threshold 
################################################################
# perl onliner accord to http://www.linuxmisc.com/3-solaris/87bae91d1c2bef80.htm
# MAXTIME => seconds
# selects all files older then MAXTIME
ls -1 /usr/openv/logs/ | awk '{print "/usr/openv/logs/"$1}' | perl -e '$MAXTIME=21600; while(<>) { chomp; $mtime=(stat($_))[9];$age=time-$mtime;if ($age>=$MAXTIME) {print "$_\n"} }' > $FILES2REMOVE_FILE

# how many files have we found for removal?
LOGS2REMOVE=`cat $FILES2REMOVE_FILE | awk 'END { print NR }'`

# Below threshold but nothing to remove (no logs match)
if [[ $USED -gt $DISK_USAGE_THRESHOLD && $LOGS2REMOVE -eq 0 ]] ; then
	printf "Disk usage is ${USED} percent. No log files found for removal."  | /usr/bin/mailx -s "Housekeeping on XXX - High disk usage and nothing to remove to free disk space" pager@maillist.com
	exit 0
fi

# Start file removal
if [[ $USED -gt $DISK_USAGE_THRESHOLD && $LOGS2REMOVE -gt 0 ]] ; then
	echo "Start housekeeping as disk usage for /usr/openv reach the threshold is > ${DISK_USAGE_THRESHOLD}%"
	cat $FILES2REMOVE_FILE | awk '/\/usr\/openv\/logs/{ print }' | xargs -n 1 rm -f
	sleep 5
	USED_AFTER=`df -h|awk '/\/usr\/openv/{ print $5 }'|sed s/%//`
	LOG_FILES_COUNT_AFTER=`ls -1 /usr/openv/logs/|awk 'END { print NR }'`
	SIZE_AFTER=`du -sh /usr/openv`

	/usr/bin/mailx -s "Housekeeping ended on XXX" email@blabla.com << EOF
Stats
---------------------------------------
Number of log files before cleanup: $LOG_FILES_COUNT_BEFORE
Number of log files after  cleanup: $LOG_FILES_COUNT_AFTER
Number of files removed: $(( $LOG_FILES_COUNT_BEFORE - $LOG_FILES_COUNT_AFTER ))

Disk usage before cleanup: $USED%
Disk usage after  cleanup: $USED_AFTER%

Before: $SIZE_BEFORE
After : $SIZE_AFTER
EOF

else
	echo " Nothing to do? It's Wired ;-("
fi

exit 0

