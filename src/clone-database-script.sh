#!/usr/bin/env bash

set -e
DB_DUMP_FILENAME="${1:-database-dump.sql}"  # If VARIABLE not set or null, set its value to 'default'. 
MARIADB_IMAGE="${2:-mariadb:10.11.7}"  # If VARIABLE not set or null, set its value to 'default'. 

gum log --level info "usage..."
gum log --level warn "variables are read from .env-file. please specify DB_DUMP_FILENAME and MARIADB_IMAGE"
gum log --level info "DB_DUMP_FILENAME is set to $DB_DUMP_FILENAME"
gum log --level info "MARIADB_IMAGE is set to $MARIADB_IMAGE" 





gum log --level info "checking prequesites..."
if docker info > /dev/null 2>&1; then
  gum log --level info "Docker Daemon is available"
else
  gum log --level info "Docker Daemon is not available. Please start Docker Daemon"
  exit 1
fi


gum log --level info "bootstrapping..."
grep $DB_DUMP_FILENAME .gitignore || echo $DB_DUMP_FILENAME >> .gitignore
gum log --level info "done"


gum log --level info "Selecting Cluster and Namespace and Pod and dump database using Docker-Container MariadDB"
SRC_CLUSTER=$(gum choose \
  --header "Choose the SRC cluster to connect to" \
  --cursor ">" \
  $(kubectl config get-contexts --no-headers=true -o name) CANCEL)

if [ "$SRC_CLUSTER" == "CANCEL" ] ; then
  gum log --level error "No cluster selected"
  exit 1
fi
gum log --level info "Selected cluster: $SRC_CLUSTER"
kubectx $SRC_CLUSTER
NAMESPACE_FILTER=$(gum input --placeholder "Choose the Namespace-Filter")
SRC_NAMESPACE=$(gum choose \
  --header "Choose the SRC namespace to connect to" \
  --cursor ">" \
  $(kubectl get namespace --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep $NAMESPACE_FILTER) CANCEL)
SRC_MARIADB_POD=$(gum choose \
  --header "Choose the MariaDB-Pod" \
  --cursor ">" \
  $(kubectl --namespace $SRC_NAMESPACE get pods -o name | grep mariadb) CANCEL) 

if [ "$SRC_NAMESPACE" == "CANCEL" ] ; then
  gum log --level error "No namespace selected"
  exit 1
fi
gum log --level info "Selected Namespace: $SRC_NAMESPACE"

SRC_DATABASE_NAME=$(kubectl get secret database --namespace $SRC_NAMESPACE  -o jsonpath='{.data.DATABASE_NAME}' | base64 -d)
SRC_DATABASE_USER=$(kubectl  get secret database --namespace $SRC_NAMESPACE -o jsonpath='{.data.DATABASE_USER}' | base64 -d)
SRC_DATABASE_PASSWORD=$(kubectl  get secret database --namespace $SRC_NAMESPACE -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d)

gum log --level info "SRC mariadb pod: $SRC_MARIADB_POD"
gum log --level info "SRC mariadb name: $SRC_DATABASE_NAME"
gum log --level info "SRC mariadb user: $SRC_DATABASE_USER"
gum log --level info "SRC mariadb password: $SRC_DATABASE_PASSWORD"

localport=3306
remoteport=3306

kubectl port-forward --namespace $SRC_NAMESPACE $SRC_MARIADB_POD $localport:$remoteport > /dev/null 2>&1 &

while ! nc -vz localhost $localport > /dev/null 2>&1 ; do
    gum log --level info "waiting for tunnel to be established: $pid"
    sleep 0.1
done

pid=$!
gum log --level info  "pid of kubect-port-forward: $pid"

trap '{
    kill $pid
}' EXIT

while ! nc -vz localhost $localport > /dev/null 2>&1 ; do
    gum log --level info "waiting for tunnel to be established: $pid"
    sleep 0.1
done

START=$(gum choose \
  --header "Ready to dump database? This can take some time" \
  --cursor ">" OK CANCEL) 

if [ "$START" == "CANCEL" ] ; then
  gum log --level info "Aborting database dump"
  exit 0
fi

docker run --rm $MARIADB_IMAGE mariadb-admin --host host.docker.internal -u $SRC_DATABASE_USER -p$SRC_DATABASE_PASSWORD status 

gum log --level info "Dumping database $SRC_DATABASE_NAME from pod $SRC_MARIADB_POD to $DB_DUMP_FILENAME"

gum spin --spinner dot --title "mariadb dump" -- docker run --rm $MARIADB_IMAGE mariadb-dump  --host host.docker.internal -u $SRC_DATABASE_USER -p$SRC_DATABASE_PASSWORD $SRC_DATABASE_NAME > $DB_DUMP_FILENAME

gum log --level info "Copy Database to sql-scripts-dir"

\cp -f $DB_DUMP_FILENAME ./eventDataBase/sql-scripts/00-baseline-dump.sql
