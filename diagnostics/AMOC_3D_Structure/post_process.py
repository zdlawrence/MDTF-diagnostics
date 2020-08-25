#============================================================
# execute_ncl_calculate - call a nclPlotFile via subprocess call
#============================================================
def execute_ncl_calculate(nclPlotFile):
    """generate_plots_call - call a nclPlotFile via subprocess call

    Arguments:
    nclPlotFile (string) - full path to ncl plotting file name
    """
    import subprocess
    # check if the nclPlotFile exists -
    # don't exit if it does not exists just print a warning.
    try:
        pipe = subprocess.Popen(['ncl -Q {0}'.format(nclPlotFile)], shell=True, stdout=subprocess.PIPE)
        output = pipe.communicate()[0]
        print('NCL routine {0} \n {1}'.format(nclPlotFile,output))
        while pipe.poll() is None:
            time.sleep(0.5)
    except OSError as e:
        print('WARNING',e.errno,e.strerror)

    return 0
