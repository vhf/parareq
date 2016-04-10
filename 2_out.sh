#!/bin/bash
:> ./output/0_excluded
:> ./output/1_tried
:> ./output/2_error
:> ./output/2_exception
:> ./output/2_good
:> ./output/3_log
tail -f ./output/2_* | pv -i10 -ltr >/dev/null
