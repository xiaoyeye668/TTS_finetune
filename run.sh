#!/bin/bash

set -e
source path.sh


input_dir=./input/tmp_0
newdir_name="newdir"
new_dir=${input_dir}/${newdir_name}
pretrained_model_dir=./pretrained_models/fastspeech2_aishell3_ckpt_1.1.0
mfa_dir=./mfa_result
dump_dir=./dump
output_dir=./exp/default
lang=zh
ngpu=0
finetune_config=./conf/finetune.yaml
replace_spkid=0

#ckpt=snapshot_iter_96400
#ckpt=snapshot_iter_96699
#ckpt=snapshot_iter_96645
#ckpt=snapshot_iter_97890
ckpt=snapshot_iter_97815
gpus=-1
CUDA_VISIBLE_DEVICES=${gpus}
stage=0
stop_stage=100


# with the following command, you can choose the stage range you want to run
# such as `./run.sh --stage 0 --stop-stage 0`
# this can not be mixed use with `$1`, `$2` ...
source ${MAIN_ROOT}/utils/parse_options.sh || exit 1

# check oov
if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    echo "check oov"
    python local/check_oov.py \
        --input_dir=${input_dir} \
        --pretrained_model_dir=${pretrained_model_dir} \
        --newdir_name=${newdir_name} \
        --lang=${lang}
fi

# get mfa result
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "get mfa result"
    python local/get_mfa_result.py \
        --input_dir=${new_dir} \
        --mfa_dir=${mfa_dir} \
        --lang=${lang}
fi

# generate durations.txt
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "generate durations.txt"
    python local/generate_duration.py \
        --mfa_dir=${mfa_dir} 
fi

# extract feature
if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "extract feature"
    python local/extract_feature.py \
        --duration_file="./durations.txt" \
        --input_dir=${new_dir} \
        --dump_dir=${dump_dir} \
        --pretrained_model_dir=${pretrained_model_dir} \
        --replace_spkid=$replace_spkid
fi

# create finetune env
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "create finetune env"
    python local/prepare_env.py \
        --pretrained_model_dir=${pretrained_model_dir} \
        --output_dir=${output_dir}
fi

# finetune
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "finetune..."
    python local/finetune.py \
        --pretrained_model_dir=${pretrained_model_dir} \
        --dump_dir=${dump_dir} \
        --output_dir=${output_dir} \
        --ngpu=${ngpu} \
        --epoch=100 \
        --finetune_config=${finetune_config}
fi

# synthesize e2e on hifigan
if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
    echo "in hifigan syn_e2e"
    python ${BIN_DIR}/../synthesize_e2e.py \
        --am=fastspeech2_aishell3 \
        --am_config=${pretrained_model_dir}/default.yaml \
        --am_ckpt=${output_dir}/checkpoints/${ckpt}.pdz \
        --am_stat=${pretrained_model_dir}/speech_stats.npy \
        --voc=hifigan_aishell3 \
        --voc_config=pretrained_models/hifigan_aishell3_ckpt_0.2.0/default.yaml \
        --voc_ckpt=pretrained_models/hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
        --voc_stat=pretrained_models/hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
        --lang=zh \
        --text=./sentences.txt \
        --output_dir=./test_e2e/ \
        --phones_dict=${dump_dir}/phone_id_map.txt \
        --speaker_dict=${dump_dir}/speaker_id_map.txt \
        --spk_id=$replace_spkid \
        --ngpu=0
fi


# synthesize e2e on pwg
if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
    echo "in pwgan syn_e2e"
    python ${BIN_DIR}/../synthesize_e2e.py \
        --am=fastspeech2_aishell3 \
        --am_config=${pretrained_model_dir}/default.yaml \
        --am_ckpt=${output_dir}/checkpoints/${ckpt}.pdz \
        --am_stat=${pretrained_model_dir}/speech_stats.npy \
        --voc=pwgan_aishell3 \
        --voc_config=pretrained_models/pwg_aishell3_ckpt_0.5/default.yaml \
        --voc_ckpt=pretrained_models/pwg_aishell3_ckpt_0.5/snapshot_iter_1000000.pdz \
        --voc_stat=pretrained_models/pwg_aishell3_ckpt_0.5/feats_stats.npy \
        --lang=zh \
        --text=./sentences3.txt \
        --output_dir=./demo5/ \
        --phones_dict=${dump_dir}/phone_id_map.txt \
        --speaker_dict=${dump_dir}/speaker_id_map.txt \
        --spk_id=$replace_spkid \
        --ngpu=0
fi
