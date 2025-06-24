# PROGRAM test;
# USES
    source './env.sh'
# VAR
    DB_SQL='test.sql'
# BEGIN
    isql "$DB_PATH" $DB_AUTH -i "$DB_SQL"
# END.