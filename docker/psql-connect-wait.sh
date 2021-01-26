#!/bin/sh

set -ue

usage() {
    echo "Usage: $(basename "$0") NAME PREFIX"
}

NAME="${1:-}"
PREFIX="${2:-}"

if [ -z "$NAME" ]; then
	usage
	echo "ERROR: missing NAME"
	exit 1
fi

if [ -z "$PREFIX" ]; then
	usage
	echo "ERROR: missing PREFIX"
	exit 1
fi

if ! hash psql > /dev/null 2>&1 ; then
	echo "WARNING: missing psql binary"
	exit 1
fi

eval DB_HOST="$""${PREFIX}_HOST"
eval DB_NAME="$""${PREFIX}_NAME"
eval DB_PASS="$""${PREFIX}_PASS"
eval DB_USER="$""${PREFIX}_USER"
eval DB_NAME="$""${PREFIX}_NAME"
eval DB_PORT="$""${PREFIX}_PORT"

echo "Waiting for PostgreSQL on $DB_HOST:$DB_PORT to become available..."
while ! PGPASSWORD="$DB_PASS" psql -U "$DB_USER" -h "$DB_HOST" "$DB_NAME" -c '\dt' >/dev/null 2>&1 ; do
    elapsed=$(( elapsed+1 ))
    if [ "$elapsed" -gt 120 ]; then
        echo "ERROR: connection timed out for $NAME on $HOST:$PORT!"
        exit 1
    fi
    sleep 1
done

sleep 5
echo "Service is ready for $NAME!"

