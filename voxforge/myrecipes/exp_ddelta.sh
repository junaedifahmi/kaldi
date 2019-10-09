#!/bin/bash

source ./cmd.sh || exit 10;
source ./path.sh || exit 10;

dir_base="./exp/tri_ddelta/"

if [ ! -d exp/tri_delta/align ]; then
	./steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
		data/train data/lang \
		exp/tri_delta/3000_4000/model \
		exp/tri_delta/align;
fi

for gauss in {5000..10000..1000}; do
	for leaves in {6000..1200..1000}; do
		dir_exp=${dir_base}/${x}_${y}
		train_start=$(date +"%T")
		./steps/train_deltas.sh --cmd "$train_cmd" \
			$gauss $leaves \
			data/train data/lang exp/tri_delta/align \
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
		echo $elapsed >> ${dir_exp}/decode_time.txt

		for x in ${dir_exp}/*/decode*; do
			[ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh >> ${dir_base}/best_wer.txt;
		done
	done
done


