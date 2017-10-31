import os, sys, time, re, string, types
from debug import utils_traceback
import linecache
from datetime import datetime

Debug = True
#Debug = False
DebugLevel = 10
exceptions_file = '/var/log/debug.log'
DefaultLevel = 5

def make_datetime(str):
    data1 = str.split()
    if re.search('-', data1[0]):
        data2 = data1[0].split('-')
    else:
        data2 = data1[0].split('/')
    data3 = data1[1].split(':')
    return datetime(int(data2[0]), int(data2[1]), int(data2[2]), int(data3[0]), int(data3[1]), int(data3[2]))

def getCurrentTime():
    current_time = time.time()
    current_int_time = int(current_time)
    delta_time = current_time-current_int_time
    power_of_10 = 6
    multiplier = 10**power_of_10
    return time.strftime('%Y-%m-%d:%H:%M:%S', time.localtime(time.time()))+('.%0*.0f' % (power_of_10, multiplier*delta_time))

def get_file_lineno():
    try:
        raise ZeroDivisionError
    except ZeroDivisionError:
        f = sys.exc_info()[2].tb_frame.f_back
    limit = None
    list = []
    n = 0
    while f is not None and (limit is None or n < limit):
        lineno = f.f_lineno
        co = f.f_code
        filename = co.co_filename
        name = utils_traceback.guess_full_method_name(f)
        linecache.checkcache(filename)
        line = linecache.getline(filename, lineno)
        if line: line = line.strip()
        else: line = None
        list.append((filename, lineno, name, line))
        f = f.f_back
        n = n+1
    list.reverse()
    return list

def file_lineno_module(list, depth=1):
    return_string = '';
    for i in range(len(list)-2, max(0, len(list)-2-depth), -1):
        return_string += '%s line %s %s' % (os.path.basename(list[i][0]), list[i][1], list[i][2])
        if depth > 1:
          return_string += ";"
    return return_string

# edit this value and change DebugLevel to something new, or put this call in your code with
def file_nolineno_module(list, depth=1):
    return_string = '';
    for i in range(len(list)-2, max(0, len(list)-2-depth), -1):
        return_string += '{0} ({1}) '.format(os.path.basename(list[i][0]), list[i][2])
    return return_string

# a new DebugLevel
def change_debug_level(new_debug_level):
    global DebugLevel
    DebugLevel = new_debug_level

def Traceback(*args, **kwargs):
    if Debug and ((not hasattr(kwargs, 'level') and DefaultLevel <= DebugLevel) or (hasattr(kwargs, 'level') and kwargs['level'] <= DebugLevel)):
        if hasattr(kwargs, 'file'):
            outfile = open(kwargs['file'], 'a')
        elif hasattr(kwargs, 'log') and kwargs['log'] == 0:
            outfile = sys.stdout
        else:
            outfile = open(exceptions_file, 'a')
        data = repr(utils_traceback.format_stack()).replace("['  ",'').replace(']','').split("\\n', '  ")
        if not hasattr(kwargs, 'depth'):
            depth = len(data)+1
        else: 
            depth = kwargs['depth']
        if args:
            values = data[len(data)-2].split('\\n')[0].split(', ')
            line_parts = values[0].replace('"', '').split('/')
            for arg in args:
                print('%s:' % getCurrentTime(), line_parts[len(line_parts)-1], values[1], values[2].replace('in ',''), end=' ', file=outfile)
                print(arg, file=outfile)
        print('%s: Trace begun' % getCurrentTime(), file=outfile)
        for i in range(len(data)-2,len(data)-depth-2,-1):
           values = data[i].split('\\n')[0].split(', ')
           line_parts = values[0].replace('"', '').split('/')
           print('%s:' % getCurrentTime(), line_parts[len(line_parts)-1], values[1], values[2].replace('in ',''), file=outfile)
        print('%s: Trace complete' % getCurrentTime(), file=outfile)
        if not hasattr(kwargs, 'log') or kwargs['log'] != 0:
          outfile.close()

