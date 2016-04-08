#!/bin/bash
MIX_ENV=prod mix compile
MIX_ENV=prod iex --erl "-smp enable +K true +P 134217727" -S mix
