#!/bin/bash

## VIASH START
## VIASH END

agat_convert_sp_gff2tsv.pl \
  -f "$par_gff" \
  -o "$par_output" \
  ${par_config:+--config "${par_config}"}
