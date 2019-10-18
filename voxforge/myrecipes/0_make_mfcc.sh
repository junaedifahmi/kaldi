#!/bin/bash

# This code is used to prepare data from making lang data until mfcc

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

dialects="British"

nspk_test=20

lm_order=2

pos_dep_phones=true

selected=${DATA_ROOT}/selected

. utils/parse_options.sh || exit 1;

[[ $# -ge 1 ]] && { echo "Unexpected Args"; exit 1;}

local/voxforge_select.sh --dialect $dialects \
	${DATA_ROOT}/extracted ${selected} || exit 1;

local/voxforge_map_anonymous.sh ${selected} || exit 1;

local/voxforge_data_prep.sh --nspk_test ${nspk_test} ${selected} || exit 1;

local/voxforge_prepare_lm.sh --order ${lm_order} || exit 1;

local/voxforge_prepare_dict.sh || exit 1;

utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \
	data/local/dict '!SIL' data/local/lang data/lang || exit 1

local/voxforge_format_data.sh || exit 1;

mfccdir=${DATA_ROOT}/mfcc

for x in train test; do
	steps/make_mfcc.sh exp/make_mfcc/$x $mfccdir || exit 1;
	steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
done

