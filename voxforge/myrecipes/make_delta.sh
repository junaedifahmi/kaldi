#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source ./utils/parse_options.sh || exit 3;


dir_exp=./exp/delta
dir_mono_ali=./exp/mono/align

gauss=5000
leaves=10000

if [ -d $dir_mono_ali ]; then
	./steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
		data/train data/lang exp/mono/model $dir_mono_ali;
fi

./steps/train_deltas.sh --cmd "$train_cmd" \
	$gauss $leaves \
	data/train data/lang \
	$dir_mono_ali $dir_exp/model;

echo "Bikin graph nya"

./utils/mkgraph.sh data/lang_test $dir_exp/model $dir_exp/graph;

./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	$dir_exp/graph data/test $dir_exp/model/decode

./steps/scoring_kaldi.sh data/test $dir_exp/graph $dir_exp/model/decode

for x in $dir_exp/*/decode*; do
	[ -d $x ] && grep WER $x/*wer_* | \
		./utils/best_wer.sh > $dir_exp/best_wer.txt;
done
