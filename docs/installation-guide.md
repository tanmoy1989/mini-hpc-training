# Mini-HPC Training: Installation and Setup Guide

**A step-by-step guide to deploying a two-node HPC training cluster**

Designed by Dr. Tanmoy Chakraborty

## 1. Introduction

This guide explains how to deploy and verify a mini-HPC training environment using Vagrant, VMware, Ansible, Slurm, Prometheus and Grafana.

The installation creates two Ubuntu 24.04 virtual machines:

- **node01:** Login node, Slurm controller, compute node and monitoring server.
- **node02:** Compute node.

The cluster is automatically configured using the `setup.sh` deployment script.

## 2. System requirements

### 2.1 Host software

Install the following software on your host computer before proceeding:

1. VMware Workstation with a compatible licence.
2. HashiCorp Vagrant.
3. Vagrant VMware Desktop provider plugin and the required VMware utility.
4. Ansible, including `ansible-galaxy`.
5. Python 3.
6. Git.

An internet connection is required to download the Ubuntu virtual machine image, operating system packages and Grafana.

**Compatibility:** The current project has been tested on a Linux host with VMware. Other virtualisation providers have not yet been tested.

### 2.2 Hardware requirements

The deployment requests:

| Resource | node01 | node02 | Total |
|---|---|---|---|
| RAM | 2 GB | 2 GB | 4 GB |
| Virtual CPUs | 2 | 2 | 4 |
| Operating system | Ubuntu 24.04 | Ubuntu 24.04 | — |

Allow additional resources for the host operating system, VMware overhead and virtual machine storage.

### 2.3 Installing prerequisites on Ubuntu

The following instructions are intended for Ubuntu Linux host computers.

#### Install Ansible

```bash
sudo apt update
sudo apt install -y ansible
```

Verify the installation:

```bash
ansible --version
ansible-galaxy --version
```

`ansible-galaxy` is normally included with Ansible and does not require a separate installation.

#### Install Vagrant

Vagrant is maintained by HashiCorp. Follow the official installation instructions for Ubuntu:

