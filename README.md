# Testing whether SLURM Job Steps can share resources

The `batch.sh` has a comment that explains what's going on.

Run like so

```bash
sbatch batch.sh
```

`batch.sh` calls `script.sh` to see processes etc.

For this example, it is important that the machine this is tested on,
Traverse, has 4 GPUs per node. The goal is two run two Job Steps
(2 `srun`'s ) one each requiring 4 GPUs or one requireing 2 and the other one 6, 
for a total requirement of 12. Ideally, the Job should have the two 
Job Steps share their GPUs so that they run concurrently.

This **_does_** work on Andes (ORNL) and Expanse (SDSC).

## `batch.sh` Setup


`batch.sh` runs two jobs, which take the assigned nodes and create
host files dynamically with cyclic task assignment and block assignment.
Both should work. Host files are assign so that one task is assign to one node.

In brackets the nodes that the GPUs are taken from 

```
# Cyclic
Job Step 1: [1,2,1,2]
Job Step 2: [1,2,1,2]

# Block and heterogeneous
Job Step 1: [1,1]
Job Step 2: [1,1,2,2,2,2]
```

```bash
my_srun() {
    # $1 is hosfile
    # $2 is task/gpu count
    export SLURM_HOSTFILE="$1"
    srun -n $2 --gpus=$2 --cpus-per-task=1 --gpus-per-task=1 --distribution=arbitrary script.sh 
}
```

`my_srun` exports the input `SLURM_HOSTFILE` location, and runs 
a test script with the input number tasks/gpus. The important flag
is `--distribution=arbitrary`, which invokes the arbitrary assignment 
of tasks.

All job steps are submitted successfully, but not simulatenously on Traverse.

---

Check for ok submission by

```bash
$ for file in *out; do echo $file; cat $file; done
```

Expected output from Andes

<details>
  
```
block.1.out
143526.0.0 START Mon Oct 25 19:13:13 EDT 2021 @ andes-gpu5.olcf.ornl.gov: 0,1
143526.0.1 START Mon Oct 25 19:13:13 EDT 2021 @ andes-gpu5.olcf.ornl.gov: 0,1
143526.0.2 START Mon Oct 25 19:13:13 EDT 2021 @ andes-gpu6.olcf.ornl.gov: 0
143526.0.0 STOP Mon Oct 25 19:14:13 EDT 2021
143526.0.1 STOP Mon Oct 25 19:14:13 EDT 2021
143526.0.2 STOP Mon Oct 25 19:14:13 EDT 2021
block.2.out
143526.1.0 START Mon Oct 25 19:13:13 EDT 2021 @ andes-gpu6.olcf.ornl.gov: 1
143526.1.0 STOP Mon Oct 25 19:14:13 EDT 2021
cyclic.1.out
143526.2.1 START Mon Oct 25 19:14:13 EDT 2021 @ andes-gpu6.olcf.ornl.gov: 0
143526.2.0 START Mon Oct 25 19:14:13 EDT 2021 @ andes-gpu5.olcf.ornl.gov: 0
143526.2.1 STOP Mon Oct 25 19:15:13 EDT 2021
143526.2.0 STOP Mon Oct 25 19:15:13 EDT 2021
cyclic.2.out
143526.3.1 START Mon Oct 25 19:14:13 EDT 2021 @ andes-gpu6.olcf.ornl.gov: 1
143526.3.0 START Mon Oct 25 19:14:13 EDT 2021 @ andes-gpu5.olcf.ornl.gov: 1
143526.3.1 STOP Mon Oct 25 19:15:13 EDT 2021
143526.3.0 STOP Mon Oct 25 19:15:13 EDT 2021
```
  
</details>

Note, the numbers after the colon which show the `$CUDA_VISIBLE_DEVICES`. Also, 
note, how `block1.1.out` and `block1.2.out` have the same `START` times, 
and `cyclic.1.out` and `cyclic.2.out` as well. 

I added a second set of assignments where slurm takes care of the assignment.
Meaning, I'm not specifiying any hostfile that manually assigns tasks to a specific host.
The commands are defined as

```bash
# Runs two jobsteps with each 4 tasks and 1 gpu per task
normal_no_host() {...}

# Runs two jobsteps with one with 2 tasks and one with 6 tasks, each with 1 gpu per task
block_no_host() {...}
```

So, each function should run a total of 8 tasks simultaneously.

Check output files like so:

```bash
for file in nohost*out; do echo $file; cat $file; done
```

The wanted ouput from Traverse looks as follows

<details>

```
nohost.block.1.out
287363.6.0 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g1: CPUs=pid 928746's current affinity list: 0-3, GPU-PCI-ID: 00000004:04:00.0
287363.6.5 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g2: CPUs=pid 897493's current affinity list: 8-11, GPU-PCI-ID: 00000035:03:00.0
287363.6.2 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g1: CPUs=pid 928749's current affinity list: 8-11, GPU-PCI-ID: 00000035:03:00.0
287363.6.1 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g1: CPUs=pid 928748's current affinity list: 4-7, GPU-PCI-ID: 00000004:05:00.0
287363.6.3 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g2: CPUs=pid 897491's current affinity list: 0-3, GPU-PCI-ID: 00000004:04:00.0
287363.6.4 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g2: CPUs=pid 897492's current affinity list: 4-7, GPU-PCI-ID: 00000004:05:00.0
287363.6.2 STOP Fri Feb 11 15:09:40 EST 2022
287363.6.0 STOP Fri Feb 11 15:09:40 EST 2022
287363.6.1 STOP Fri Feb 11 15:09:40 EST 2022
287363.6.5 STOP Fri Feb 11 15:09:40 EST 2022
287363.6.3 STOP Fri Feb 11 15:09:40 EST 2022
287363.6.4 STOP Fri Feb 11 15:09:40 EST 2022
nohost.block.2.out
287363.7.0 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g1: CPUs=pid 928747's current affinity list: 12-15, GPU-PCI-ID: 00000035:04:00.0
287363.7.1 START Fri Feb 11 15:08:40 EST 2022 @ traverse-k05g2: CPUs=pid 897490's current affinity list: 12-15, GPU-PCI-ID: 00000035:04:00.0
287363.7.0 STOP Fri Feb 11 15:09:40 EST 2022
287363.7.1 STOP Fri Feb 11 15:09:40 EST 2022
nohost.normal.1.out
287363.5.2 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g2: CPUs=pid 897323's current affinity list: 8-11, GPU-PCI-ID: 00000035:03:00.0
287363.5.3 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g2: CPUs=pid 897324's current affinity list: 12-15, GPU-PCI-ID: 00000035:04:00.0
287363.5.1 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g1: CPUs=pid 928617's current affinity list: 12-15, GPU-PCI-ID: 00000035:04:00.0
287363.5.0 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g1: CPUs=pid 928616's current affinity list: 8-11, GPU-PCI-ID: 00000035:03:00.0
287363.5.2 STOP Fri Feb 11 15:08:39 EST 2022
287363.5.3 STOP Fri Feb 11 15:08:39 EST 2022
287363.5.0 STOP Fri Feb 11 15:08:39 EST 2022
287363.5.1 STOP Fri Feb 11 15:08:39 EST 2022
nohost.normal.2.out
287363.4.3 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g2: CPUs=pid 897321's current affinity list: 4-7, GPU-PCI-ID: 00000004:05:00.0
287363.4.2 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g2: CPUs=pid 897320's current affinity list: 0-3, GPU-PCI-ID: 00000004:04:00.0
287363.4.1 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g1: CPUs=pid 928619's current affinity list: 4-7, GPU-PCI-ID: 00000004:05:00.0
287363.4.0 START Fri Feb 11 15:07:39 EST 2022 @ traverse-k05g1: CPUs=pid 928618's current affinity list: 0-3, GPU-PCI-ID: 00000004:04:00.0
287363.4.2 STOP Fri Feb 11 15:08:39 EST 2022
287363.4.3 STOP Fri Feb 11 15:08:39 EST 2022
287363.4.0 STOP Fri Feb 11 15:08:39 EST 2022
287363.4.1 STOP Fri Feb 11 15:08:39 EST 2022
```

</details>



Previously, these two sets of submission wouldn't work correctly/I didn't know
how to properly assign the gpus and the tasks (due to the hardware threads).
The unexpected/unwanted output on Traverse.



<details>

```bash
block.1.out
srun: Job 258710 step creation temporarily disabled, retrying (Requested nodes are busy)
srun: Step created for job 258710
258710.3.3 START Mon Oct 25 19:40:25 EDT 2021 @ traverse-k05g2: 0
258710.3.2 START Mon Oct 25 19:40:25 EDT 2021 @ traverse-k05g2: 0
258710.3.0 START Mon Oct 25 19:40:25 EDT 2021 @ traverse-k05g2: 0
258710.3.1 START Mon Oct 25 19:40:25 EDT 2021 @ traverse-k05g2: 0
258710.3.5 START Mon Oct 25 19:40:25 EDT 2021 @ traverse-k05g3: 0
258710.3.4 START Mon Oct 25 19:40:25 EDT 2021 @ traverse-k05g3: 0
258710.3.0 STOP Mon Oct 25 19:41:25 EDT 2021
258710.3.1 STOP Mon Oct 25 19:41:25 EDT 2021
258710.3.2 STOP Mon Oct 25 19:41:25 EDT 2021
258710.3.3 STOP Mon Oct 25 19:41:25 EDT 2021
258710.3.4 STOP Mon Oct 25 19:41:25 EDT 2021
258710.3.5 STOP Mon Oct 25 19:41:25 EDT 2021
block.2.out
258710.2.0 START Mon Oct 25 19:39:24 EDT 2021 @ traverse-k05g3: 0
258710.2.1 START Mon Oct 25 19:39:24 EDT 2021 @ traverse-k05g3: 0
258710.2.0 STOP Mon Oct 25 19:40:24 EDT 2021
258710.2.1 STOP Mon Oct 25 19:40:24 EDT 2021
cyclic.1.out
258710.0.1 START Mon Oct 25 19:37:23 EDT 2021 @ traverse-k05g3: 0
258710.0.0 START Mon Oct 25 19:37:23 EDT 2021 @ traverse-k05g2: 0
258710.0.3 START Mon Oct 25 19:37:23 EDT 2021 @ traverse-k05g3: 0
258710.0.2 START Mon Oct 25 19:37:23 EDT 2021 @ traverse-k05g2: 0
258710.0.1 STOP Mon Oct 25 19:38:23 EDT 2021
258710.0.3 STOP Mon Oct 25 19:38:23 EDT 2021
258710.0.0 STOP Mon Oct 25 19:38:23 EDT 2021
258710.0.2 STOP Mon Oct 25 19:38:23 EDT 2021
cyclic.2.out
srun: Job 258710 step creation temporarily disabled, retrying (Requested nodes are busy)
srun: Step created for job 258710
258710.1.0 START Mon Oct 25 19:38:24 EDT 2021 @ traverse-k05g2: 0
258710.1.1 START Mon Oct 25 19:38:24 EDT 2021 @ traverse-k05g3: 0
258710.1.2 START Mon Oct 25 19:38:24 EDT 2021 @ traverse-k05g2: 0
258710.1.3 START Mon Oct 25 19:38:24 EDT 2021 @ traverse-k05g3: 0
258710.1.0 STOP Mon Oct 25 19:39:24 EDT 2021
258710.1.2 STOP Mon Oct 25 19:39:24 EDT 2021
258710.1.1 STOP Mon Oct 25 19:39:24 EDT 2021
258710.1.3 STOP Mon Oct 25 19:39:24 EDT 2021
```

</details>

It almost looks like there is a misunderstanding of slurm in terms of `CUDA_VISIBLE_DEVICES`?

