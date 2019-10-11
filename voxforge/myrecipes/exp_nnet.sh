#!/bin/bash

source ./cmd.sh || exit 9;
source ./path.sh || exit 10;

dir_exp=./exp/nnet
dir_gmm=./exp/gmm
dir_fmllr=./exp/fmmlr_ali_gmm
awct=0.1


# Storing 40d pretained dbm

dir_feat=${dir_exp}/fmmlr_feats
./steps/nnet/make_fmllr_feats.sh --nj $njobs --cmd "$train_cmd" \
	--transform-dir $dir_gmm/model/decode \
	$dir_fmllr data/train $dir_gmm/model $dir_feat/log $dir_feat/train;

./steps/nnet/make_fmllr_feats.sh --nj $njobs --cmd "$train_cmd" \
	--transform-dir $dir_gmm/model/decode \
	$dir_fmllr data/test $dir_gmm/model $dir_feat/log $dir_feat/test;

# Split data to train test
utils/subset_data_dir_tr_cv.sh $dir_feat/train $dir_feat/tr90 $dir_feat/cv10 || exit 90;

# Get pretrained dbn
dir_dbn=${dir_exp}/pretrain_dbn
./steps/nnet/pretrain_dbn.sh --rbm-iter 2 $dir_fmllr $dir_dbn || exit 90;

## 

# Train the nnet
ft=${dir_dbn}/final.feature_transform
dbn=${dir_dbn}/6.dbn
(tail --pid=$$ -F $dir_exp/log/train.log 2>/dev/null)&

$gpu_cmd $dir_exp/log/train.log \
	./steps/nnet/train.sh --feature_transform $ft --dbn $dbn \
		--hid-layers 1 --learn-rate 0.001 \
		$dir_feat/tr90 $dir_feat/cv10 \
		data/lang $dir_gmm/align $dir_gmm/align \
		$dir_exp/model || exit 1;
./steps/nnet/decode.sh --nj $njobs --cmd "$decode_cmd" --config ./conf/decode_dnn.config \
	--acwt $awct \
	$dir_gmm/graph $dir_fmllr_feat/test $dir_exp/model/decode

# Get align and denlats from nnet model
./steps/nnet/align.sh --nj $njobs --cmd "$train_cmd" \
	$dir_feat/train data/lang $dir_exp/model $dir_exp/align;

./steps/nnet/make_denlats.sh --nj $njobs --cmd "$train_cmd" --config conf/decode_dnn/config \
	--acwt $awct \
	$dir_feat/train data/lang $dir_exp/model $dir_exp/denlats;



./steps/nnet/train_mpe.sh --cmd "$gpu_cmd" --num-iters 5 --acwt $awct --do-smbr true \
	$data_feat/train data/lang $dir_exp/model $dir_exp/align $dir_exp/denlats $dir_exp/mpe

for iter in 5 4 3 1; do
	steps/nnet/decode.sh --nj $njobs --cmd "$decode_cmd" --config ./conf/decode_dnn.config \
		--net $dir_exp/mpe/${iter}.nnet --acwt $awct \
		$dir_gmm/graph $dir_feat/test $dir_exp/mpe/decode_${iter}
