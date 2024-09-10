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
##fileformat=VCFv4.0
##fileDate=20090805
##source=myImputationProgramV3.1
##reference=1000GenomesPilot-NCBI36
##contig=<ID=19,length=58617616>
##contig=<ID=20,length=58617616>
##phasing=partial
##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of Samples With Data">
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
##INFO=<ID=AC,Number=.,Type=Integer,Description="Allele count in genotypes, for each ALT allele, in the same order as listed">
##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">
##INFO=<ID=AF,Number=.,Type=Float,Description="Allele Frequency">
##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
##INFO=<ID=DB,Number=0,Type=Flag,Description="dbSNP membership, build 129">
##INFO=<ID=H2,Number=0,Type=Flag,Description="HapMap2 membership">
##FILTER=<ID=q10,Description="Quality below 10">
##FILTER=<ID=s50,Description="Less than 50% of samples have data">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=HQ,Number=2,Type=Integer,Description="Haplotype Quality">
##ALT=<ID=DEL:ME:ALU,Description="Deletion of ALU element">
##ALT=<ID=CNV,Description="Copy number variable region">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	NA00001	NA00002	NA00003
19	111	.	A	C	9.6	.	.	GT:HQ	0|0:10,10	0|0:10,10	0/1:3,3
19	112	.	A	G	10	.	.	GT:HQ	0|0:10,10	0|0:10,10	0/1:3,3
20	14370	rs6054257	G	A	29	PASS	NS=3;DP=14;AF=0.5;DB;H2	GT:GQ:DP:HQ	0|0:48:1:51,51	1|0:48:8:51,51	1/1:43:5:.,.
20	17330	.	T	A	3	q10	NS=3;DP=11;AF=0.017	GT:GQ:DP:HQ	0|0:49:3:58,50	0|1:3:5:65,3	0/0:41:3:.,.
20	1110696	rs6040355	A	G,T	67	PASS	NS=2;DP=10;AF=0.333,0.667;AA=T;DB	GT:GQ:DP:HQ	1|2:21:6:23,27	2|1:2:0:18,2	2/2:35:4:.,.
20	1230237	.	T	.	47	PASS	NS=3;DP=13;AA=T	GT:GQ:DP:HQ	0|0:54:.:56,60	0|0:48:4:51,51	0/0:61:2:.,.
20	1234567	microsat1	G	GA,GAC	50	PASS	NS=3;DP=9;AA=G;AN=6;AC=3,1	GT:GQ:DP	0/1:.:4	0/2:17:2	1/1:40:3
20	1235237	.	T	.	.	.	.	GT	0/0	0|0	./.
EOF

bgzip -c $TMPDIR/example.vcf > $TMPDIR/example.vcf.gz
tabix -p vcf $TMPDIR/example.vcf.gz

cat <<EOF > "$TMPDIR/exons.bed"
chr19	12345	12567
chr20	23456	23789
EOF

# Compressing and indexing the exons file
bgzip -c $TMPDIR/exons.bed > $TMPDIR/exons.bed.gz
tabix -s1 -b2 -e3 $TMPDIR/exons.bed.gz

# Create fai test file
# cat <<EOF > "$TMPDIR/reference.fasta.fai"
# 19	100	895464957	60	61
# 20	10000	1083893029	60	61
# EOF

# Create allele frequency bins file
cat <<EOF > "$TMPDIR/allele_frequency_bins.txt"
0.1
0.2
0.3
0.4
0.5
0.6
0.7
0.8
0.9
EOF

# Test 1: Default Use
mkdir "$TMPDIR/test1" && pushd "$TMPDIR/test1" > /dev/null

echo "> Run bcftools_stats on VCF file"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  ../example.vcf"
echo "- test1 succeeded -"

popd > /dev/null

# Test 2: First allele only
mkdir "$TMPDIR/test2" && pushd "$TMPDIR/test2" > /dev/null

echo "> Run bcftools_stats on VCF file with first allele only"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --first_allele_only \
  --allele_frequency_bins "0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9" \
  --allele_frequency_tag "AF" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  --1st-allele-only --af-bins 0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9 --af-tag AF ../example.vcf"
echo "- test2 succeeded -"

popd > /dev/null

# Test 3: Split by ID
mkdir "$TMPDIR/test3" && pushd "$TMPDIR/test3" > /dev/null

