./scripts/force-kill-delete-all-data.sh
./scripts/make.sh
./scripts/start.sh
echo 'sleeping before init db'
sleep 7
scripts/init_db.sh
docker-compose up -d bottledwater-avro
./scripts/plsql.sh
