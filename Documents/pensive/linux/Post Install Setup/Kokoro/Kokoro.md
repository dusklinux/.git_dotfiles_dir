not needed for this project but needed for other kokoros
pytorch cpu 118 NOT 12.X
or 
pytorch cuda 118 not 12.x
python 3.12

(OPTIONAL BUT NOT RECOMMANDED)
paru -S miniconda3
source /opt/miniconda3/etc/profile.d/conda.sh
sudo chown -R dusk:dusk /opt/miniconda3
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 && conda --version
conda update -n base -c defaults conda
nvim ~/.condarc

channels:
  - conda-forge
  - defaults
channel_priority: strict
echo "[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc
conda create --name kokoro python=3.12
conda activate kokoro
pip install --upgrade pip

-------------
(OPTIONAL BUT RECOMMENDED)
uv venv kokoro_cpu --python 3.12
source kokoro_cpu/bin/activate
cd kokoro_cpu
git clone https://github.com/nazdridoy/kokoro-tts.git
cd kokoro-tts
uv sync --active
wget https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/voices-v1.0.bin
wget https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/kokoro-v1.0.onnx
mkdir /mnt/zram/kokoro/
./kokoro-tts ~/Documents/text.txt /mnt/zram1/kokoro/audio.wav --voice af_heart && mpv /mnt/zram1/kokoro/audio.wav


good voices 
4 --female 
17 -- manly
7 --quite
20 --santa
