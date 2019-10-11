#!/bin/bash

source ./cmd.sh || exit 9;
source ./path.sh || exit 10;

nnet=./exp/nnet
gmm=./exp/gmm

for x in train test; do
    ./steps/nnet/make_fmllr_feats.sh --nj $njobs --cmd "$train_cmd" \
        --transform-dir $gmm/model/decode \
        $gmm/fmllr data/$x $gmm/model $nnet/log $nnet/feats/$x;
done

# Split dataset

./utils/subset_dir_tr_cv.sh $nnet/feats
