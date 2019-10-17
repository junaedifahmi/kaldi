#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 1;

source parse_options.sh || exit 1;

ubm=./exp/ubm
sat=./exp/sat
gmm=./exp/gmm

if [ ! -d $ubm ]; then
	echo "Train UBM dulu bung";
	exit 1;
fi

boost=0.15
gauss=8000
substates=19000


time ( ./steps/train_sgmm2.sh --cmd "$train_cmd" $gauss $substates \
	data/train data/lang $sat/fmllr $ubm \
	$gmm/model; ) 2> train.time

./utils/mkgraph.sh data/lang_test $gmm/model $gmm/graph;

time ( ./steps/decode_sgmm2.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	--transform-dir $sat/model/decode \
	$gmm/graph data/test $gmm/model/decode; ) 2> decode.time

./steps/align_sgmm2.sh --nj $njobs --cmd "$train_cmd" --transform-dir $sat/fmllr \
	--use-graphs true \
	--use-gselect true \
	data/train data/lang \
	$gmm/model \
	$gmm/align;


./steps/make_denlats_sgmm2.sh --nj $njobs --sub-split 20 --cmd "$decode_cmd" \
	--transform-dir $sat/fmllr \
	data/train data/lang $gmm/align \
	$gmm/denlats;

./steps/train_mmi_sgmm2.sh --cmd "$decode_cmd" --transform-dir $sat \
	--boost $boost \
	data/train data/lang \
	$gmm/align $gmm/denlats \
	$gmm/mmi;

for iter in {1..4}; do
	steps/decode_sgmm2_rescore.sh --cmd "$decode_cmd" --iter $iter \
		--transform-dir $sat/model/decode \
		data/lang data/test \
		$gmm/model/decode 


for x in $gmm/*/decode*; do
	[ -d $x ] && grep WER $x/wer_* | \
		./utils/best_wer.sh > $gmm/best_wer.txt;
done












