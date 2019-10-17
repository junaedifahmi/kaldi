#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 1;

source parse_options.sh || exit 1;

dir_exp="./exp/ivector"
gauss=1500


# Train diagonal ubm first
./steps/online/nnet2/train_diag_ubm.sh --cmd "$train_cmd" --nj $njobs \
	data/train $gauss \
	${dir_exp}/dubm;

# Train ivector extractor

./steps/online/nnet2/train_ivector_extractor.sh --cmd "$train_cmd" --nj $njobs \
	data/train ${dir_exp}/dubm \
	${dir_exp}/extractor;

# Get iVector Features

./steps/nnet/ivector/extract_ivectors_online.sh \
	--cmd "$train_cmd" --nj $njobs \
	data/train ${dir_exp}/extractor \
	${dir_exp}/feats;
