#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source parse_options.sh || exit 3;

dir_model="./exp/sat"
boost=0.05

echo "Align SI"

# ./steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
# 	data/train data/lang $dir_model/model $dir_model/align;

./steps/align_fmllr.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
	data/train data/lang $dir_model/model $dir_model/fmllr

# Align Denlats with fMllr
./steps/make_denlats.sh --nj $njobs --cmd "$train_cmd" \
	--transform-dir ${dir_model}/fmllr
	data/train data/lang $dir_model/model $dir_model/denlats;


# Get mmi features
./steps/train_mmi.sh data/train data/lang \
	$dir_model/fmllr $dir_model/denlats \
	$dir_model/mmi;

./steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	--alignment-model $dir_model/fmllr/final.alimdl \
	--adapt-model $dir_model/model/final.mdl \ 
	$dir_model/graph data/test $dir_model/mmi/decode_fmllr

./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	--transform-dir ${dir_model}/model/decode $dir_model/graph \
	data/test $dir_model/mmi/decode

