import os
import re
import sys
from pypinyin import pinyin, lazy_pinyin, Style

input_dir = sys.argv[1]
out_dir = sys.argv[2]
label_file = open(sys.argv[2]+'/labels.txt', 'w')

count = 0
for _ in range(6):
    for files in os.listdir(input_dir):
        if files.split('.')[-1] == 'mp3':
            txt = files.split('.')[0]
            wav_name = '{:0>4d}'.format(count)
            os.system('ffmpeg -i {}/{} -ar 24000 -y -f wav {}/{}.wav'.format(input_dir, files, out_dir, wav_name))
            count += 1
            txt_py = lazy_pinyin(txt, style=Style.TONE3, neutral_tone_with_five=True)
            label_file.write('{}|{}'.format(wav_name, ' '.join(str(x) for x in txt_py)))
            label_file.write('\n')
