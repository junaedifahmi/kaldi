#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source ./utils/parse_options.sh || exit 3;

dir_exp="./exp/lda"
dir_ali="./exp/delta/align"

if [ ! -d ${dir_ali} ]; then
	echo "Belum buat align for delta";
	exit 4;
fi


gauss=2000
leaves=11000


./steps/train_lda_mllt.sh --cmd "$train_cmd" \
	$gauss $leaves \
	data/train data/lang \
	$dir_ali \
	$dir_exp/model;

./utils/mkgraph.sh data/lang_test $dir_exp/model $dir_exp/graph;

./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	$dir_exp/graph data/test $dir_exp/model/decode

./steps/scoring_kaldi.sh data/test $dir_exp/graph $dir_exp/model/decode

for x in $dir_exp/*/decode*; do
	[ -d $x ] && grep WER $x/*wer_* | \
		./utils/best_wer.sh > $dir_exp/best_wer.txt;
done
