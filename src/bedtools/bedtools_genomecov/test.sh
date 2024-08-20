#!/bin/bash

# exit on error
set -eo pipefail

## VIASH START
meta_executable="target/executable/bedtools/bedtools_intersect/bedtools_intersect"
meta_resources_dir="src/bedtools/bedtools_intersect"
## VIASH END

# directory of the bam file
test_data="$meta_resources_dir/test_data"

#############################################
# helper functions
assert_file_exists() {
  [ -f "$1" ] || { echo "File '$1' does not exist" && exit 1; }
}
assert_file_not_empty() {
  [ -s "$1" ] || { echo "File '$1' is empty but shouldn't be" && exit 1; }
}
assert_file_contains() {
  grep -q "$2" "$1" || { echo "File '$1' does not contain '$2'" && exit 1; }
}
assert_identical_content() {
  diff -a "$2" "$1" \
    || (echo "Files are not identical!" && exit 1)
}
#############################################

# Create directories for tests
echo "Creating Test Data..."
TMPDIR=$(mktemp -d "$meta_temp_dir/XXXXXX")
function clean_up {
  [[ -d "$TMPDIR" ]] && rm -r "$TMPDIR"
}
trap clean_up EXIT

# Create and populate input files
printf "chr1\t248956422\nchr2\t198295559\nchr3\t242193529\n" > "$TMPDIR/genome.txt"
printf "chr2\t128\t228\tmy_read/1\t37\t+\nchr2\t428\t528\tmy_read/2\t37\t-\n" > "$TMPDIR/example.bed"
printf "chr2\t128\t228\tmy_read/1\t60\t+\t128\t228\t255,0,0\t1\t100\t0\nchr2\t428\t528\tmy_read/2\t60\t-\t428\t528\t255,0,0\t1\t100\t0\n" > "$TMPDIR/example.bed12"
printf "chr2\t100\t103\n" > "$TMPDIR/example_dz.bed"

# expected outputs
cat > "$TMPDIR/expected_default.bed" <<EOF
chr2	0	198295359	198295559	0.999999
chr2	1	200	198295559	1.0086e-06
chr1	0	248956422	248956422	1
chr3	0	242193529	242193529	1
genome	0	689445310	689445510	1
genome	1	200	689445510	2.90088e-07
EOF
cat > "$TMPDIR/expected_ibam.bed" <<EOF
chr2:172936693-172938111	0	1218	1418	0.858956
chr2:172936693-172938111	1	200	1418	0.141044
genome	0	1218	1418	0.858956
genome	1	200	1418	0.141044
EOF
cat > "$TMPDIR/expected_ibam_pc.bed" <<EOF
chr2:172936693-172938111	0	1018	1418	0.717913
chr2:172936693-172938111	1	400	1418	0.282087
genome	0	1018	1418	0.717913
genome	1	400	1418	0.282087
EOF
cat > "$TMPDIR/expected_ibam_fs.bed" <<EOF
chr2:172936693-172938111	0	1218	1418	0.858956
chr2:172936693-172938111	1	200	1418	0.141044
genome	0	1218	1418	0.858956
genome	1	200	1418	0.141044
EOF
cat > "$TMPDIR/expected_dz.bed" <<EOF
chr2	100	1
chr2	101	1
chr2	102	1
EOF
cat > "$TMPDIR/expected_strand.bed" <<EOF
chr2	0	198295459	198295559	1
chr2	1	100	198295559	5.04298e-07
chr1	0	248956422	248956422	1
chr3	0	242193529	242193529	1
genome	0	689445410	689445510	1
genome	1	100	689445510	1.45044e-07
EOF
cat > "$TMPDIR/expected_5.bed" <<EOF
chr2	0	198295557	198295559	1
chr2	1	2	198295559	1.0086e-08
chr1	0	248956422	248956422	1
chr3	0	242193529	242193529	1
genome	0	689445508	689445510	1
genome	1	2	689445510	2.90088e-09
EOF
cat > "$TMPDIR/expected_bg_scale.bed" <<EOF
chr2	128	228	100
chr2	428	528	100
EOF
cat > "$TMPDIR/expected_trackopts.bed" <<EOF
track type=bedGraph name=example llama=Alpaco
chr2	128	228	1
chr2	428	528	1
EOF
cat > "$TMPDIR/expected_split.bed" <<EOF
chr2	0	198295359	198295559	0.999999
chr2	1	200	198295559	1.0086e-06
chr1	0	248956422	248956422	1
chr3	0	242193529	242193529	1
genome	0	689445310	689445510	1
genome	1	200	689445510	2.90088e-07
EOF
cat > "$TMPDIR/expected_ignoreD_du.bed" <<EOF
chr2:172936693-172938111	0	1218	1418	0.858956
chr2:172936693-172938111	1	200	1418	0.141044
genome	0	1218	1418	0.858956
genome	1	200	1418	0.141044
EOF

# Test 1: 
mkdir "$TMPDIR/test1" && pushd "$TMPDIR/test1" > /dev/null

