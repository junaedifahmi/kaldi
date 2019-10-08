#!/bin/bash

source ./cmd.sh || exit 10;
source ./path.sh || exit 10;

dir_base="./exp/tri_lda/"
dir_ali="exp/tri/ddelta/align"

if [ ! -d ${dir_ali} ]; then
	./steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
		data/train data/lang \
		exp/tri_delta/3000_4000/model \
		${dir_ali};
fi

for leaves {10000..1000..20000} ; do
	for gauss in {15000..1000..25000}  ; do
		dir_exp=${dir_base}/${leaves}_${gauss}
		train_start=$(date +"%T")
		./steps/train_lda_mllt.sh --cmd "$train_cmd" \
			$gauss $leaves \
			data/train data/lang ${dir_ali} \
			${dir_exp}/model;
		train_end=$(date +"%T")
		elapsed=$(( $(date -d "$train_end" "+%s") - $(date -d "$train_start" "+%s") ))
		echo $elapsed >> ${dir_exp}/training_time.txt

		./utils/mkgraph.sh \
			data/lang_test ${dir_exp}/model \
			${dir_exp}/graph;

		train_start=$(date +"%T")
		./steps/decode.sh --config ./conf/decode.config --nj $njobs --cmd "$decode_cmd" \
			${dir_exp}/graph data/test \
			${dir_exp}/model/decode;
		train_end=$(date +"%T")
		elapsed=$(( $(date -d "$train_end" "+%s") - $(date -d "$train_start" "+%s") ))
		echo $elapsed >> ${dir_exp}/decode_time.txt

		for x in ${dir_exp}/*/decode*; do
			[ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh >> ${dir_base}/best_wer.txt;
		done
	done
done


