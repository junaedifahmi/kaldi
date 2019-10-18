#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source parse_options.sh || exit 3;

chain=./exp/chain
ivector=./exp/ivector/feats

xent_regularize=0.1

# Generate Topologi
lang=./data/lang_chain
rm -rf $lang
cp -r data/lang $lang

silphonelist=$(cat $lang/phones/silence.csl);
nonsilphonelist=$(cat $lang/phones/nonsilence.csl);

./steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist > $lang/topo


ali=./exp/gmm/align
# Building Tree
./steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 \
	--context-opts "--context-width=2 --central-position=1" \
	--cmd "$train_cmd" 7000 data/train $lang $ali \
	$chain/tree;

# Create Config Files

num_target=$(tree-info $chain/tree/tree | grep num-pdfs|awk '{print $2}' )
lr_factor=$(echo "print (0.5/$xent_regularize)" | python )
affine_opts="l2-regularize=0.01 dropout-proportion=0.0 dropout-per-dim=true dropout-per-dim-continuous=true"
tdnnf_opts="l2-regularize=0.01 droupout-proportion=0.0 droupout-proportion=0.0 bypass-scale=0.66"
linear_opts="l2-regularize=0.01 orthonormal-constraint=-1.0"
prefinal_opts="l2-regularize=0.01"
output_opts="l2-regularize=0.002"

mkdir -p $chain/configs

echo "input dim=100 name=ivector
  input dim=13 name=input

  delta-layer name=delta
  no-op-component name=input2 input=Append(delta, Scale(1.0, ReplaceIndex(ivector, t, 0)))

  relu-batchnorm-dropout-layer name=tdnn1 $affine_opts dim=1536 input=input2
  tdnnf-layer name=tdnnf2 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
  tdnnf-layer name=tdnnf3 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
  tdnnf-layer name=tdnnf4 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
  tdnnf-layer name=tdnnf5 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=0
  tdnnf-layer name=tdnnf6 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf7 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf8 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf9 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf10 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf11 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf12 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf13 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf14 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf15 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  linear-component name=prefinal-l dim=256 $linear_opts

  prefinal-layer name=prefinal-chain input=prefinal-l $prefinal_opts big-dim=1536 small-dim=256
  output-layer name=output include-log-softmax=false dim=$num_targets $output_opts

  prefinal-layer name=prefinal-xent input=prefinal-l $prefinal_opts big-dim=1536 small-dim=256
  output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts" > $chain/configs/network.xconfig;

./steps/nnet3/xconfig_to_configs.py --xconfig-file $chain/configs/network.xconfig --config-dir $chain/configs


dir_lat=exp/sat/lat

if [ ! -d $dir_lat ]; then
	./steps/align_fmllr_lat.sh --cmd "$train_cmd" --nj $njobs data/train data/lang exp/sat $dir_lat;
fi

./steps/chain/make_weighted_den_fst.sh exp/sat/align $chain/model


$common_egs_dir=./exp/chain/egs

if [ ! -d $common_egs_dir ]; then
	./steps/chain/get_egs.sh --online-ivectoer-dir $ivector --left-context 1 --right-context 8 data/train $chain/model ./exp/sta/lta $common_egs_dir;
fi



# Training
./steps/nnet3/chain/train.py \
	--cmd "$train_cmd" \
	--feat.online-ivector-dir $ivector \
	--feat.cmvn-opts "--norm-means=false --norm-vars=false" \
	--chain.xent-regularize $xent_regularize \
	--chain.leaky-hmm-coefficient 0.1 \
	--chain.l2-regularize 0.0 \
	--chain.apply-deriv-weights false \
	--chain.lm-opts="--num-extra-lm-states=2000" \
	--trainer.dropout-schedule $dropout_schedule \
	--trainer.add-option="--optimization.memory-compression-level=2" \
	--egs-dir $common_egs_dir \
	--feat-dir data/train \
	--tree-dir $chain/tree \
	--lat-dir $dir_lat \
	--dir $chain/model

# Make graph
./utils/mkgraph.sh --self-loop-scale 1.0 data/lang_test $chain/model $chain/graph

# Decode

./steps/nnet3/deocode.sh --acwt 1.0 --post-decode-acwt 10.0 \
	--nj $njobs --cmd "$decode_cmd" \
	--online-ivector-dir $ivector \
	$chain/graph data/test $chain/model/decode

for x in $chain/*/decode* ; do
	grep WER $x/*wer_* | ./utils/best_wer.sh > $chain/best_wer.txt; 
done




