cd $MYSQL_HOME/mysql-test
./mtr --suite=cloud-test --extern socket=/tmp/mysql.sock --force --retry=0 --max-test-fail=100