# Hands-on HPC Training Workshop

**Introduction to Linux, Slurm and Cluster Monitoring**

Designed by Dr. Tanmoy Chakraborty

**Duration:** 60 minutes  
**Level:** Beginner  
**Environment:** Two-node Ubuntu mini-HPC cluster

## Workshop objectives

By the end of this workshop, participants should be able to:

- Understand the basic structure of an HPC cluster.
- Navigate the Linux command line.
- Check compute-node availability using Slurm.
- Submit and monitor simple computational jobs.
- Execute tasks across multiple compute nodes.
- Interpret basic CPU, memory and network metrics using Grafana.

## Before you begin

Complete the [Installation and Setup Guide](../docs/installation-guide.md) before starting this workshop.

Your mini-HPC environment should have two running virtual machines:

| Node | Role |
|---|---|
| `node01` | Login node, Slurm controller and compute node |
| `node02` | Compute node |

On your host computer, navigate to the project directory and connect to the controller:

```bash
cd mini-hpc-training
vagrant ssh node01
```

Unless otherwise specified, all commands in this workshop should be executed **inside `node01`**.

---

## Exercise 1: Introduction to HPC (5 minutes)

### What is High Performance Computing?

High Performance Computing (HPC) uses computational resources to solve problems that may be too large, complex or time-consuming for an ordinary desktop computer.

HPC systems typically consist of multiple interconnected computers, known as *nodes*, working together to execute computational workloads.

### Understanding our mini-HPC cluster

Our training environment contains two nodes:

- **node01:** Accepts user connections, manages jobs through Slurm and executes computational tasks.
- **node02:** Executes computational tasks assigned by Slurm.

The two nodes communicate across a virtual network.

**Slurm** is the workload manager. It decides where and when jobs run, based on the resources requested and available.

**Munge** provides authentication between cluster components.

**Prometheus** collects monitoring metrics, while **Grafana** displays them through dashboards.

### Quick discussion

Consider these questions:

1. Why might researchers need an HPC cluster rather than a desktop computer?
2. What is the difference between a login node and a compute node?
3. Why do HPC systems use job schedulers such as Slurm?

---

## Exercise 2: Linux command-line basics (10 minutes)

### 2.1 Identify your current location

Run:

```bash
pwd
```

The `pwd` command displays your current working directory.

### 2.2 List files and directories

```bash
ls
```

For a detailed listing:

```bash
ls -lh
```

### 2.3 Create a working directory

```bash
mkdir -p ~/hpc-workshop
cd ~/hpc-workshop
```

This creates a directory for your training files and moves into it.

### 2.4 Create a text file

```bash
echo "Hello from the mini-HPC cluster!" > hello.txt
```

Display its contents:

```bash
cat hello.txt
```

### 2.5 Identify the current node

```bash
hostname
```

Expected output:

```text
node01
```

### 2.6 Inspect system resources

Check processor information:

```bash
nproc
```

Check memory availability:

```bash
free -h
```

Check disk usage:

```bash
df -h
```

### 2.7 Check running processes

```bash
ps aux | head
```

This displays a sample of the processes currently running.

### Exercise questions

1. What is the difference between `pwd` and `ls`?
2. What does `mkdir -p` do?
3. How much memory is available on `node01`?
4. Why is it useful to check system resources before running a computational job?

---

## Exercise 3: Exploring Slurm (10 minutes)

### 3.1 Check available partitions

```bash
sinfo
```

The `compute` partition should contain both nodes.

### 3.2 Display individual node states

```bash
sinfo -N -l
```

Look for `node01` and `node02` and examine their states.

### 3.3 Inspect detailed node information

```bash
scontrol show nodes
```

Look for fields such as:

- `NodeName`
- `CPUAlloc`
- `CPUTot`
- `RealMemory`
- `State`

### 3.4 Check the job queue

```bash
squeue
```

The queue may be empty if no jobs are currently running.

### 3.5 Run your first Slurm task

```bash
srun hostname
```

Slurm selects an available compute node and executes the command.

### Exercise questions

1. How many nodes are available in the `compute` partition?
2. What does the `idle` node state mean?
3. What is the difference between `sinfo` and `squeue`?
4. Why use `srun hostname` instead of simply running `hostname`?

---

