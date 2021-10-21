# Testing whether SLURM Job Steps can share resources

The `batch.sh` has a comment that explains what's going on.

Run like so

```bash
sbatch batch.sh
```

`batch.sh` calls `script.sh` to see processes etc.

For this example, it is important that the machine this is tested on,
Traverse, has 4 GPUs per node. The goal is two run two Job Steps
(2 `srun`'s ) each requiring 6 GPUs, for a total requirement of 12.
Ideally, the Job should have the two Job Steps share one node's GPUs
so that

```
Job Step 1: [4 GPUs from node 1, 2 GPUs from node 2]
Job Step 2: [2 GPUs from node 2, 4 GPUs from node 4]
```

However, I have tried it with several setups and it does not seem to
be possible. The only workaround is having to use 4 nodes
(16 GPUs, 2 nodes per job step, 3 GPUs per node), and having
4 GPUs sit idle.


Any help/solutions would be amazing. I do believe this should be
possible.


What `batch.sh` attempts: The first step is to get the actual
nodelist. We try this using two different ways. `cyclic` takes
the 3 nodes and creates lists [1,2,3,1,2,3], [1,2,3,1,2,3], and
`block` [1,1,1,1,2,2], [2,2,3,3,3,3]. It turns out that the `block`
way does not work at all because it's not even submitting the
first job step.

Then, we export the `SLURM_HOSTFILE` location, set distribution to
arbitrary

```
export SLURM_HOSTFILE=host1.list
srun -n 6 --cpus-per-task=1 --gpus-per-task 1 --distribution=arbitrary script.sh 0 &
```

Note how the `SLURM_HOSTFILE` is used to make the arbitrary assignment and
how the arbitrary distribution is invoked using `--distribution=arbitrary`.

Both jobs are submitted successfully and use the hostfile. They are just
not submitted simultaneously.

---

Check whether the job steps have been submitted almost at the same time.

```bash
sacct --format JobID%20,Start,End,Elapsed,ReqCPUS,JobName%20, -j <job-id>
```

Note that, I make the second job start 7 seconds after the other by definition
in `script.sh`, just to control the printing. But if the jobs are started sequentially
the difference is over a minute.


Check output

```bash
cat mixed_gpu.txt
```