echo "> Run bcftools_stats on VCF file with split by ID"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --split_by_ID \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  --split-by-ID ../example.vcf"
echo "- test3 succeeded -"

popd > /dev/null

# Test 4: Collapse, Depth, Exclude
mkdir "$TMPDIR/test4" && pushd "$TMPDIR/test4" > /dev/null

echo "> Run bcftools_stats on VCF file with collapse, depth, and exclude"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --depth "0,500,1" \
  --exclude "GT='mis'" \
  --collapse "snps" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  -c snps -d 0,500,1 -e GT='mis' ../example.vcf"
echo "- test4 succeeded -"

popd > /dev/null

# Test 5: Exons, Apply Filters
mkdir "$TMPDIR/test5" && pushd "$TMPDIR/test5" > /dev/null

echo "> Run bcftools_stats on VCF file with exons, apply filters, and fasta reference"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --exons "../exons.bed.gz" \
  --apply_filters "PASS" \
#  --fasta_reference "../reference.fasta.fai" \

# NOTE: fasta_reference option not included in testing because of error from bcftools stats.

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  -E ../exons.bed.gz -f PASS ../example.vcf"
#assert_file_contains "stats.txt" "bcftools stats  -E ../exons.bed.gz -f PASS -F ../reference.fasta.fai ../example.vcf"
echo "- test5 succeeded -"

popd > /dev/null

# Test 6: Include, Regions
mkdir "$TMPDIR/test6" && pushd "$TMPDIR/test6" > /dev/null

echo "> Run bcftools_stats on VCF file with include and regions options"
"$meta_executable" \
  --input "../example.vcf.gz" \
  --output "stats.txt" \
  --include "GT='mis'" \
  --regions "20:1000000-2000000" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  -i GT='mis' -r 20:1000000-2000000 ../example.vcf.gz"
echo "- test6 succeeded -"

popd > /dev/null

# Test 7: Regions Overlap, Samples
mkdir "$TMPDIR/test7" && pushd "$TMPDIR/test7" > /dev/null

echo "> Run bcftools_stats on VCF file with regions overlap, and samples options"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --regions_overlap "record" \
  --samples "NA00001,NA00002" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  --regions-overlap record -s NA00001,NA00002 ../example.vcf"
echo "- test7 succeeded -"

popd > /dev/null

# Test 8: Targets, Targets File, Targets Overlaps
mkdir "$TMPDIR/test8" && pushd "$TMPDIR/test8" > /dev/null

echo "> Run bcftools_stats on VCF file with targets, targets file, and targets overlaps"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --targets "20:1000000-2000000" \
  --targets_overlaps "pos" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  -t 20:1000000-2000000 --targets-overlap pos ../example.vcf"
echo "- test8 succeeded -"

popd > /dev/null

# Test 9: User TSTV and Verbose
mkdir "$TMPDIR/test9" && pushd "$TMPDIR/test9" > /dev/null

echo "> Run bcftools_stats on VCF file with user TSTV and verbose"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --user_tstv "DP" \
  --verbose \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  --verbose -u DP ../example.vcf"
echo "- test9 succeeded -"

popd > /dev/null

# Test 10: Two vcf files
mkdir "$TMPDIR/test10" && pushd "$TMPDIR/test10" > /dev/null

echo "> Run bcftools_stats on two VCF files"
"$meta_executable" \
  --input "../example.vcf.gz" \
  --input "../example.vcf.gz" \
  --output "stats.txt" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  ../example.vcf.gz ../example.vcf.gz"
echo "- test10 succeeded -"

popd > /dev/null

# Test 11: with allele frequency bins file option
mkdir "$TMPDIR/test11" && pushd "$TMPDIR/test11" > /dev/null

echo "> Run bcftools_stats on VCF file with allele frequency bins file option"
"$meta_executable" \
  --input "../example.vcf" \
  --output "stats.txt" \
  --allele_frequency_bins "../allele_frequency_bins.txt" \

# checks
assert_file_exists "stats.txt"
assert_file_not_empty "stats.txt"
assert_file_contains "stats.txt" "bcftools stats  --af-bins ../allele_frequency_bins.txt ../example.vcf"
echo "- test11 succeeded -"

popd > /dev/null


echo "---- All tests succeeded! ----"
exit 0


