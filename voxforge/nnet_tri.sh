#!/bin/bash

# nnet from aligment from triphone

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

num_threads=10
num_hidden_layer=2
num_layer_dim=50
num_epoch=10
iter_per_epoch=2
init_lr=0.02
fin_lr=0.004
min_batch=20


exp_dir=exp/nnet/tri
# Training Model

./steps/nnet2/train_pnorm_simple.sh --config ./conf/nnet.config \
	data/train \
	data/lang \
	exp/tri/lda_mltt \
	${exp_dir}

# Decode
./steps/nnet2/decode.sh --config ./conf/nnet_decode.config \
	exp/tri/lda_mltt/graph \
	data/test \
	${exp_dir}/decode

# Get best WER
for x in ${exp_dir}/decode*; do
	[ -d $x ] && grep WER $x/wer_* | \
		utils/best_wer.sh > nnet2_simple_wer.txt;
done

echo "Done"
