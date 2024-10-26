#!/bin/bash

# clone repo
if [ ! -d /tmp/agat_source ]; then
  git clone --depth 1 --single-branch --branch master https://github.com/NBISweden/AGAT /tmp/agat_source
fi

# copy test data
cp -r /tmp/agat_source/t/scripts_output/in/1.gff src/agat/agat_sp_statistics/test_data
cp -r /tmp/agat_source/t/scripts_output/out/agat_sp_statistics_1.txt src/agat/agat_sp_statistics/test_data

# keep only the first 78 lines of 1.gff
head -n 78 src/agat/agat_sp_statistics/test_data/1.gff > src/agat/agat_sp_statistics/test_data/1.gff.tmp
mv src/agat/agat_sp_statistics/test_data/1.gff.tmp src/agat/agat_sp_statistics/test_data/1.gff