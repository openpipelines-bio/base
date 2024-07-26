#!/bin/bash

## VIASH START
## VIASH END

[[ "$par_write_a" == "false" ]] && unset par_write_a
[[ "$par_write_b" == "false" ]] && unset par_write_b
[[ "$par_left_outer_join" == "false" ]] && unset par_left_outer_join
[[ "$par_write_overlap" == "false" ]] && unset par_write_overlap
[[ "$par_write_overlap_plus" == "false" ]] && unset par_write_overlap_plus
[[ "$par_report_A_if_no_overlap" == "false" ]] && unset par_report_A_if_no_overlap
[[ "$par_number_of_overlaps_A" == "false" ]] && unset par_number_of_overlaps_A
[[ "$par_report_no_overlaps_A" == "false" ]] && unset par_report_no_overlaps_A
[[ "$par_uncompressed_bam" == "false" ]] && unset par_uncompressed_bam
[[ "$par_same_strand" == "false" ]] && unset par_same_strand
[[ "$par_opposite_strand" == "false" ]] && unset par_opposite_strand
[[ "$par_reciprocal_overlap" == "false" ]] && unset par_reciprocal_overlap
[[ "$par_either_overlap" == "false" ]] && unset par_either_overlap
[[ "$par_split" == "false" ]] && unset par_split
[[ "$par_nonamecheck" == "false" ]] && unset par_nonamecheck
[[ "$par_sorted" == "false" ]] && unset par_sorted
[[ "$par_filenames" == "false" ]] && unset par_filenames
[[ "$par_sortout" == "false" ]] && unset par_sortout
[[ "$par_bed" == "false" ]] && unset par_bed
[[ "$par_header" == "false" ]] && unset par_header
[[ "$par_no_buffer_output" == "false" ]] && unset par_no_buffer_output

# Create input array 
IFS=";" read -ra input <<< $par_input_b

bedtools intersect \
    ${par_write_a:+-wa} \
    ${par_write_b:+-wb} \
    ${par_left_outer_join:+-loj} \
    ${par_write_overlap:+-wo} \
    ${par_write_overlap_plus:+-wao} \
    ${par_report_A_if_no_overlap:+-u} \
    ${par_number_of_overlaps_A:+-c} \
    ${par_report_no_overlaps_A:+-v} \
    ${par_uncompressed_bam:+-ubam} \
    ${par_same_strand:+-s} \
    ${par_opposite_strand:+-S} \
    ${par_min_overlap_A:+-f "$par_min_overlap_A"} \
    ${par_min_overlap_B:+-F "$par_min_overlap_B"} \
    ${par_reciprocal_overlap:+-r} \
    ${par_either_overlap:+-e} \
    ${par_split:+-split} \
    ${par_genome:+-g "$par_genome"} \
    ${par_nonamecheck:+-nonamecheck} \
    ${par_sorted:+-sorted} \
    ${par_names:+-names "$par_names"} \
    ${par_filenames:+-filenames} \
    ${par_sortout:+-sortout} \
    ${par_bed:+-bed} \
    ${par_header:+-header} \
    ${par_no_buffer_output:+-nobuf} \
    ${par_io_buffer_size:+-iobuf "$par_io_buffer_size"} \
    -a "$par_input_a" \
    ${par_input_b:+ -b ${input[*]}} \
    > "$par_output"
    