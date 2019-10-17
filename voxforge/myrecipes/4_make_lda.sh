#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source ./utils/parse_options.sh || exit 3;

dir_exp="./exp/lda"
dir_ali="./exp/ddelta"

gauss=12000
leaves=15000

if [ ! -d ${dir_ali}/align ]; then
	echo "Belum buat align for delta";
	./steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
		data/train data/lang $dir_ali/model $dir_ali/align; 
	exit 4;
fi

./steps/train_lda_mllt.sh --cmd "$train_cmd" \
	$gauss $leaves \
	data/train data/lang \
	$dir_ali/align \
	$dir_exp/model;

./utils/mkgraph.sh data/lang_test $dir_exp/model $dir_exp/graph;

./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	$dir_exp/graph data/test $dir_exp/model/decode

./steps/score_kaldi.sh data/test $dir_exp/graph $dir_exp/model/decode

for x in $dir_exp/*/decode*; do
	[ -d $x ] && grep WER $x/*wer_* | \
		./utils/best_wer.sh > $dir_exp/best_wer.txt;
done
