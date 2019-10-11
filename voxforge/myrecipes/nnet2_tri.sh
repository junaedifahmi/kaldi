#!/bin/bash

# nnet from aligment from triphone

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

dir_base=./exp/nnet2
dir_sat=./exp/sat

if [ ! -d ${dir_sat} ]; then
	echo "belum training sat";
	exit 90;
fi



# Training Model
dir_exp=${dir_base}/pnorm

./steps/nnet2/train_pnorm_fast.sh --cmd "$gpu_cmd" \
	data/train data/lang ${dir_sat} \
	${dir_exp}/model

./steps/mkgraph.sh data/lang ${dir_exp}/model ${dir_exp}/graph

# Decode
./steps/nnet2/decode.sh --cmd "$decode_cmd" \
	${dir_exp}/graph
	data/test \
	${dir_exp}/model/decode

# Get best WER
for x in ${exp_dir}/decode*; do
	[ -d $x ] && grep WER $x/wer_* | \
		utils/best_wer.sh > ${exp_dir}/best_wer.txt;
done