# pass in parameter level=? where ? is a number to change whether the debug data is printed.
# anything less than or equal to the value defined by DebugLevel will cause the debug data
# to be printed.  by default, any call to print_debug without the level parameter set will
# result in the level to be equal to DefaultLevel
def Log(*args, **kwargs):
    if Debug and ((not hasattr(kwargs, 'level') and DefaultLevel <= DebugLevel) or (hasattr(kwargs, 'level') and kwargs['level'] <= DebugLevel)):
        list = get_file_lineno()
        if not hasattr(kwargs, 'depth'):
            depth = 1
        else: 
            depth = kwargs['depth']
        if hasattr(kwargs, 'file'):
            outfile = open(kwargs['file'], 'a')
        else:
            outfile = open(exceptions_file, 'a')
        count = 0
        while True:
          if hasattr(kwargs, 'no_time') and kwargs['no_time'] == True:
              if hasattr(kwargs, 'no_line_no') and kwargs['no_line_no'] == True:
                  print(file_nolineno_module(list, depth), end=' ', file=outfile)
              else:
                  print(file_lineno_module(list, depth), end=' ', file=outfile)
          else:
              if hasattr(kwargs, 'no_line_no') and kwargs['no_line_no'] == True:
                  print('%s:' % getCurrentTime(), file_nolineno_module(list, depth), end=' ', file=outfile)
              else:
                  print('%s:' % getCurrentTime(), file_lineno_module(list, depth), end=' ', file=outfile)
          if len(args) == 0:
              print('', file=outfile)
              break
          print(args[count], file=outfile)
          count += 1
          if count >= len(args):
            break
        outfile.close()

# pass in parameter level=? where ? is a number to change whether the debug data is printed.
# anything less than or equal to the value defined by DebugLevel will cause the debug data
# to be printed.  by default, any call to print_debug without the level parameter set will
# result in the level to be equal to DefaultLevel
def Print(*args, **kwargs):
    if Debug and ((not hasattr(kwargs, 'level') and DefaultLevel <= DebugLevel) or (hasattr(kwargs, 'level') and kwargs['level'] <= DebugLevel)):
        list = get_file_lineno()
        if not hasattr(kwargs, 'depth'):
            depth = 1
        else: 
            depth = kwargs['depth']
        if hasattr(kwargs, 'no_time') and kwargs['no_time'] == True:
            if hasattr(kwargs, 'no_line_no') and kwargs['no_line_no'] == True:
                print(file_nolineno_module(list, depth), end=' ')
            else:
                print(file_lineno_module(list, depth), end=' ')
        else:
            if hasattr(kwargs, 'no_line_no') and kwargs['no_line_no'] == True:
                print('%s:' % getCurrentTime(), file_nolineno_module(list, depth), end=' ')
            else:
                print('%s:' % getCurrentTime(), file_lineno_module(list, depth), end=' ')
        for arg in args:
            print(arg)
        print('')

def intSort(a, b):
    if a > b:
        return 1
    elif b > a:
        return -1
    else:
        return 0

def tupleSort(a, b):
    if a[0] > b[0] or \
       a[0] == b[0] and a[1] > b[1]:
        return 1
    elif a[0] == b[0] and a[1] == b[1]:
        return 0
    else:
        return -1

def caseInsensitiveSort(a, b):
    if a.upper() > b.upper():
        return 1
    elif b.upper() > a.upper():
        return -1
    else:
        return 0

def DumpClass(in_class, exclude_list=[], log=1, **kwargs):
    if log == 1:
        outfile = open(exceptions_file, 'a')
        list = get_file_lineno()
        if not hasattr(kwargs, 'depth'):
            depth = 1
        else: 
            depth = kwargs['depth']
        if hasattr(kwargs, 'no_time') and kwargs['no_time'] == True:
            if hasattr(kwargs, 'no_line_no') and kwargs['no_line_no'] == True:
                print(file_nolineno_module(list, depth), end=' ', file=outfile)
            else:
                print(file_lineno_module(list, depth), end=' ', file=outfile)
        else:
            if hasattr(kwargs, 'no_line_no') and kwargs['no_line_no'] == True:
                print('%s:' % getCurrentTime(), file_nolineno_module(list, depth), end=' ', file=outfile)
            else:
                print('%s:' % getCurrentTime(), file_lineno_module(list, depth), end=' ', file=outfile)
    else:
        outfile = sys.stdout
    print(in_class, file=outfile)
    attrs = dir(in_class)
    attrs.sort(caseInsensitiveSort)
    for attr in attrs:
        result = getattr(in_class, attr)
        print("\t", "%-30.30s" % attr, type(result), end=' ', file=outfile)
        if not attr in exclude_list and \
           type(result) != types.InstanceType and \
           type(result) != types.MethodType:
           print(result, end=' ', file=outfile)
        print('', file=outfile)