[Install HashiCorp Vagrant](https://developer.hashicorp.com/vagrant/install)

After installation, verify:

```bash
vagrant --version
```

#### Install VMware Workstation

Install a compatible version of VMware Workstation on your host computer.

The current mini-HPC project uses VMware as its virtualisation provider. Other providers have not yet been tested.

#### Install the Vagrant VMware Utility

The VMware provider requires the Vagrant VMware Utility, which must be installed separately.

Follow the official instructions:

[Vagrant VMware Utility Installation](https://developer.hashicorp.com/vagrant/install/vmware)

#### Install the Vagrant VMware Desktop plugin

Once Vagrant, VMware Workstation and the VMware Utility are installed, run:

```bash
vagrant plugin install vagrant-vmware-desktop
```

Verify:

```bash
vagrant plugin list
```

The output should include `vagrant-vmware-desktop`.

#### Verify the prerequisites

Before proceeding with the mini-HPC deployment, confirm that the following commands work:

```bash
vagrant --version
ansible --version
ansible-galaxy --version
python3 --version
git --version
```

All required tools must be installed on the **host computer**, not inside the Ubuntu virtual machines.

Once these checks pass, continue with Section 3 to clone the repository and deploy the cluster.

## 3. Download the project

Open a terminal on the host computer.

Clone the repository:

```bash
git clone https://github.com/tanmoy1989/mini-hpc-training.git
```

Enter the project directory:

```bash
cd mini-hpc-training
```

## 4. Deploy the mini-HPC cluster

Run the automated installation:

```bash
./setup.sh
```

The deployment script performs the following operations:

1. Checks the host prerequisites and VMware Vagrant provider.
2. Installs the required Ansible collections.
3. Creates and starts two Ubuntu virtual machines.
4. Automatically discovers their IP addresses.
5. Generates the Ansible inventory file.
6. Installs and configures Munge, Slurm, Prometheus and Grafana.
7. Provisions the Grafana monitoring dashboard.

The initial deployment may take longer because software packages must be downloaded and installed.

A successful run finishes with:

```text
==========================================
 Mini-HPC deployment completed!
==========================================
```

**Important:** Run Vagrant commands from inside your cloned `mini-hpc-training` directory to ensure they target the intended virtual machines.

## 5. Verify the cluster installation

After `./setup.sh` completes, verify that both virtual machines and the HPC services are functioning.

### 5.1 Check the virtual machines

On your host computer, from inside the `mini-hpc-training` directory, run:

```bash
vagrant status
```

Expected result:

```text
node01    running (vmware_desktop)
node02    running (vmware_desktop)
```

Both VMs should be running.

### 5.2 Connect to the Slurm controller

From your host computer:

```bash
vagrant ssh node01
```

You are now logged into `node01`, which acts as the login node, Slurm controller and compute node.

The following Slurm commands should be executed inside this VM.

### 5.3 Check Slurm node availability

Run:

```bash
sinfo
```

Expected output:

```text
PARTITION AVAIL  TIMELIMIT  NODES STATE NODELIST
compute*  up     infinite      2  idle node[01-02]
```

This confirms that Slurm recognises both compute nodes.

The node state may differ if jobs are currently running.

### 5.4 Execute a distributed Slurm job

Run:

```bash
srun --nodes=2 --ntasks=2 hostname
```

Expected output (order may vary):

```text
node01
node02
```

This confirms that Slurm can launch tasks across both virtual machines.

### 5.5 Check Prometheus monitoring

While still connected to `node01`, run:

```bash
curl -s 'http://localhost:9090/api/v1/query?query=up'
```

The JSON response should include these monitoring targets with a value of `"1"`:

| Target | Meaning |
|---|---|
| `localhost:9090` | Prometheus server |
| `node01:9100` | Node Exporter on node01 |
| `node02:9100` | Node Exporter on node02 |

A value of `1` indicates that Prometheus successfully scraped the target. A value of `0` indicates that the scrape failed.

### 5.6 Check Grafana health

While connected to `node01`, run:

```bash
curl -s http://localhost:3000/api/health
```

The response should contain:

```json
{
  "database": "ok"
}
```

Additional fields, including Grafana's version and commit identifier, may also appear.

This confirms that the Grafana HTTP service and its database are responding.

### 5.7 Exit the virtual machine

Run:

```bash
exit
```

You should now be back in the terminal of your host computer.

The next section explains how to access the Grafana dashboard from a web browser.

## 6. Accessing the Grafana monitoring dashboard

Grafana provides a web-based interface for visualising the performance of the mini-HPC cluster.

The installation automatically configures a dashboard named **Mini-HPC Cluster Monitoring**, which displays CPU, memory and network metrics for both compute nodes.

### 6.1 Find the controller's IP address

On the host computer, from the repository directory, run:

```bash
./get-ips.sh
```

The output displays the current addresses of `node01` and `node02`.

For example:

```text
node01 ansible_host=172.16.15.137 ...
node02 ansible_host=172.16.15.138 ...
```

These are example addresses. Your actual IP addresses may differ.

### 6.2 Access Grafana from the host computer

If your host computer can reach the VMware virtual machine network, open a web browser and navigate to:

```text
http://<NODE01_IP>:3000
```

Replace `<NODE01_IP>` with the actual IP address of `node01`.

For example:

```text
http://172.16.15.137:3000
```

The Grafana login page should appear.

### 6.3 First-time Grafana login

For a new Grafana installation, the default administrator credentials are normally:

- **Username:** `admin`
- **Password:** `admin`

Grafana should prompt you to change the initial administrator password.

Choose a strong password and keep it private. Do not commit passwords or other credentials to the Git repository.

The training environment is intended for trusted networks and should not be exposed directly to the public internet.

### 6.4 Open the monitoring dashboard

After signing in, navigate to:

**Dashboards → Mini-HPC Training → Mini-HPC Cluster Monitoring**

The dashboard contains four panels:

| Panel | Description |
|---|---|
| CPU Utilisation (%) | CPU usage on each compute node |
| Memory Utilisation (%) | Memory usage on each compute node |
| Network Receive (bytes/sec) | Incoming network traffic |
| Network Transmit (bytes/sec) | Outgoing network traffic |

Each panel should display separate metrics for `node01:9100` and `node02:9100`.

The dashboard refreshes automatically every 15 seconds.

Some panels may initially need a few minutes of collected metrics before meaningful graphs appear.

### 6.5 Access Grafana when connecting remotely

If the mini-HPC environment runs on a remote host, the VMware VM addresses may not be directly accessible from your local computer.

In this case, use SSH local port forwarding.

Open a terminal on your **local computer** and run:

```bash
ssh -L 3001:<NODE01_IP>:3000 USER@REMOTE_HOST
```

Replace:

- `<NODE01_IP>` with the controller VM's IP address.
- `USER` with your username on the remote host.
- `REMOTE_HOST` with the remote computer's hostname or IP address.

For example, if the controller IP is `172.16.15.137`:

```bash
ssh -L 3001:172.16.15.137:3000 username@remote-host.example.org
```

Keep this SSH connection open.

On your local computer, open:

```text
http://localhost:3001
```

Your browser connects to the remote Grafana service through the encrypted SSH connection.

If port `3001` is already in use, choose another available local port and update the browser address accordingly.

**Note:** Remote SSH tunnelling requires SSH access to the host computer and network connectivity from that host to the controller VM.

### 6.6 Optional: check Prometheus directly

Prometheus runs on `node01` using port `9090`.

From a terminal inside `node01`, you can check its HTTP interface:

```bash
curl -I http://localhost:9090
```

To access Prometheus in a browser, use:

```text
http://<NODE01_IP>:9090
```

If connecting remotely, you can also forward port `9090` through SSH, following the same approach as for Grafana.

Prometheus provides access to metrics and queries, while Grafana presents those metrics through a more user-friendly dashboard.

## 7. Troubleshooting

This section covers common problems that may occur when deploying or using the mini-HPC cluster.

Unless otherwise stated, run these commands from the `mini-hpc-training` directory on your host computer.

### 7.1 Virtual machines are not running

Check the VM status:

```bash
vagrant status
```

If either VM is stopped, start the virtual machines:

```bash
vagrant up --provider=vmware_desktop
```

To run the complete configuration process again:

```bash
./setup.sh
```

The deployment is designed to be rerunnable. Ansible normally leaves correctly configured resources unchanged.

### 7.2 Ansible cannot connect to a node

Regenerate the inventory:

```bash
./get-ips.sh
```

Test connectivity:

```bash
ansible cluster -m ping
```

Both nodes should return `"ping": "pong"`.

If a node is unreachable, check that it is running and that VMware networking is functioning.

### 7.3 Package installation is slow

During a fresh deployment, installing HPC software can take considerable time.

This depends on the host's internet connection, package repository response times and available system resources.

If installation appears to be stalled, check the package manager inside the affected VM:

```bash
vagrant ssh node01 -c "ps -eo pid,etime,stat,cmd | grep -E '[a]pt|[d]pkg'"
```

Do not remove APT lock files or terminate package management processes without first investigating their state.

If the installation fails, address the reported error before rerunning:

```bash
./setup.sh
```

### 7.4 Slurm does not show both nodes

Connect to the controller:

```bash
vagrant ssh node01
```

Check Slurm:

```bash
sinfo
```

Inspect the node states:

```bash
scontrol show nodes
```

If a node is unavailable, investigate the Slurm services and their logs before restarting anything.

Useful commands include:

```bash
sudo systemctl status slurmctld
sudo systemctl status slurmd
sudo journalctl -u slurmd -n 30 --no-pager
```

The Slurm controller (`slurmctld`) runs only on `node01`, while `slurmd` runs on both nodes.

### 7.5 Grafana dashboard does not display data

First, check the Grafana service on `node01`:

```bash
sudo systemctl status grafana-server
```

Check Prometheus:

```bash
curl -s 'http://localhost:9090/api/v1/query?query=up'
```

Confirm that both `node01:9100` and `node02:9100` report a value of `1`.

If the services are healthy, check the time range selected in Grafana and allow several minutes for metrics to accumulate.

### 7.6 Check service logs

On `node01`, useful diagnostic commands include:

```bash
sudo journalctl -u slurmctld -n 30 --no-pager
sudo journalctl -u prometheus -n 30 --no-pager
sudo journalctl -u grafana-server -n 30 --no-pager
```

On either node:

```bash
sudo journalctl -u munge -n 30 --no-pager
sudo journalctl -u slurmd -n 30 --no-pager
```

These commands display recent service logs without changing the system.

## 8. Stopping and restarting the cluster

When you finish a training session, you can shut down the two virtual machines without deleting them.

From the repository directory on your host computer:

```bash
vagrant halt
```

To restart the existing virtual machines later:

```bash
vagrant up --provider=vmware_desktop
```

To reapply the cluster configuration:

```bash
./setup.sh
```

The VMs retain their installed software and files when halted.

## 9. Removing the training cluster

If you no longer need the virtual machines, you can remove them using Vagrant.

**Warning:** Destroying the virtual machines permanently deletes their local data, including job scripts, output files and Grafana settings stored inside the VMs.

Before proceeding, check that you are in the intended repository directory:

```bash
pwd
vagrant status
```

Review the listed VM names carefully.

To remove the virtual machines associated with the current Vagrant environment:

```bash
vagrant destroy
```

Vagrant will request confirmation for each machine.

Do not run this command from another Vagrant project directory, particularly if that project contains VMs you want to preserve.

The repository's source code remains available after the VMs are destroyed.

To recreate the environment:

```bash
./setup.sh
```

The newly created VMs may receive different IP addresses.

## 10. Next steps

Once your mini-HPC cluster is running, continue with the practical workshop:

**[Hands-on HPC Training Exercises](../exercises/hpc-training.md)**

The exercises introduce Linux basics, Slurm job scheduling, distributed execution and monitoring using Prometheus and Grafana.

Return to the [project README](../README.md) for an overview of the training environment.
