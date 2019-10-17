#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;
source parse_options.sh || exit 3;


ivector=./exp/ivector
nnet3=./exp/nnet3
gmm=./exp/gmm

if [ ! -d $ivector ]; then
	echo " Belum bikin iVector, bentar aku bikinin";
	./myrecipes/13_make_ivector.sh || exit 4;
fi



if [ ! -f $nnet3/configs/network.xconfig ]; then
	echo "Gak ada file confignya, dasar kau ini!!"
	mkdir -p $nnet3/configs
	num_targets=$(tree-info $gmm/tree | grep num-pdfs | awk '{print $2}');
	echo "input dim=100 name=ivector
	input dim=40 name=input
	
	# please note that it is important to have input layer with the name=input
	# as the layer immediately preceding the fixed-affine-layer to enable
	# the use of short notation for the descriptor
	
	fixed-affine-layer name=lda input=Append(-2,-1,0,1,2,ReplaceIndex(ivector, t, 0)) affine-transform-file=$nnet3/configs/lda.mat
	
	# the first splicing is moved before the lda layer, so no splicing here
	
	relu-renorm-layer name=tdnn1 dim=1024
	relu-renorm-layer name=tdnn2 input=Append(-1,2) dim=1024
	relu-renorm-layer name=tdnn3 input=Append(-3,3) dim=1024
	relu-renorm-layer name=tdnn4 input=Append(-3,3) dim=1024
	relu-renorm-layer name=tdnn5 input=Append(-7,2) dim=1024
	relu-renorm-layer name=tdnn6 dim=1024
	
	output-layer name=output input=tdnn6 dim=$num_targets max-change=1.5" >
	$dnnet3/configs/network.xconfig
fi

./steps/nnet3/xconfig_to_configs.py --xconfig-file $nnet3/network.xconfig

./steps/nnet3/train_dnn.py \
	--cmd="$gpu_cmd"\
	--feat.online-ivector-dir $ivector \
	--feat.cmvn-opts="--norm-means=false --norm-vars=false" \
	--trainer.num-epoch 1\
	--trainer.optimization.num-jobs-initial 3 \
	--trainer.optimization.num-jobs-final 16 \
	--trainer.optimization.initial-effective-lrate 0.0017 \
	--trainer.optimization.final-effective-lrate 0.0017 \
	--cleanup.preserve-model-interval 100 \
	--ali-dir $gmm/align \
	--lang data/lang \
	--dir $nnet3/model

./utils/mkgraph.sh data/lang_test $nnet3/model $nnet3/graph


./steps/nnet3/decode.sh --nj $njobs --cmd "$decode_cmd" \
	$nnet3/graph data/test $nnet3/model/decode

for x in $nnet3/*/decode*; do
	grep WER $x/*wer_* | ./utils/best_wer.sh > $nnet3/best_wer.sh
done



