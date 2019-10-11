#!/bin/bash

source ./cmd.sh || exit 1;
source ./path.sh || exit 2;

source parse_options.sh || exit 3;

sw=0.5
gauss=250

dubm=./exp/dubm
sat=./exp/sat

if [ ! -d $sat/fmllr ]; then
	echo "Gak ada fmllr nya, coba ditrain dulu";
	exit 4
fi

./steps/train_diag_ubm.sh --silence-weight $sw --nj $njobs --cmd "$train_cmd" \
	$gauss data/train data/lang $sat/fmllr $dubm/model;

./steps/train_mmi_fmmi.sh --learning-rate 0.0025 \
	--boost 0.1 --cmd "$train_cmd" \
	data/train data/lang \
	$sat/fmllr $dubm/model $sat/denlats \
	$dubm/fmmi

for iter in {3..8}; do
	steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" \
		--iter $iter --transform-dir $sat/model/decode \
		$sat/graph data/test $dubm/fmmi/decode;
done

./steps/train_mmi_fmmi.sh --learning-rate 0.001 \
	--boost 0.1 --cmd "$train_cmd" \
	data/train data/lang \
	$sat/fmllr $dubm $sat/denlats \
	$dubm/fmmi_c;

for iter in {3..8}; do
	steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" \
		--iter $iter --transform-dir $sat/model/decode \
		$sat/graph data/test $dubm/fmmi_c/decode${iter};
done

./steps/train_mmi_fmmi_indirect.sh --learning-rate 0.002 \
	--schedule "fmmi fmmi fmmi fmmi mmi mmi mmi mmi" \
	--boost 0.1 --cmd "$train_cmd" data/train data/lang \
	$sat/fmllr $dubm $sat/denlats \
	$dubm/fmmi_d;

for iter in {3..8}; do 
	steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" \
		--iter $iter --transform-dir $sat/model/decode $sat/graph \
		data/test $dubm/fmmi_d/decode${iter};
done

for x in $dubm/*/decode*; do
	[ -d $x ] && grep WER $x/*wer_* | \
		./utils/best_wer.sh > $dubm/best_wer.txt;
done

