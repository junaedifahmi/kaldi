#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;
source parse_options.sh || exit 3;

sw=0.5
gauss=1500
sat=./exp/sat
ubm=./exp/ubm

steps/train_ubm.sh --silence-weight $sw --cmd "$train_cmd" $gauss \
	data/train data/lang $sat/fmllr \
	$ubm
