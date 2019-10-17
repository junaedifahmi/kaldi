#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 3;
source parse_options.sh || exit 3;

if [ ! -d ./exp/mono ]; then
	./myrecipes/1_make_mono.sh;
fi

if [ ! -d ./exp/delta ]; then
	./myrecipes/2_make_delta.sh;
fi


if [ ! -d ./exp/ddelta ]; then
	./myrecipes/3_make_ddelta.sh;
fi


if [ ! -d ./exp/lda ]; then
	./myrecipes/4_make_lda.sh;
	./myrecipes/5_make_lda_feats.sh;
fi


if [ ! -d ./exp/sat ]; then
	./myrecipes/6_make_sat.sh;
	./myrecipes/7_make_sat_feats.sh;
fi

if [ ! -d ./exp/dubm ]; then
	./myrecipes/8_make_dubm.sh;
fi

if [ ! -d ./exp/ubm ]; then
	./myrecipes/9_make_ubm.sh;
fi

if [ ! -d ./exp/gmm ]; then
	./myrecipes/10_make_gmm.sh;
fi

if [ ! -d ./exp/nnet ]; then
	./myrecipes/11_make_nnet.sh;
fi

if [ ! -d ./exp/nnet2 ]; then
	./myrecipes/12_make_nnet2.sh;
fi

if [ ! -d ./exp/ivector ]; then
    ./myrecipes/13_make_ivector.sh;
fi

if [ ! -d ./exp/nnet3 ]; then
	./myrecipes/14_make_nnet3.sh;
fi

if [ ! -d ./exp/chain ]; then
	./myrecipes/15_make_chain.sh;
fi

for x in exp/*/best_wer.txt ; do
    cat $x >> best_wer_all.txt;
done


