# TTS_finetune

## 环境安装
*3.7* 以上版本的 *python* 上安装 PaddleSpeech。

### 相关依赖
+ gcc >= 4.8.5
+ paddlepaddle >= 2.4.1
+ python >= 3.7
+ linux(推荐), mac, windows

PaddleSpeech 依赖于 paddlepaddle，安装可以参考[ paddlepaddle 官网](https://www.paddlepaddle.org.cn/)，根据自己机器的情况进行选择。

## Prepare 
### Download Pretrained model
Assume the path to the model is `./pretrained_models`. </br>
If you want to finetune Chinese pretrained model, you need to download Fastspeech2 pretrained model with AISHELL-3: [fastspeech2_aishell3_ckpt_1.1.0.zip](https://paddlespeech.bj.bcebos.com/Parakeet/released_models/fastspeech2/fastspeech2_aishell3_ckpt_1.1.0.zip) for finetuning. Download HiFiGAN pretrained model with aishell3: [hifigan_aishell3_ckpt_0.2.0.zip](https://paddlespeech.bj.bcebos.com/Parakeet/released_models/hifigan/hifigan_aishell3_ckpt_0.2.0.zip) for synthesis.


```bash
mkdir -p pretrained_models && cd pretrained_models
# pretrained fastspeech2 model
wget https://paddlespeech.bj.bcebos.com/Parakeet/released_models/fastspeech2/fastspeech2_aishell3_ckpt_1.1.0.zip 
unzip fastspeech2_aishell3_ckpt_1.1.0.zip
# pretrained hifigan model
wget https://paddlespeech.bj.bcebos.com/Parakeet/released_models/hifigan/hifigan_aishell3_ckpt_0.2.0.zip
unzip hifigan_aishell3_ckpt_0.2.0.zip
cd ../
```

### Prepare your data
Assume the path to the dataset is `./input` which contains a speaker folder. Speaker folder contains audio files (*.wav) and label file (labels.txt). The format of the audio file is wav. The format of the label file is: utt_id|pronunciation. </br>

If you want to finetune Chinese pretrained model, you need to prepare Chinese data. Chinese label example: 
```
000001|ka2 er2 pu3 pei2 wai4 sun1 wan2 hua2 ti1
```

Here is a Chinese data example of the first 200 data of csmsc.

```bash
mkdir -p input && cd input
wget https://paddlespeech.bj.bcebos.com/datasets/csmsc_mini.zip
unzip csmsc_mini.zip
cd ../
```

### Download MFA tools and pretrained model
Assume the path to the MFA tool is `./tools`. Download [MFA](https://github.com/MontrealCorpusTools/Montreal-Forced-Aligner/releases/download/v1.0.1/montreal-forced-aligner_linux.tar.gz).

```bash
mkdir -p tools && cd tools
# mfa tool
wget https://github.com/MontrealCorpusTools/Montreal-Forced-Aligner/releases/download/v1.0.1/montreal-forced-aligner_linux.tar.gz
tar xvf montreal-forced-aligner_linux.tar.gz
cp montreal-forced-aligner/lib/libpython3.6m.so.1.0 montreal-forced-aligner/lib/libpython3.6m.so
mkdir -p aligner && cd aligner
```

If you want to get mfa result of Chinese data, you need to download pretrained MFA models with aishell3: [aishell3_model.zip](https://paddlespeech.bj.bcebos.com/MFA/ernie_sat/aishell3_model.zip) and unzip it.

```bash
# pretrained mfa model for Chinese data
wget https://paddlespeech.bj.bcebos.com/MFA/ernie_sat/aishell3_model.zip
unzip aishell3_model.zip
wget https://paddlespeech.bj.bcebos.com/MFA/AISHELL-3/with_tone/simple.lexicon
cd ../../
```

When "Prepare" done. The structure of the current directory is similar to the following.
```text
├── input
│   ├── csmsc_mini
│   │   ├── 000001.wav
│   │   ├── 000002.wav
│   │   ├── 000003.wav
│   │   ├── ...
│   │   ├── 000200.wav
│   │   ├── labels.txt
│   └── csmsc_mini.zip
├── pretrained_models
│   ├── fastspeech2_aishell3_ckpt_1.1.0
│   │   ├── default.yaml
│   │   ├── energy_stats.npy
│   │   ├── phone_id_map.txt
│   │   ├── pitch_stats.npy
│   │   ├── snapshot_iter_96400.pdz
│   │   ├── speaker_id_map.txt
│   │   └── speech_stats.npy
│   ├── fastspeech2_aishell3_ckpt_1.1.0.zip
│   ├── hifigan_aishell3_ckpt_0.2.0    
│   │   ├── default.yaml
│   │   ├── feats_stats.npy
│   │   └── snapshot_iter_2500000.pdz
│   └── hifigan_aishell3_ckpt_0.2.0.zip
└── tools
    ├── aligner
    │   ├── aishell3_model
    │   ├── aishell3_model.zip
    │   └── simple.lexicon
    ├── montreal-forced-aligner
    │   ├── bin
    │   ├── lib
    │   └── pretrained_models
    └── montreal-forced-aligner_linux.tar.gz
    ...

```

### Set finetune.yaml
`conf/finetune.yaml` contains some configurations for fine-tuning. You can try various options to fine better result. The value of frozen_layers can be change according `conf/fastspeech2_layers.txt` which is the model layer of fastspeech2.

Arguments:
  - `batch_size`: finetune batch size which should be less than or equal to the number of training samples. Default: -1, means 64 which same to pretrained model
  - `learning_rate`: learning rate. Default: 0.0001
  - `num_snapshots`: number of save models. Default: -1, means 5 which same to pretrained model
  - `frozen_layers`: frozen layers. must be a list. If you don't want to frozen any layer, set []. 


## Get Started
execute `./run.sh`. </br>
Run the command below to
1. **source path**.
2. finetune the model. 
3. synthesize wavs.
    - synthesize waveform from text file.

```bash
./run.sh
```
You can choose a range of stages you want to run, or set `stage` equal to `stop-stage` to run only one stage.

