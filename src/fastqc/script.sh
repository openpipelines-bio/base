#!/bin/bash

## VIASH START
## VIASH END

# exit on error
set -eo pipefail

# Check if both outputs are empty, at least one must be passed.
if [[ -z "$par_html" ]] && [[ -z "$par_zip" ]] && [[ -z "$par_summary" ]] && [[ -z "$par_data" ]]; then
  echo "Error: At least one of the output arguments (--html, --zip, --summary, and --data) must be passed."
  exit 1
fi

# unset flags
unset_if_false=(
  par_casava
  par_nano
  par_nofilter
  par_extract
  par_noextract
  par_nogroup
  par_quiet
)

for par in ${unset_if_false[@]}; do
    test_val="${!par}"
    [[ "$test_val" == "false" ]] && unset $par
done

tmpdir=$(mktemp -d "${meta_temp_dir}/${meta_name}-XXXXXXXX")
function clean_up {
  rm -rf "$tmpdir"
}
trap clean_up EXIT

# Create input array 
IFS=";" read -ra input <<< $par_input

# Run fastqc
fastqc \
  --extract \
  ${par_casava:+--casava} \
  ${par_nano:+--nano} \
  ${par_nofilter:+--nofilter} \
  ${par_nogroup:+--nogroup} \
  ${par_min_length:+--min_length "$par_min_length"} \
  ${par_format:+--format "$par_format"} \
  ${par_contaminants:+--contaminants "$par_contaminants"} \
  ${par_adapters:+--adapters "$par_adapters"} \
  ${par_limits:+--limits "$par_limits"} \
  ${par_kmers:+--kmers "$par_kmers"} \
  ${par_quiet:+--quiet} \
  ${meta_cpus:+--threads "$meta_cpus"} \
  ${meta_temp_dir:+--dir "$meta_temp_dir"} \
  --outdir "${tmpdir}" \
  "${input[@]}"
 
# Move output files
for file in "${input[@]}"; do
  # Removes everthing after the first dot of the basename
  sample_name=$(basename "${file}" | sed 's/\..*$//')
  if [[ -n "$par_html" ]]; then
    input_html="${tmpdir}/${sample_name}_fastqc.html"
    html_file="${par_html//\*/$sample_name}"
    mv "$input_html" "$html_file"
  fi
  if [[ -n "$par_zip" ]]; then
    input_zip="${tmpdir}/${sample_name}_fastqc.zip"
    zip_file="${par_zip//\*/$sample_name}"
    mv "$input_zip" "$zip_file"
  fi
  if [[ -n "$par_summary" ]]; then
    summary_file="${tmpdir}/${sample_name}_fastqc/summary.txt"
    new_summary="${par_summary//\*/$sample_name}"
    mv "$summary_file" "$new_summary"
  fi
  if [[ -n "$par_data" ]]; then
    data_file="${tmpdir}/${sample_name}_fastqc/fastqc_data.txt"
    new_data="${par_data//\*/$sample_name}"
    mv "$data_file" "$new_data"
  fi
  # Remove the extracted directory
  rm -r "${tmpdir}/${sample_name}_fastqc"
done

