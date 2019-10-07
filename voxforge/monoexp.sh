#!/bin/bash

source ./path.sh || exit 9;
source ./cmd.sh || exit 9;

source utils/parse_options.sh || exit 9;

for x in 500 600 1000 1500 100; do
	./steps/train_mono.sh --nj $njobs --cmd "$train_cmd" --totgauss $x \
		data/train1.k data/lang exp/mono/$x/model
	./utils/mkgraph.sh data/lang_test exp/mono/$x/model exp/mono/$x/graph
	./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
		exp/mono/$x/graph data/test exp/mono/$x/model/decode
	./utils/best_wer.sh exp/mono/$x/model/decode

	for y in exp/mono/$/decode*; do
		[ -d $y ] && grep WER $y/wer_* | utils/best_wer.sh;
	done

	ln -sf exp/mono/$x/model/decode/scoring_kaldi/best_wer exp/mono/$x

echo "DONE"

