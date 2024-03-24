#!/bin/bash

echo ">>> Testing $meta_functionality_name"

"$meta_executable" \
  --bam "$meta_resources_dir/test_data/a.bam" \
  --bai "$meta_resources_dir/test_data/a.bam.bai" \
  --output "$meta_resources_dir/test_data/a.flagstat"

echo ">>> Checking whether output exists"
[ ! -f "$meta_resources_dir/test_data/a.flagstat" ] && echo "File 'a.flagstat' does not exist!" && exit 1

echo ">>> Checking whether output is non-empty"
[ ! -s "$meta_resources_dir/test_data/a.flagstat" ] && echo "File 'a.flagstat' is empty!" && exit 1

echo ">>> Checking whether output is correct"
diff "$meta_resources_dir/test_data/a.flagstat" "$meta_resources_dir/test_data/a_ref.flagstat" || \
    (echo "Output file chr19.flagstat does not match expected output" && exit 1)

rm "$meta_resources_dir/test_data/a.flagstat"

################################################################################

echo 
echo "All tests succeeded!"
exit 0