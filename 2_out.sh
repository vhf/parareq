#!/bin/bash
:> ./output/0_excluded
:> ./output/1_tried
:> ./output/2_error
:> ./output/2_exception
:> ./output/2_good
tail -f ./output/1_tried | pv -i5 -ltr >/dev/null
