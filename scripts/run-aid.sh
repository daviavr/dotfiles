#!/usr/bin/env bash


backend_path=~/nonblobs/work/clinicmanager/backend
backend="$backend_path/mvnw spring-boot:run -f $backend_path/pom.xml"

gbackend_path=~/nonblobs/work/general
gbackend="$gbackend_path/mvnw spring-boot:run -f $gbackend_path/pom.xml"

tmux new-session -ds run-backend $backend 
#tmux new-session -ds run-gbackend $gbackend 
