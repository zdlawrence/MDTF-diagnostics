#!/usr/bin/env bash
#SBATCH --job-name=MDTF-CI
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH -o $HOME/mdtf_ci/%x.%j.out
#SBATCH --constraint=bigmem

# Manual script for "CI" testing of MDTF-diagnostics within GFDL firewall.
# Intended to be submitted as a slurm job from analysis.
# Takes one optional argument, the name of the POD to test; otherwise runs all
# PODs in develop branch.

set -Eeo pipefail

# parse aruments manually
POD="all"
BRANCH="develop"
while (( "$#" )); do
    case "$1" in
        ?*)
            # Assume nonempty input is name of POD to test
            if [ -n "$1" ]; then
                POD="$1"
                BRANCH="pod/${1}"
            fi
            shift 1
            ;;
        *) # Default case: No more options, so break out of the loop.
            break
    esac
done

module load git

# checkout requested branch into $TMPDIR
cd $TMPDIR
git clone --depth 1 --branch "$BRANCH" https://gitlab.gfdl.noaa.gov/thomas.jackson/MDTF-diagnostics.git
cd MDTF-diagnostics

# use conda envs, data from MDTeam installation
MDTEAM_MDTF="/home/mdteam/DET/analysis/mdtf/MDTF-diagnostics"
source "${MDTEAM_MDTF}/src/conda/conda_init.sh" "/home/mdteam/anaconda"
conda activate "${MDTEAM_MDTF}/envs/_MDTF_base"

# run script
/usr/bin/env python -m src.mdtf_gfdl --pods "$POD" -- -f "${MDTEAM_MDTF}/tests/gfdl_ci_config.jsonc"
