#!/usr/bin/env sh

NO_REPLICAS=${REPLICAS:-4}
HOST=${SERVICE:-"minio"}
VOLUME_PATH=${VOLUME:-"export"}

TASKS="tasks"
QUERY="${TASKS}.${HOST}"

echo "waiting for service discovery..."
until nslookup "${HOST}" ; do echo -n . ; sleep 1 ; done
echo

echo "waiting for all replicas to come online..."
NO_HOSTS=0
while [ "${NO_HOSTS}" -lt "${NO_REPLICAS}" ]
do
  OLD_HOSTS="${NO_HOSTS}"
  NO_HOSTS=$(nslookup "${QUERY}" | grep Address | wc -l)
  if [ "${OLD_HOSTS}" -ne "${NO_HOSTS}" ] ; then echo -n "${NO_HOSTS} " ; fi
  sleep 1
done

HOSTNAMES=$(nslookup "${QUERY}" | grep "Address" | awk '{ print $3 }' | sed -e 's/^/http:\/\//' | sed -e "s/$/\/${VOLUME_PATH}/" | tr '\n' ' ' | sed -e 's/[ \t]*$//')


if [ -f "/run/secrets/$MINIO_ACCESS_KEY_FILE" ]
then
  export MINIO_ACCESS_KEY=$(cat /run/secrets/$MINIO_ACCESS_KEY_FILE)
fi
if [ -f "/run/secrets/$MINIO_SECRET_KEY_FILE" ]
then
  export MINIO_SECRET_KEY=$(cat /run/secrets/$MINIO_SECRET_KEY_FILE)
fi

# start server
eval "minio server" "${HOSTNAMES}"
