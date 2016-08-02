docker-compose ps | cut -f1 -d' ' | tail -n +3 | xargs | xargs docker rm -fv

