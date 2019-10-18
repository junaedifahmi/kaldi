#!/bin/bash

source ./cmd.sh
source ./path.sh

nnet3=./exp/nnet3

#### MAKE MFCC with 40 feats ####

data10k=./data/train.10k
mfcc10k=./data/mfcc.10k
cmvn10k=./data/cmvn.10k

ivector10k=./exp/ivector.10k


if [ ! -d $data10k ]; then
	./utils/subset_data_dir.sh data/train 10000 $data10k
fi

if [ ! -d $mfcc10k ]; then
	./steps/make_mfcc.sh --nj $njobs --mfcc-config conf/mfcc_online.conf \
		$data10k exp/mfcc10k $mfcc10k;
	./steps/compute_cmvn_stats.sh $data10k exp/mfcc10k $cmvn10k;
fi

if [ ! -d exp/gmm/fmllr ]; then
	./steps/align_fmllr.sh --nj $njobs --cmd "$train_cmd" \
		$data10k data/lang exp/gmm/model exp/gmm/fmllr
fi

if [ ! -d $nnet3/lda ]; then
	./steps/train_lda_mllt.sh --cmd "$train_cmd" --num-iters 13 \
		--splice-opts "--left-context=3 --right-context=3" \
		5500 90000 $data10k \
		data/lang exp/gmm/fmllr $nnet3/lda;
fi

if [ ! -d $ivector10k/dubm ]; then
	./steps/online/nnet2/train_diag_ubm.sh $data10k 2048 --num-frames 200000 $nnet3/lda $ivector10k/dubm;
fi

if [ ! -d $ivector10k/extractor ]; then
	./steps/online/nnet2/train_ivector_extractor.sh --cmd "$train_cmd" --nj $njobs \
		$data10k $ivector10k/dubm $ivector10k/extractor;
fi


if [ ! -d $ivector10k/feats ]; then
	./steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $njobs \
		$data10k $ivector10k/extractor $ivector10k/feats;
fi

conf=./exp/nnet3/configs

./steps/chain/make_weighted_den_fst.sh exp/sat/fmllr $conf

if [ ! -f $conf/network.xconfig ]; then
	num_targets=$(tree-info $nnet/lda/tree | grep num-pdfs | awk '{print $2}');
	echo "input dim=100 name=ivector
input dim=13 name=input

# please note that it is important to have input layer with the name=input
# as the layer immediately preceding the fixed-affine-layer to enable
# the use of short notation for the descriptor
        
fixed-affine-layer name=lda input=Append(-2,-1,0,1,2,ReplaceIndex(ivector, t, 0)) affine-transform-file=$nnet3/lda/full.mat

# the first splicing is moved before the lda layer, so no splicing here
        
relu-renorm-layer name=tdnn1 dim=1024
relu-renorm-layer name=tdnn2 input=Append(-1,2) dim=1024
relu-renorm-layer name=tdnn3 input=Append(-3,3) dim=1024
relu-renorm-layer name=tdnn4 input=Append(-3,3) dim=1024
relu-renorm-layer name=tdnn5 input=Append(-7,2) dim=1024
relu-renorm-layer name=tdnn6 dim=1024
        
output-layer name=output input=tdnn6 dim=${num_targets} max-change=1.5" > $conf/network.xconfig;
fi

./steps/nnet3/xconfig_to_configs.py --xconfig-file $cong/network.xconfig --config-dir $nnet3

common_egs_dir=$nnet3/egs


if [ ! -d $common_egs_dir ]; then
./steps/chain/get_egs.sh --online-ivector-dir $ivector10k/feats --left-context 3 --right-context 3 $data10k $conf $nnet3/lda $common_egs_dir;
fi

./steps/nnet3/train_dnn.py \
	--cmd="$gpu_cmd" \
	--feat-dir $data10k \
	--feat.online-ivector-dir $ivector10k/feats \
	--feat.cmvn-opts="--norm-means=false --norm-vars=false" \
	--trainer.num-epoch 1 \
	--trainer.optimization.num-jobs-initial 3 \
	--trainer.optimization.num-jobs-final 12 \
	--trainer.optimization.initial-effective-lrate 0.0017 \
	--trainer.optimization.final-effective-lrate 0.0017 \
	--cleanup.preserve-model-interval 100 \
	--egs.dir $common_egs_dir \
	--ali-dir ./exp/gmm/fmllr \
	--lang data/lang \
	--dir $nnet3;

./utils/mkgraph.sh data/lang_test $nnet3 $nnet3/graph


./steps/nnet3/decode.sh --nj $njobs --cmd "$decode_cmd" \
	        $nnet3/graph data/test $nnet3/decode

for x in $nnet3/*/decode*; do
	        grep WER $x/*wer_* | ./utils/best_wer.sh > $nnet3/best_wer.txt
	done


