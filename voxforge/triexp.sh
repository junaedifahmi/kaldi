#!/bin/bash

source ./path.sh || exit 9;
source ./cmd.sh || exit 9;

#Train delta

./steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
	data/train data/lang exp/mono/1500/model \
	exp/mono/1500/align


dir_base="exp/tri_delta"


for x in 1000 1500 2000 3000; do
	for y in 1500 2000 3000 4000; do
		./steps/train_deltas.sh --cmd "$train_cmd" \
			$x $y \
			data/train data/lang exp/mono/1500/align \
			${dir_base}/$x_$y/model;

		./utils/mkgraph.sh \
			data/lang_test ${dir_bae}/$x_$y/model \
			${dir_base}/$x_$y/graph;

		./steps/decode.sh --config ./conf/decode.config --nj $njobs --cmd "$decode_cmd" \
			${dir_base}/$x_$y/graph data/test \
			${dir_base}/$x_$y/model/decode;
	done
done