## Exercise 4: Submitting and managing Slurm jobs (15 minutes)

In this exercise, you'll learn how to create a batch script, submit it to Slurm, monitor its execution and inspect the results.

### 4.1 Navigate to your working directory

Make sure you're connected to `node01`.

```bash
cd ~/hpc-workshop
```

### 4.2 Create your first batch script

Open a text editor:

```bash
nano hello.slurm
```

Add the following:

```bash
#!/bin/bash
#SBATCH --job-name=hello-hpc
#SBATCH --output=hello-%j.out
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:02:00

echo "Hello from my first Slurm batch job!"
echo "Running on: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Date: $(date)"
```

Save the file.

### 4.3 Submit the job

```bash
sbatch hello.slurm
```

Slurm will return a job ID, for example:

```text
Submitted batch job 5
```

Your job ID may be different.

### 4.4 Check the job queue

```bash
squeue
```

For a queue showing only your jobs:

```bash
squeue -u "$USER"
```

A short job may finish before you can see it in the queue. This is normal.

### 4.5 Inspect the job output

```bash
ls -lh hello-*.out
cat hello-*.out
```

You should see the greeting, hostname, job ID and execution date.

The `%j` in the output filename is replaced by the Slurm job ID.

### 4.6 Submit a longer-running job

Create another script:

```bash
nano sleep.slurm
```

Add:

```bash
#!/bin/bash
#SBATCH --job-name=sleep-test
#SBATCH --output=sleep-%j.out
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:02:00

echo "Starting on $(hostname)"
sleep 60
echo "Job completed"
```

Submit it:

```bash
sbatch sleep.slurm
```

Check the queue:

```bash
squeue
```

Look for the job state `R` (running) or `PD` (pending).

### 4.7 Cancel the job

If the sleep job is still running, cancel it using its job ID:

```bash
scancel JOB_ID
```

Replace `JOB_ID` with the numerical ID returned by `sbatch`. Do not type the word `JOB_ID` literally.

### Exercise questions

1. What is the difference between `sbatch` and `srun`?
2. What does `#SBATCH --time=00:02:00` specify?
3. What is the purpose of `%j` in the output filename?
4. What do the job states `R` and `PD` mean?
5. Why might a job disappear from `squeue` shortly after submission?

---

## Exercise 5: Distributed job execution (10 minutes)

In this exercise, you'll use both compute nodes to demonstrate how Slurm distributes work across the mini-HPC cluster.

### 5.1 Check node availability

```bash
sinfo
```

Confirm that both `node01` and `node02` are available.

### 5.2 Run tasks across both nodes

```bash
srun --nodes=2 --ntasks=2 hostname
```

Expected output (order may vary):

```text
node01
node02
```

This command asks Slurm to allocate two nodes and launch two tasks.

### 5.3 Create a distributed batch script

Navigate to your working directory:

```bash
cd ~/hpc-workshop
```

Create a script:

```bash
nano distributed.slurm
```

Add:

```bash
#!/bin/bash
#SBATCH --job-name=distributed-test
#SBATCH --output=distributed-%j.out
#SBATCH --partition=compute
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:02:00

echo "Slurm job ID: $SLURM_JOB_ID"
echo "Allocated nodes: $SLURM_JOB_NODELIST"
echo "Starting distributed tasks:"

srun hostname
```

Save the file.

### 5.4 Submit the distributed job

```bash
sbatch distributed.slurm
```

Once the job completes, inspect its output:

```bash
cat distributed-*.out
```

The output should show both node hostnames.

### 5.5 Understand the difference between tasks and nodes

A **node** is a computer participating in the cluster.

A **task** is an instance of a program launched by Slurm.

A job can request multiple tasks on one node or distribute tasks across several nodes, depending on its resource requirements.

In our mini-HPC configuration, the Slurm scheduler currently allocates one CPU per node.

### Exercise questions

1. What do `--nodes=2` and `--ntasks=2` mean?
2. Why do we use `srun` inside the distributed batch script?
3. Can multiple tasks run on the same compute node?
4. What would happen if `node02` were unavailable?
5. Does running `hostname` on two nodes mean the nodes are performing a tightly coupled parallel calculation?

**Important:** This exercise demonstrates distributed task launching, not an actual MPI parallel computation. MPI programming can be introduced in a future advanced workshop.
