#!/bin/bash

### MAKE SPEAKER A T ###

source ./cmd.sh || exit 1;
source ./path.sh || exit 1;
source parse_options.sh || exit ;

dir_exp="./exp/sat"
dir_ali="./exp/lda/align"

leaves=15000
gauss=17000

if [ ! -d $dir_ali ]; then
	./steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
		data/train data/lang ./exp/lda/model ${dir_ali}
fi

./steps/train_sat.sh --cmd "$train_cmd" \  #config
	$leaves $gauss \                       #hiperparam
	data/train data/lang ${dir_ali} \      #input
	${dir_exp}/model                       #output

./utils/mkgraph.sh data/lang_test ${dir_exp}/model ${dir_exp}/graph

./steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
	${dir_exp}/graph data/test ${dir_exp}/model/decode

for x in $dir_exp/*/decode*; do
	[ -d $x ] && grep WER $x/wer_* | \
		./utils/best_wer.sh > $dir_exp/best_wer.txt;
done
