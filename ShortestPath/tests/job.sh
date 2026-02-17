#!/bin/bash -l        
#SBATCH --time=24:00:00
#SBATCH --ntasks=16
#SBATCH --mem=50g
#SBATCH --tmp=50g
#SBATCH --mail-type=FAIL,END 
#SBATCH --mail-user=jagan024@umn.edu 
module load gurobi
export MODULEPATH=$MODULEPATH:~/module-files
module load julia
julia tests/main.jl $SLURM_ARRAY_TASK_ID