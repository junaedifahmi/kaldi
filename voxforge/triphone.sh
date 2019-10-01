#!/bin/bash


# This is a script to make triphone model, this file can be executed with the assumption that
# monophone model had been made before.

. ./path.sh || echo "problem with path.sh" && exit 1;
. ./cmd.sh || echo "problem with cmd.sh" && exit 1;


njobs=72


# Get Delta (tri1)
./steps/train_deltas.sh --cmd "$train_cmd" \
	2000 11000 \ 
	data/train \
	data/lang \
	exp/mono/align \
	exp/tri/delta/model || \
	echo "problem training delta" && exit 1;

## Decode tri1
./utils/mkgraph.sh \
	data/lang_test \
	exp/tri/delta/model \
	exp/tri/delta/graph || \
	echo "problem with mking graph" && exit 1;

./steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	exp/tri/delta/graph \
	data/test \
	exp/tri/delta/decode

## Alignment Delta
./steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
	data/train \
	data/lang \
	exp/tri/delta/model \
	exp/tri/delta/align || \
	echo "problem with aligment" && exit 1;

# Get Double Delta (tri2)
./steps/train_deltas.sh --cmd "$train_cmd" \
	2500 15000 \
	data/train \
	data/lang \
	exp/tri/delta/align \
	exp/tri/ddelta/model || \
	echo "problem with training double delta" && exit 1;
## Make graph
./utils/mkgraph.sh data/lang_test exp/tri/ddelta/model exp/tri/ddelta/graph
## Decode
./steps/decode.sh --config ./config/decode.config \
	--nj $njobs \
	--cmd "$decode_cmd" \
	exp/tri/ddelta/graph \
	data/test \
	exp/tri/ddelta/decode || \
	echo "problem with decode" && exit 1;
## Align ddelta
./steps/align_si.sh --nj $njobs \
	--cmd "$train_cmd" \
	--use-graphs true \
	data/train \
	data/lang \
	exp/tri/ddelta/model \
	exp/tri/ddelta/align

#Get LDA + MLLT
./steps/train_lda_mllt.sh --cmd "$train_cmd" \
	3500 20000 \
	data/train \
	data/lang \
	exp/tri/ddelta/align \
	exp/tri/lda_mllt/model || \
	echo "problem with training lda" && exit 1;
## Make graph
./utils/mkgraph.sh data/lang_test exp/tri/lda_mllt/model exp/tri/lda_mllt/graph || exit 1;
## Decode
./steps/decode.sh --config ./config/decode.config \
	--nj $njobs \
	--cmd "$decode_cmd" \
	exp/tri/lda_mllt/graph \
	data/test \
	exp/tri/lda_mllt/decode || \
	echo "problem with decode at lda+mllt" && exit 1;
## Align using fmllr
./steps/align_fmllr.sh --nj $njobs \
	--cmd "$train_cmd" \
	data/train \
	data/lang \
	exp/tri/lda_mllt/model \
	exp/tri/lda_mllt/align || \
	echo "problem at fmllr align lda+mllt" && exit 1;

# Get SAT
./steps/train_sat.sh --cmd "$train_cmd" \
	4200 40000 \
	data/train \
	data/lang \
	exp/tri/lda_mllt/align \
	exp/tri/sat/model || \
	echo "problem in training SAT" && exit 1;
# Make graphs
./utils/mkgraph.sh data/lang_test exp/tri/sat/model exp/tri/sat/graph || exit 2;
#Decode
./steps/decode.sh --config ./config/decode.config \
	--nj $njobs \
	--cmd "$decode_cmd" \
	exp/tri/sat/graph \
	exp/test \
	exp/tri/sat/decode || \
	echo "problem decode SAT" && exit 2;
## Alignment using fMLLR
./steps/align_fmllr.sh --nj $njobs \
	--cmd "$train_cmd" \
	data/lang \
	exp/tri/sat/model \
	exp/tri/sat/align || \
	echo "problem at align fmllr SAT" && exit 2;
