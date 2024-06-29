nvidia-smi && \
# Huge Pages
echo 'Checking Huge Pages configuration:'
cat /proc/meminfo | grep Huge
ls -lh /dev/hugepages

# Check HugePages_Free
hugepages_free=$(cat /proc/meminfo | grep -i hugepages_free | awk '{print $2}')
echo "HugePages_Free: $hugepages_free"

if [ $hugepages_free -lt 15000 ]; then
    echo "Error: HugePages_Free ($hugepages_free) is less than 15000. Please make sure HugePages is configured correctly on the host machine. Requires 15000 HugePages configured per node."
    exit 1
fi

# Download param files from local FTP server
wget -r -nH -nv --cut-dirs=1 --no-parent --user=ftpuser --password=ftppassword ftp://localhost/params/ -P /home/zkwasm/prover-node-release/workspace/static/ && \
time=$(date +%Y-%m-%d-%H-%M-%S) && \
CUDA_VISIBLE_DEVICES=0 RUST_LOG=info RUST_BACKTRACE=1 ./target/release/zkwasm-playground --config prover_config.json -w workspace --dryrunconfig dry_run_config.json -p \
      2>&1 | rotatelogs -e -n 10 logs/prover/prover_${time}.log 100M