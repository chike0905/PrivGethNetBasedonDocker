import sys
import glob
import re
from datetime import datetime
import pandas as pd

def readfile(filepath):
    try: 
        with open(filepath) as f:
            filestr = f.read()
    except IOError:
        print('ERROR: "%s" cannot be opened.' % filepath)
        quit()
    return filestr

def logline2dt(logline):
    rawdate = "2020" + re.search(r'\[\d{2}-\d{2}\|\d{2}:\d{2}:\d{2}\.\d{3}\]', logline).group()
    dtdate = datetime.strptime(rawdate, '%Y[%m-%d|%H:%M:%S.%f]')
    return dtdate

if __name__ == '__main__':
    # read log files
    args = sys.argv
    logpaths = glob.glob(args[1] + "/logs/*")
    
    # perse log
    loglist = []
    for logpath in logpaths:
        logfname = logpath[len(args[1]+"/logs/"):]
        rawlog = readfile(logpath)
        loglines = rawlog.split("\n")
        for line in loglines:
            if line:
                date = logline2dt(line)
                level = line[:5].strip(" ")
                label = line[26:67].strip()
                info = line[67:]
                log = [logfname, date, level, label, info]
                loglist.append(log)
    
    LogFrame = pd.DataFrame(data=loglist, columns=["Node", "Date", "Level", "lavel", "Info"])
    LogFrame = LogFrame.sort_values('Date')
    LogFrame.to_csv(args[1]+"/logs/mergedlog.csv")

