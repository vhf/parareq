#!/bin/bash
MIX_ENV=prod mix compile
MIX_ENV=prod iex --erl "-smp enable +K true +P 524288" -S mix
