#!/bin/bash

## VIASH START
## VIASH END

# Exit on error
set -eo pipefail

#test_data="$meta_resources_dir/test_data"

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

# Create test data
cat <<EOF > "$TMPDIR/example.vcf"
##fileformat=VCFv4.1
##contig=<ID=1,length=249250621,assembly=b37>
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE1
1	752567	llama	A	C	.	.	.	.	.
1	752722	.	G	A	.	.	.	.	.
EOF

bgzip -c $TMPDIR/example.vcf > $TMPDIR/example.vcf.gz
tabix -p vcf $TMPDIR/example.vcf.gz

cat <<EOF > "$TMPDIR/annots.tsv"
1	752567	752567	FooValue1	12345
1	752722	752722	FooValue2	67890
EOF

cat <<EOF > "$TMPDIR/rename.tsv"
INFO/.	Luigi
EOF

bgzip $TMPDIR/annots.tsv
tabix -s1 -b2 -e3 $TMPDIR/annots.tsv.gz

cat <<EOF > "$TMPDIR/header.hdr"
##FORMAT=<ID=FOO,Number=1,Type=String,Description="Some description">
##INFO=<ID=BAR,Number=1,Type=Integer,Description="Some description">
EOF

cat <<EOF > "$TMPDIR/rename_chrm.tsv"
1	chr1
2	chr2
EOF

# Test 1: Remove ID annotations
mkdir "$TMPDIR/test1" && pushd "$TMPDIR/test1" > /dev/null

echo "> Run bcftools_annotate remove annotations"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --remove "ID" \

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "1	752567	.	A	C"
echo "- test1 succeeded -"

popd > /dev/null

# Test 2: Annotate with -a, -c and -h options
mkdir "$TMPDIR/test2" && pushd "$TMPDIR/test2" > /dev/null

echo "> Run bcftools_annotate with -a, -c and -h options"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --annotations "../annots.tsv.gz" \
  --header_lines "../header.hdr" \
  --columns "CHROM,FROM,TO,FMT/FOO,BAR" \
  --mark_sites "BAR" \

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" $(echo -e "1\t752567\tllama\tA\tC\t.\t.\tBAR=12345\tFOO\tFooValue1")
echo "- test2 succeeded -"

popd > /dev/null

# Test 3: 
mkdir "$TMPDIR/test3" && pushd "$TMPDIR/test3" > /dev/null

echo "> Run bcftools_annotate with --set_id option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --set_id "+'%CHROM\_%POS\_%REF\_%FIRST_ALT'" \

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "'1_752722_G_A'"
echo "- test3 succeeded -"

popd > /dev/null

# Test 4:
mkdir "$TMPDIR/test4" && pushd "$TMPDIR/test4" > /dev/null

echo "> Run bcftools_annotate with --rename-annotations option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --rename_annotations "../rename.tsv"

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "##bcftools_annotateCommand=annotate --rename-annots ../rename.tsv -o annotated.vcf"
echo "- test4 succeeded -"

popd > /dev/null

# Test 5: Rename chromosomes
mkdir "$TMPDIR/test5" && pushd "$TMPDIR/test5" > /dev/null

echo "> Run bcftools_annotate with --rename-chromosomes option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --rename_chromosomes "../rename_chrm.tsv"

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "chr1"
echo "- test5 succeeded -"

popd > /dev/null

# Test 6: Sample option
mkdir "$TMPDIR/test6" && pushd "$TMPDIR/test6" > /dev/null

echo "> Run bcftools_annotate with -s option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --samples "SAMPLE1"

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "##bcftools_annotateCommand=annotate -s SAMPLE1 -o annotated.vcf ../example.vcf"
echo "- test6 succeeded -"

popd > /dev/null

# Test 7: Single overlaps
mkdir "$TMPDIR/test7" && pushd "$TMPDIR/test7" > /dev/null

echo "> Run bcftools_annotate with --single-overlaps option"	
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --single_overlaps \
  --keep_sites \

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "annotate -k --single-overlaps -o annotated.vcf ../example.vcf"
echo "- test7 succeeded -"

popd > /dev/null

# Test 8: Min overlap
mkdir "$TMPDIR/test8" && pushd "$TMPDIR/test8" > /dev/null

echo "> Run bcftools_annotate with --min-overlap option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --annotations "../annots.tsv.gz" \
  --columns "CHROM,FROM,TO,FMT/FOO,BAR" \
  --header_lines "../header.hdr" \
  --min_overlap "1"

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "annotate -a ../annots.tsv.gz -c CHROM,FROM,TO,FMT/FOO,BAR -h ../header.hdr --min-overlap 1 -o annotated.vcf ../example.vcf"
echo "- test8 succeeded -"

popd > /dev/null

# Test 9: Regions
mkdir "$TMPDIR/test9" && pushd "$TMPDIR/test9" > /dev/null

echo "> Run bcftools_annotate with -r option"
"$meta_executable" \
  --input "../example.vcf.gz" \
  --output "annotated.vcf" \
  --regions "1:752567-752722"

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "annotate -r 1:752567-752722 -o annotated.vcf ../example.vcf.gz"
echo "- test9 succeeded -"

popd > /dev/null

# Test 10: pair-logic
mkdir "$TMPDIR/test10" && pushd "$TMPDIR/test10" > /dev/null

echo "> Run bcftools_annotate with --pair-logic option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --pair_logic "all"

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "annotate --pair-logic all -o annotated.vcf ../example.vcf"
echo "- test10 succeeded -"

popd > /dev/null

# Test 11: regions-overlap
mkdir "$TMPDIR/test11" && pushd "$TMPDIR/test11" > /dev/null

echo "> Run bcftools_annotate with --regions-overlap option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --regions_overlap "1"

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "annotate --regions-overlap 1 -o annotated.vcf ../example.vcf"
echo "- test11 succeeded -"

popd > /dev/null

# Test 12: include 
mkdir "$TMPDIR/test12" && pushd "$TMPDIR/test12" > /dev/null

echo "> Run bcftools_annotate with -i option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --include "FILTER='PASS'" \

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "annotate -i FILTER='PASS' -o annotated.vcf ../example.vcf"
echo "- test12 succeeded -"

popd > /dev/null

# Test 13: exclude
mkdir "$TMPDIR/test13" && pushd "$TMPDIR/test13" > /dev/null

echo "> Run bcftools_annotate with -e option"
"$meta_executable" \
  --annotations "../annots.tsv.gz" \
  --input "../example.vcf" \
  --output "annotated.vcf" \
  --exclude "FILTER='PASS'" \
  --header_lines "../header.hdr" \
  --columns "CHROM,FROM,TO,FMT/FOO,BAR" \
  --merge_logic "FOO:first" \

# checks
assert_file_exists "annotated.vcf"
assert_file_not_empty "annotated.vcf"
assert_file_contains "annotated.vcf" "annotate -a ../annots.tsv.gz -c CHROM,FROM,TO,FMT/FOO,BAR -e FILTER='PASS' -h ../header.hdr -l FOO:first -o annotated.vcf ../example.vcf"
echo "- test13 succeeded -"

popd > /dev/null


echo "---- All tests succeeded! ----"
exit 0

