#!/usr/bin/env bash
#SBATCH --job-name=MDTF-CI
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --output=./%x.%j.out
#SBATCH --constraint=bigmem
#SBATCH --partition=analysis  

# (partiton=analysis needed so that we run on analysis queue for access to 
# /data_cmip6; bigmem not necessary but nice)

# Manual script for "CI" testing of MDTF-diagnostics within GFDL firewall.
# Intended to be submitted as a slurm job from analysis.
# CLI options are name of branch and pod to run.

set -Eeo pipefail
exit_code=0 # for error handling on commands that might fail, since we set -e

REPO_NAME="MDTF-diagnostics"
# use conda envs, data from MDTeam installation
MDTEAM_MDTF="/home/mdteam/DET/analysis/mdtf/${REPO_NAME}"
# path to env module command on analysis; env modules defined as a shell alias
MODULECMD="/usr/local/Modules/default/bin/modulecmd"
# output directory of MDTF script
OUTPUT_DIR="${TMPDIR}/wkdir"

DEFAULT_POD="atmos"
DEFAULT_BRANCH="feature/gfdl-data"

# parse aruments manually
while (( "$#" )); do
    case "$1" in
        -p|--pod)
            if [ -n "$2" ]; then
                POD="$2"
            fi
            shift 2
            ;;
        -b|--branch)
            if [ -n "$2" ]; then
                BRANCH="$2"
            fi
            shift 2
            ;;
        -?*)
            echo "$0: Unknown option (ignored): $1\n" >&2
            shift 1
            ;;
        *) # Default case: No more options, so break out of the loop.
            break
    esac
done
if [ -z "$POD" ]; then
    POD="$DEFAULT_POD"
fi
if [ -z "$BRANCH" ]; then
    BRANCH="$DEFAULT_BRANCH"
fi

# make sure we have git
eval $( "$MODULECMD" bash load git )

# checkout requested branch into $TMPDIR
cd $TMPDIR
git clone --depth 1 --recursive --branch "$BRANCH" "https://gitlab.gfdl.noaa.gov/thomas.jackson/${REPO_NAME}.git" || exit_code=$?
if [ "${exit_code}" -ne 0 ]; then
    echo "ERROR: couldn't checkout branch $BRANCH" >&2
    exit 1
fi
cd "$REPO_NAME"
# check if requested POD exists
if [[ "$POD" != "$DEFAULT_POD" && ! -d "diagnostics/${POD}" ]]; then
    echo "ERROR: can't find POD $POD, instead using default $DEFAULT_POD" >&2
    POD="$DEFAULT_POD"
fi

# activate MDTF framework's conda environment from the MDTeam install
if [ ! -d "$MDTEAM_MDTF" ]; then
    echo "ERROR: can't find MDTeam install at ${MDTEAM_MDTF}" 1>&2
    exit 1
fi
source "${MDTEAM_MDTF}/src/conda/conda_init.sh" "/home/mdteam/anaconda"
conda activate "${MDTEAM_MDTF}/envs/_MDTF_base" || exit_code=$?
if [ "${exit_code}" -ne 0 ]; then
    echo "ERROR: conda activate failed" >&2
    exit 1
fi
mkdir -p "$OUTPUT_DIR" # not strictly necessary

# run script
/usr/bin/env python -m src.mdtf_gfdl -f "${MDTEAM_MDTF}/tests/gfdl_ci_config.jsonc" -o "$OUTPUT_DIR" --pods "$POD" -- 

# test to see if $OUTPUT_DIR has only one subdirectory and no other content
if [ "$( find "$OUTPUT_DIR" -maxdepth 1 -mindepth 1 -printf %y )" = "d" ]; then
    RESULTS_DIR=$( find "$OUTPUT_DIR" -maxdepth 1 -mindepth 1 )
    # run verify_links to determine if all plots created (interpret that as success)
    /usr/bin/env python -m src.verify_links -v "$RESULTS_DIR"
else
    echo "Found unexpected content in $OUTPUT_DIR:"
    ls "$OUTPUT_DIR"
    exit 1
fi
