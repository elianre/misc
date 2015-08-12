#!/usr/bin/env python

# uncompress any tar liked file!

import os, sys
import subprocess
from optparse import OptionParser

file_map = {
            "POSIX tar archive (GNU)": "tar xvf",
            "gzip compressed data": "tar -xvzf",
            "bzip2 compressed data": "tar -xvjf",
            "compress'd data 16 bits": "tar -xvZf",
            "RAR archive data": "unrar e -o+",
            "XZ compressed data":  "tar -xvf"
        }


def uncompress(path):
    if os.path.exists(path) and os.path.isfile(path):
        cmd = 'file %s' % path
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        ret = p.stdout.read()
        p.wait()
        if p.returncode != 0:
            print "ERROR: Got exit code %d of executing '%s'" % (p.returncode, cmd)
            sys.exit(1)

        file_type = ret[len(path)+2:-1].split(',')[0]
        if not file_map.has_key(file_type):
            print "ERROR: File %s(%s) is not supported yet!" % (path, file_type)
            sys.exit(1)

        dir_path = os.path.dirname(path)
        print "Uncompress '%s' at '%s'..." % (path, dir_path)
        cwd = os.getcwd()
        os.chdir(dir_path)
        ret = os.system("%s %s" % (file_map[file_type], os.path.basename(path)))
        if not ret == 0:
            print "ERROR: exit code %n" % ret
        os.chdir(cwd)
    else:
        print "ERROR: '%s' is not a valid path" % path
        sys.exit(1)


if __name__ == "__main__":
    parser = OptionParser(usage="%prog FILE1 FILE2 ...", version="%prog 1.0")
    (options, args) = parser.parse_args()

    if not args:
        print parser.get_usage()

    for path in args:
        uncompress(path)
