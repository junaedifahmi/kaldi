#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;
source parse_options.sh || exit 3;

sat=./exp/sat
nnet2=./exp/nnet2

if [ ! -d $sat ]; then
	echo "Belum ada sat nya bang,"
	exit 4;
fi

time ( ./steps/nnet2/train_pnorm_fast.sh --cmd "$gpu_cmd" \
    --num-epochs 2 \
	data/train data/lang $sat \
	$nnet2/model ) 2> train.time

./utils/mkgraph.sh data/lang_test $nnet2/model $nnet2/graph 

time ( ./steps/nnet2/decode.sh --cmd "$decode_cmd" \
	$nnet2/graph \
	data/test \
	$nnet2/model/decode ) 2> decode.time

for x in $nnet/*/decode* ; do
	grep WER $x/wer_* | utils/best_wer.sh > $nnet2/best_wer.txt;
done
