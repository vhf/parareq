#!/bin/bash
:> ./output/0_excluded
:> ./output/0_sec
:> ./output/1_tried
:> ./output/2_error
:> ./output/2_exception
:> ./output/2_good
tail -f 0_sec
