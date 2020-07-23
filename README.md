# AWS-HPC-Workshop


### Configure EFS

### Collect your Canonical ID
This is needed so I can share the S3 bucket with you

`aws s3api list-buckets --output text`

### Install ParallelCluster
```bash
 pip-3.6 install aws-parallelcluster -U --user
``` 
 
### Generate a new key-pair
```bash
aws ec2 create-key-pair --key-name lab-3-your-key --query KeyMaterial --output text >> ~/.ssh/lab-3-key
chmod 600 ~/.ssh/lab-3-key
```

### Set the configuration variables

```bash
IFACE=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
SUBNET_ID=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${IFACE}/subnet-id)
VPC_ID=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${IFACE}/vpc-id)
REGION=$(curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')

```

### Create the pcluster config file
```bash
cat > config.ini << EOF
[aws]
aws_region_name = ${REGION}

[global]
update_check = true
sanity_check = true
cluster_template = default

[aliases]
ssh = ssh {CFN_USER}@{MASTER_IP} {ARGS}

[cluster default]
key_name = lab-3-your-key
base_os = centos7
maintain_initial_size = false
vpc_settings = default
initial_queue_size = 0
max_queue_size = 10
master_instance_type = g4dn.xlarge
compute_instance_type = c5.xlarge
cluster_type = ondemand
scheduler = slurm

efs_settings = customfs
dcv_settings = default
fsx_settings = fs

[fsx fs]
shared_dir = /fsx
storage_capacity = 1200
imported_file_chunk_size = 1024
export_path = s3://fruffino-multiaccount/fsx
import_path = s3://fruffino-multiaccount/fsx
weekly_maintenance_start_time = 1:00:00
deployment_type = PERSISTENT_1
per_unit_storage_throughput = 50


[dcv default]
enable = master


[vpc default]
vpc_id = ${VPC_ID}
master_subnet_id = ${SUBNET_ID}

[efs customfs]
shared_dir = efs
encrypted = false
performance_mode = generalPurpose

EOF
```

### Install ParallelCluster                                                                                                               

```bash
mkdir -p ~/.parallelcluster
cp config.ini ~/.parallelcluster
pcluster create hpclab-yourname -c config.ini
```

### Login to your cluster
```bash
pcluster list --color
pcluster ssh hpclab-yourname -i ~/.ssh/lab-3-key
```

### Run your first job
```bash
sudo chown -R centos:centos /fsx/fsx
sinfo
squeue
cat > test.sh << EOF
#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4

env
date >> /fsx/fsx/shared/test
sleep 60
EOF
chmod +x test.sh
sbatch test.sh

```

### Start a DCV session
```bash
pcluster dcv connect hpclab-yourname -k ~/.ssh/lab-3-key
```