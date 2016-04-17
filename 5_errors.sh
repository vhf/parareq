wc -l output/1_tried
wc -l output/2_error
awk -F' ' 'NR>1{arr[$2]++}END{for (a in arr) print a, arr[a]}' output/2_error
