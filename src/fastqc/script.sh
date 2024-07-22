#!/bin/bash

## VIASH START
## VIASH END

# unset flags
[[ "$par_casava" == "false" ]] && unset par_casava
[[ "$par_nano" == "false" ]] && unset par_nano
[[ "$par_nofilter" == "false" ]] && unset par_nofilter
[[ "$par_extract" == "false" ]] && unset par_extract
[[ "$par_noextract" == "false" ]] && unset par_noextract
[[ "$par_nogroup" == "false" ]] && unset par_nogroup
[[ "$par_quiet" == "false" ]] && unset par_quiet

# Create input array 
IFS="," read -ra input <<< $par_input

run fastqc
fastqc \
  ${par_outdir:+--outdir "$par_outdir"} \
  ${par_casava:+--casava} \
  ${par_nano:+--nano} \
  ${par_nofilter:+--nofilter} \
  ${par_extract:+--extract} \
  ${par_java:+--java "$par_java"} \
  ${par_noextract:+--noextract} \
  ${par_nogroup:+--nogroup} \
  ${par_min_length:+--min_length "$par_min_length"} \
  ${par_format:+--format "$par_format"} \
  ${par_threads:+--threads "$par_threads"} \
  ${par_contaminants:+--contaminants "$par_contaminants"} \
  ${par_adapters:+--adapters "$par_adapters"} \
  ${par_limits:+--limits "$par_limits"} \
  ${par_kmers:+--kmers "$par_kmers"} \
  ${par_quiet:+--quiet} \
  ${par_dir:+--dir "$par_dir"} \
  ${par_input:+ ${input[*]}}

# input_dir=$(dirname ${input[1]})
# # Both outputs args passed
# if [[ -n "$par_html" ]] && [[ -n "$par_zip" ]]; then
#   IFS=',' read -r -a html_files <<< "$par_html"
#   IFS=',' read -r -a zip_files <<< "$par_zip"
#   for i in "${!input[@]}"; do
#     sample_name=$(basename ${input[$i]} .fq)
#     input_zip="$input_dir/${sample_name}_fastqc.zip"
#     input_html="$input_dir/${sample_name}_fastqc.html"
#     zip_file=${zip_files[$i]}
#     html_file=${html_files[$i]}
#     mv "$input_zip" "$zip_file"
#     mv "$input_html" "$html_file"
#   done
# # Only html output arg passed
# elif [[ -n "$par_html" ]]; then
#   IFS=',' read -r -a html_files <<< "$par_html"
#   for i in "${!input[@]}"; do
#     sample_name=$(basename ${input[$i]} .fq)
#     input_html="$input_dir/${sample_name}_fastqc.html"
#     html_file=${html_files[$i]}
#     mv "$input_html" "$html_file"
#   done
#   rm "$input_dir"/*.zip
# # Only zip output arg passed
# elif [[ -n "$par_zip" ]]; then
#   IFS=',' read -r -a zip_files <<< "$par_zip"
#   for i in "${!input[@]}"; do
#     sample_name=$(basename ${input[$i]} .fq)
#     input_zip="$input_dir/${sample_name}_fastqc.zip"
#     zip_file=${zip_files[$i]}
#     mv "$input_zip" "$zip_file"
#   done
#   rm "$input_dir"/*.html
# fi


# Questions:
# Should I unzip the zip file output and make multiple other outputs options for the viash component?
# TODO: handle the output args if multiple files are passed
# - if multiple files are passed, for the output args I can either change the config to multiple=false 
# and pass just a dir as argument and mv the files to this dir, 
# and would also work as well in the case of just one file passed (rename would be possible).
# i guess I can discuss this with jakub and see what he thinks is best
# because this is very similar to the -outdir flag of fastqc!

# Do I create a code for the multiple files case where I also rename the files to the output args?


#[[ -z "$par_java" ]] && unset par_java
#[[ "$par_min_length" == "false" ]] && unset par_min_length
#[[ "$par_format" == "false" ]] && unset par_format
#[[ "$par_threads" == "false" ]] && unset par_threads
#[[ "$par_contaminants" == "false" ]] && unset par_contaminants
#[[ "$par_adapters" == "false" ]] && unset par_adapters
#[[ "$par_limits" == "false" ]] && unset par_limits
#[[ "$par_kmers" == "false" ]] && unset par_kmers
