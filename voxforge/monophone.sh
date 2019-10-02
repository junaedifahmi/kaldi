#!/bin/bash

# This file is to run monotraining with voxforge dataset
# This code only run with assumption that all data preparation had been done before, this proces include the 
# data/lang preparation and phonetic preparation.


# Load additional environtments
. ./path.sh || exit 1
. ./cmd.sh || exit 1


#define how much jobs/cmd to execute, the more the faster,

njobs=72


# Training models
./utils/subset_data_dir.sh data/train 1000 data/train.1k || {echo "problem with making subset" && exit 1;}
./steps/train_mono.sh --nj $njobs --cmd "$train_cmd" data/train.1k data/lang exp/mono/model || \
	{echo "problem with training" && exit 1};

# Decoding models, this mean making graph and testing the model we have made with process before
## Making model
./utils/mkgraph.sh data/lang_test exp/mono/model exp/mono/graph || echo "problem with making graph" && exit 1;
	
## Decode and testing the model, 
./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	exp/mono/graph data/test exp/mono/decode

## Get best wer 
./utils/best_wer.sh exp/mono/decode

# Get model aligned
./steps/align_si.sh --nj $njobs --cmd "$train_cmd" data/train data/lang exp/mono/model exp/mono/mono_ali || \
	echo "problem with alignment" && exit 1;

echo "done training for monophone"

