#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 3;
source parse_options.sh || exit 3;

if [ ! -d ./exp/mono ]; then
	./myrecipes/make_mono.sh;
fi

if [ ! -d ./exp/delta ]; then
	./myrecipes/make_delta.sh;
fi


if [ ! -d ./exp/ddelta ]; then
	./myrecipes/make_ddelta.sh;
fi


if [ ! -d ./exp/lda ]; then
	./myrecipes/make_lda.sh;
	./myrecipes/make_lda_feats.sh;
fi


if [ ! -d ./exp/sat ]; then
	./myrecipes/make_sat.sh;
	./myrecipes/make_sat_feats.sh;
fi

if [ ! -d ./exp/dubm ]; then
	./myrecipes/make_dubm.sh;
fi

if [ ! -d ./exp/ubm ]; then
	./myrecipes/make_ubm.sh;
fi

if [ ! -d ./exp/gmm ]; then
	./myrecipes/make_gmm.sh;
fi

if [ ! -d ./exp/nnet ]; then
	./myrecipes/make_nnet.sh;
fi

if [ ! -d ./exp/nnet2 ]; then
	./myrecipes/make_nnet2.sh;
fi

if [ ! -d ./exp/nnet3 ]; then
	./myrecipes/make_nnet3.sh;
fi

if [ ! -d ./exp/chain ]; then
	./myrecipes/make_chain.sh;
fi












