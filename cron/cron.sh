
datetime=$(date +"%Y-%m-%d")_$(date +"%I:%M:%S");
mysqldump -u root zm > /backup/zm_$datetime.sql
rm -rf /init/*.sql
cp /backup/zm_$datetime.sql /init/dump.sql;
find /backup/*.sql -type f -mtime +7 -exec rm -rf {} \;
