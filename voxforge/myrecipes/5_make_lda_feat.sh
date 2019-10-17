#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source parse_options.sh || exit 3;

dir_model="./exp/lda"
boost=0.05

./steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
	data/train data/lang $dir_model/model $dir_model/align;

# Align Denlats
./steps/make_denlats.sh --nj $njobs --cmd "$train_cmd" \
	data/train data/lang $dir_model/model $dir_model/denlats


# Get mmi features
./steps/train_mmi.sh data/train data/lang \
	$dir_model/align $dir_model/denlats \
	$dir_model/mmi;

./steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
	$dir_model/graph data/test $dir_model/mmi/decode

# Get mmi features with boost
./steps/train_mmi.sh --boost $boost data/train data/lang \
	$dir_model/align $dir_model/denlats \
	$dir_model/mmi${boost};

./steps/decode.sh --config conf/decode.config --iter 4 nj $njobs --cmd "$decode_cmd" \
	$dir_model/graph data/test $dir_model/mmi${boost}


# Make MPE model
./steps/train_mpe.sh data/train data/lang \
	$dir_model/align $dir_model/denlats \
	$dir_model/mpe;

./steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
	$dir_model/graph data/test $dir_model/mpe/decode
