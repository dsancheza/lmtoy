#   tools useful for the script generator (usually called mk_runs.py)
#

import os
import sys

def getpars(on):
    """ get SLpipeline parameters from obsnum.args (deprecated in nov-2022)
        or comments.txt after the '#' symbol
    """
    pars4 = {}
    if os.path.exists("obsnum.args"):
        print("WARNING: obsnum.args is deprecated, please use comments.txt now")
        lines = open("obsnum.args").readlines()
        for line in lines:
            if line[0] == '#': continue
            w = line.split()
            pars4[int(w[0])] = w[1:]
            print('PJT4-deprecated',w[0],w[1:])

    if os.path.exists("comments.txt"):
        lines = open("comments.txt").readlines()
        for line in lines:
            if line[0] == '#': continue
            idx = line.find('#')
            w = line.split()
            if idx > 0:
                pars4[int(w[0])] = line[idx+1:].strip().split()
                # print('PJT4',w[0],line[idx+1:].strip().split())

    return pars4


def getargs(obsnum, pars4):
    """ search for <obsnum> and return the args
    """
    args = ""
    if obsnum in pars4.keys():
        # print("PJT2:",obsnum,pars4[obsnum])
        for a in pars4[obsnum]:
            args = args + " " + a
    return args

#        helper function for populating obsnum dependant argument
def getargs_old(obsnum, flags=True):
    """ search for <obsnum>.args
        and in lmtoy.flags
        ** deprecated **
    """
    args = ""    
    if flags:
        f = 'lmtoy.flags'
        if os.path.exists(f):
            lines = open(f).readlines()
            for line in lines:
                if line[0] == '#': continue
                args = args + line.strip() + " "
        
    f = "%d.args" % obsnum
    if os.path.exists(f):
        lines = open(f).readlines()
        for line in lines:
            if line[0] == '#': continue
            args = args + line.strip() + " "
    return args

def mk_runs(project, on, pars1, pars2):
    """ top level
    """

    run1a = '%s.run1a' % project
    run1b = '%s.run1b' % project
    run2a = '%s.run2a' % project
    run2b = '%s.run2b' % project

    fp1a = open(run1a, "w")
    fp1b = open(run1b, "w")
    fp2a = open(run2a, "w")
    fp2b = open(run2b, "w")


    pars4 = getpars(on)

    # single obsnums
    n1 = 0
    for s in on.keys():
        for o1 in on[s]:
            o = abs(o1)
            cmd1a = "SLpipeline.sh obsnum=%d _s=%s %s restart=1 " % (o,s,pars1[s])
            cmd1b = "SLpipeline.sh obsnum=%d _s=%s %s %s" % (o,s,pars2[s], getargs(o,pars4))
            fp1a.write("%s\n" % cmd1a)
            fp1b.write("%s\n" % cmd1b)
            n1 = n1 + 1

    #                           combination obsnums
    n2 = 0        
    for s in on.keys():
        obsnums = ""
        n3 = 0
        for o1 in on[s]:
            o = abs(o1)
            if o1 < 0: continue
            n3 = n3 + 1
            if obsnums == "":
                obsnums = "%d" % o
            else:
                obsnums = obsnums + ",%d" % o
        print('%s[%d/%d] :' % (s,n3,len(on[s])), obsnums)
        cmd2a = "SLpipeline.sh _s=%s admit=0 restart=1 obsnums=%s" % (s, obsnums)
        cmd2b = "SLpipeline.sh _s=%s admit=1 srdp=1    obsnums=%s" % (s, obsnums)
        fp2a.write("%s\n" % cmd2a)
        fp2b.write("%s\n" % cmd2b)
        n2 = n2 + 1

    print("A proper re-run of %s should be in the following order:" % project)
    print(run1a)
    print(run2a)
    print(run1b)
    print(run2b)
    print("Where there are %d single obsnum runs, and %d combination obsnums" % (n1,n2))
