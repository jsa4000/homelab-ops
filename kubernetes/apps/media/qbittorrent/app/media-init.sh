#!/bin/bash

ROOT_FOLDER=/downloads

FOLDERS=( "movies" "series" "music" "ebooks" "deleted" "tmp")

printf "Creating folder structure for media.\n"

for FOLDER in "${FOLDERS[@]}"; do
  printf "Creating folder: %s\n" $ROOT_FOLDER/$FOLDER
  mkdir -p $ROOT_FOLDER/$FOLDER
done

printf "Folders created.\n"
