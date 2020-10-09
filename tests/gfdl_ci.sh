#!/usr/bin/env bash
#SBATCH --job-name=MDTF-CI
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --output=./%x.%j.out
#SBATCH --constraint=bigmem

# Manual script for "CI" testing of MDTF-diagnostics within GFDL firewall.
# Intended to be submitted as a slurm job from analysis.
# Takes one optional argument, the name of the POD to test; otherwise runs all
# PODs in develop branch.

set -Eeo pipefail
set -xv

REPO_NAME="MDTF-diagnostics"
# use conda envs, data from MDTeam installation
MDTEAM_MDTF="/home/mdteam/DET/analysis/mdtf/${REPO_NAME}"
# path to env module command on analysis; env modules defined as a shell alias
MODULECMD="/usr/local/Modules/default/bin/modulecmd"
# output directory of MDTF script
OUTPUT_DIR="${TMPDIR}/wkdir"

DEFAULT_POD="all"
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
git clone --depth 1 --recursive "https://gitlab.gfdl.noaa.gov/thomas.jackson/${REPO_NAME}.git"
cd "$REPO_NAME"
# check if requested branch exists.
git show-ref --verify --quiet "refs/heads/${BRANCH}" || error_code=$?
if [ "${error_code}" -eq 0 ]; then
    git checkout "$BRANCH"
else
    echo "ERROR: can't find branch $BRANCH, using $DEFAULT_BRANCH" >&2
    git checkout "$DEFAULT_BRANCH"
fi
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
conda activate "${MDTEAM_MDTF}/envs/_MDTF_base"
mkdir -p "$OUTPUT_DIR" # not strictly necessary

# run script
/usr/bin/env python -m src.mdtf_gfdl -f "${MDTEAM_MDTF}/tests/gfdl_ci_config.jsonc" -o "$OUTPUT_DIR" --pods "$POD" -- 

# test to see if $OUTPUT_DIR has only one subdirectory and no other content
if [ "$( find "$OUTPUT_DIR" -maxdepth 1 -mindepth 1 -printf %y )" = "d" ]; then
    RESULTS_DIR=$( find "$OUTPUT_DIR" -maxdepth 1 -mindepth 1 )
    # run verify_links to determine if all plots created (interpret that as success)
    if [ ! -x ./src/verify_links.py ]; then
        echo "Couldn't find verify_links.py."
        exit 1
    fi
    ./src/verify_links.py -v "$RESULTS_DIR" || error_code=$?
    if [ "${error_code}" -eq 0 ]; then
        echo "All links found; test completed successfully."
        exit 0
    else
        echo "Error returned by verify_links; test failed."
        exit 1
    fi
else
    echo "Found unexpected content in $OUTPUT_DIR:"
    ls "$OUTPUT_DIR"
    exit 1
fi
