#!/bin/bash

. ./cmd.sh || exit 1;
. ./path.sh || exit 1;
. ./utils/parse_options.sh || exit 1;

dir_base=/exp/tri/sat

dir_train=./data/train
dir_lang=./data/lang
dir_test=./data/test

dir_exp=./exp/nnet3/tri


#Training model
./steps/nnet3/train_tdnn.sh --config ./conf/nnet3.cfg \
	$dir_train $dir_lang $dir_base/align \
	$dir_exp/model

#Decode
./steps/nnet3/decode.sh --config ./conf/nnet3.decode \
	--use-gpu true \
	--cmd "$cmd_decode" \
	--nj $njobs \
	--transform-dir ${dir_base}/model/decode ${dir_base}/graph \
	${dir_test} \
	${dir_exp}/decode

# Compute WER
for x in ${dir_exp}/decode*; do
	[ -d $x ] && grep WER $x/wer_* | \
		utils/best-wer.sh > ${dir_exp}/best_wer.txt;
done

echo $(<$dir_exp/best_wer.txt)
