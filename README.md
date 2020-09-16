# AWS-HPC-Workshop


### Create an S3 bucket
Create an S3 bucket with a unique name using the following command.

```
BUCKET_POSTFIX=$(uuidgen --random | cut -d'-' -f1)
aws s3 mb s3://bucket-${BUCKET_POSTFIX}

cat << EOF
***** Take Note of Your Bucket Name *****
Bucket Name = bucket-${BUCKET_POSTFIX}
*****************************************
EOF
```

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
vpc_settings = default
master_instance_type = g4dn.xlarge
scheduler = slurm

queue_settings = compute,memory

efs_settings = customfs
dcv_settings = default
fsx_settings = fs

[fsx fs]
shared_dir = /fsx
storage_capacity = 1200
imported_file_chunk_size = 1024
export_path = s3://bucket-${BUCKET_POSTFIX}/fsx
import_path = s3://bucket-${BUCKET_POSTFIX}/fsx
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

[queue compute]
compute_resource_settings = c4
placement_group = DYNAMIC
#enable_efa = true
disable_hyperthreading = true
compute_type = ondemand

[queue memory]
compute_resource_settings = m4
placement_group = DYNAMIC
disable_hyperthreading = true
compute_type = ondemand

[compute_resource c4]
instance_type = c4.xlarge
min_count = 0
initial_count = 0
max_count = 10

[compute_resource m4]
instance_type = m4.xlarge
min_count = 0
initial_count = 0
max_count = 10

EOF
```

### Deploy your HPC cluster with ParallelCluster                                                                                                               

```bash
mkdir -p ~/.parallelcluster
cp config.ini ~/.parallelcluster/config
pcluster create hpclab-yourname -c config.ini
```

### Login to your cluster
```bash
pcluster list --color
pcluster ssh hpclab-yourname -i ~/.ssh/lab-3-key
```

### Run your first job
```bash
sudo chown -R centos:centos /fsx
sinfo
squeue
cat > test.sh << EOF
#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=compute

env
date >> /fsx/output-\${SLURM_JOB_ID}.txt
sleep 60
EOF
chmod +x test.sh
sbatch test.sh

```

## Run an MPI job
### Compile MPI hello_world
First, build and compile your MPI hello world application. In your AWS Cloud9 terminal, run the following commands to create and build the hello world binary.


```
cat > mpi_hello_world.c << EOF
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <unistd.h>

int main(int argc, char **argv){
  int step, node, hostlen;
  char hostname[256];
  hostlen = 255;

  MPI_Init(&argc,&argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &node);
  MPI_Get_processor_name(hostname, &hostlen);

  for (step = 1; step < 5; step++) {
    printf("Hello World from Step %d on Node %d, (%s)\n", step, node, hostname);
    sleep(2);
  }

 MPI_Finalize();
}
EOF

module load intelmpi
mpicc mpi_hello_world.c -o mpi_hello_world
```

### Create submission script
This script will launch the MPI Hello World application with 4 processes and export the generated output to a *.out file.

```
cat > submission_script.sbatch << EOF
#!/bin/bash
#SBATCH --job-name=hello-world-job
#SBATCH --ntasks=4
#SBATCH --output=%x_%j.out

mpirun ./mpi_hello_world
EOF
```

### Submit your first MPI job
Submit your first MPI job using the following command on the head node:

```
sbatch submission_script.sbatch
```


### Start a DCV session
```bash
pcluster dcv connect hpclab-yourname -k ~/.ssh/lab-3-key
```
