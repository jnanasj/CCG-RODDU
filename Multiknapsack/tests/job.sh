#!/bin/bash -l        
#SBATCH --time=2:00:00
#SBATCH --ntasks=8
#SBATCH --mem=10g
#SBATCH --tmp=10g
#SBATCH --mail-type=FAIL,END 
#SBATCH --mail-user=jagan024@umn.edu 
module load gurobi/10.0.1
export MODULEPATH=$MODULEPATH:~/module-files
module load julia/1.11.2
julia tests/main.jl