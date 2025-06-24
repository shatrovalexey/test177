# PROGRAM create;
# USES
    source './env.sh'
# VAR
    DB_CREATE='create.sql'
    DB_SQL=$(mktemp)
# BEGIN
    echo "CREATE DATABASE '$DB_PATH';" > "$DB_SQL"

    isql $DB_AUTH -i "$DB_SQL"
    rm "$DB_SQL"

    isql $DB_AUTH -i "$DB_CREATE"
# END.