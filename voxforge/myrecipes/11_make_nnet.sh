#!/bin/bash

source ./cmd.sh || exit 9;
source ./path.sh || exit 10;

nnet=./exp/nnet
gmm=./exp/gmm
sat=./exp/sat


acwt=0.001

for x in train test; do
    if [ ! -d $nnet/feats/$x ]; then
    	./steps/nnet/make_fmllr_feats.sh --nj $njobs --cmd "$train_cmd" \
        	--transform-dir $sat/model/decode \
        	$nnet/data/$x data/$x $gmm/model $nnet/log $nnet/feats/$x;
    fi
done

# Split dataset

./utils/subset_data_dir_tr_cv.sh $nnet/data/train $nnet/feats/tr90 $nnet/feats/cv10 ;

dbn=$nnet/dbn
./steps/nnet/pretrain_dbn.sh --rbm-iter 3 $nnet/data/train $dbn;

(tail --pid=$$ -F $nnet/log/train.log 2>/dev/null)&
$gpu_cmd $nnet/log/train.log \
	--feature_transform $dbn/final.feature_transform --dbn $dbn/6.dbn \
	--hid-layers 1 \
	--learn-rate 0.001 \
	$nnet/feats/tr90 $nnet/feats/cv10 \
	data/lang $gmm/align $gmm/align \
	$nnet/model;

./steps/nnet/decode.sh --nj $njobs --cmd "$decode_cmd" --config ./conf/decode_dnn.config \
	--acwt $acwt \
	$gmm/graph $nnet/feats/test $nnet/model/decode

./steps/nnet/align.sh --nj $njobs --cmd "$train_cmd" \
	$nnet/feats/train data/lang $nnet/model $nnet/align;

./steps/nnet/make_denlats.sh --nj $njobs --cmd "$train_cmd" --config conf/decode_dnn.config \
	--acwt $acwt \
	$nnet/feats/train data/lang $nnet/model $nnet/denlats;

./steps/nnet/train_mpe.sh --cmd "$gpu_cmd" --num-iters 5 --acwt $acwt --do-smbr true \
	$nnet/feats/train data/lang $nnet/model $nnet/align $nnet/denlats \
	$nnet/mpe;

for iter in 5 4 3 1; do
	steps/nnet/decode.sh --nj $njobs --cmd "$decode_cmd" --config ./conf/decode_dnn.config \
		--net $nnet/mpe/${iter}.nnet --acwt $acwt \
		$gmm/graph $nnet/feats/train $nnet/mpe/decode_${iter}
done


for x in $nnet/*/decode* ; do
	grep WER $x/*wer_* | ./utils/best_wer.sh > $nnet/best_wer.sh;
done


