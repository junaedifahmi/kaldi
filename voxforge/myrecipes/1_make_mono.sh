#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source parse_options.sh || exit 3;

dir_exp=./exp/mono
dir_subset=./data/train.1k
subset=1000


if [ ! -d ${dir_subset} ]; then
	echo "Datanya kebanyakan, di reduce dulu ya";
	./utils/subset_data_dir.sh data/train $subset $dir_subset;
fi

echo "Training data dulu"

time ( ./steps/train_mono.sh --nj $njobs --cmd "$train_cmd" \
	$dir_subset data/lang \
	$dir_exp/model ) 2> $dir_exp/training.time

echo "Bikin graphnya"

./utils/mkgraph.sh data/lang_test ${dir_exp}/model ${dir_exp}/graph

echo "Decode model pake data test"

time ( ./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$train_cmd" \
	${dir_exp}/graph data/test ${dir_exp}/model/decode ) 2> $dir_exp/decode.time

for x in ${dir_exp}/*/decode*; do
	[ -d $x ] && \
		grep WER $x/wer_* | ./utils/best_wer.sh > ${dir_exp}/best_wer.txt ;
done