echo "> Run bedtools_genomecov on BED file"
"$meta_executable" \
  --input "../example.bed" \
  --genome "../genome.txt" \
  --output "output.bed"

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_default.bed"
echo "- test1 succeeded -"

popd > /dev/null

# Test 2: ibam option 
mkdir "$TMPDIR/test2" && pushd "$TMPDIR/test2" > /dev/null

echo "> Run bedtools_genomecov on BAM file with -ibam"
"$meta_executable" \
  --input_bam "$test_data/example.bam" \
  --output "output.bed" \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_ibam.bed"
echo "- test2 succeeded -"

popd > /dev/null

# Test 3: depth option
mkdir "$TMPDIR/test3" && pushd "$TMPDIR/test3" > /dev/null

echo "> Run bedtools_genomecov on BED file with -dz"
"$meta_executable" \
  --input "../example_dz.bed" \
  --genome "../genome.txt" \
  --output "output.bed" \
  --depth_zero

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_dz.bed"
echo "- test3 succeeded -"

popd > /dev/null

# Test 4: strand option
mkdir "$TMPDIR/test4" && pushd "$TMPDIR/test4" > /dev/null

echo "> Run bedtools_genomecov on BED file with -strand"
"$meta_executable" \
  --input "../example.bed" \
  --genome "../genome.txt" \
  --output "output.bed" \
  --strand "-" \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_strand.bed"
echo "- test4 succeeded -"

popd > /dev/null

# Test 5: 5' end option
mkdir "$TMPDIR/test5" && pushd "$TMPDIR/test5" > /dev/null

echo "> Run bedtools_genomecov on BED file with -5"
"$meta_executable" \
  --input "../example.bed" \
  --genome "../genome.txt" \
  --output "output.bed" \
  --five_prime \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_5.bed"
echo "- test5 succeeded -"

popd > /dev/null

# Test 6: max option
mkdir "$TMPDIR/test6" && pushd "$TMPDIR/test6" > /dev/null

echo "> Run bedtools_genomecov on BED file with -max"
"$meta_executable" \
  --input "../example.bed" \
  --genome "../genome.txt" \
  --output "output.bed" \
  --max 100 \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_default.bed"
echo "- test6 succeeded -"

popd > /dev/null

# Test 7: bedgraph and scale option
mkdir "$TMPDIR/test7" && pushd "$TMPDIR/test7" > /dev/null

echo "> Run bedtools_genomecov on BED file with -bg and -scale"
"$meta_executable" \
  --input "../example.bed" \
  --genome "../genome.txt" \
  --output "output.bed" \
  --bed_graph \
  --scale 100 \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_bg_scale.bed"
echo "- test7 succeeded -"

popd > /dev/null

# Test 8: trackopts option
mkdir "$TMPDIR/test8" && pushd "$TMPDIR/test8" > /dev/null

echo "> Run bedtools_genomecov on BED file with -bg and -trackopts"
"$meta_executable" \
  --input "../example.bed" \
  --genome "../genome.txt" \
  --output "output.bed" \
  --bed_graph \
  --trackopts "name=example" \
  --trackopts "llama=Alpaco" \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_trackopts.bed"
echo "- test8 succeeded -"

popd > /dev/null

# Test 9: ibam pc options
mkdir "$TMPDIR/test9" && pushd "$TMPDIR/test9" > /dev/null

echo "> Run bedtools_genomecov on BAM file with -ibam, -pc"
"$meta_executable" \
  --input_bam "$test_data/example.bam" \
  --output "output.bed" \
  --fragment_size \
  --pair_end_coverage \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_ibam_pc.bed"
echo "- test9 succeeded -"

popd > /dev/null

# Test 10: ibam fs options
mkdir "$TMPDIR/test10" && pushd "$TMPDIR/test10" > /dev/null

echo "> Run bedtools_genomecov on BAM file with -ibam, -fs"
"$meta_executable" \
  --input_bam "$test_data/example.bam" \
  --output "output.bed" \
  --fragment_size \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_ibam_fs.bed"
echo "- test10 succeeded -"

popd > /dev/null

# Test 11: split 
mkdir "$TMPDIR/test11" && pushd "$TMPDIR/test11" > /dev/null

echo "> Run bedtools_genomecov on BED12 file with -split"
"$meta_executable" \
  --input "../example.bed12" \
  --genome "../genome.txt" \
  --output "output.bed" \
  --split \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_split.bed"
echo "- test11 succeeded -"

popd > /dev/null

# Test 12: ignore deletion and du
mkdir "$TMPDIR/test12" && pushd "$TMPDIR/test12" > /dev/null

echo "> Run bedtools_genomecov on BAM file with -ignoreD and -du"
"$meta_executable" \
  --input_bam "$test_data/example.bam" \
  --output "output.bed" \
  --ignore_deletion \
  --du \

# checks
assert_file_exists "output.bed"
assert_file_not_empty "output.bed"
assert_identical_content "output.bed" "../expected_ignoreD_du.bed"
echo "- test12 succeeded -"

popd > /dev/null

echo "---- All tests succeeded! ----"
exit 0
