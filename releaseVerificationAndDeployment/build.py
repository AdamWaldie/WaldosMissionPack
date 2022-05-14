#!/usr/bin/env python3

import sys
import os
import argparse
import shutil
import subprocess
import tempfile
import json
import glob
import fileinput

"""
This build script was written by Andras Brostrom - andreas.brostrom.ce@gmail.com

It was provided alongside cScripts under a GNU 3.0 lisence, I claim no rights to this software and provide full credit to Andreas for his excellent work.

"""

__version__ = 3.0

scriptPath  = os.path.realpath(__file__)
scriptRoot  = os.path.dirname(scriptPath)
ProjectRoot = os.path.dirname(os.path.dirname(scriptPath))
os.chdir(ProjectRoot)

releaseFolder = os.path.join(ProjectRoot, 'release')

parser = argparse.ArgumentParser(
    prog='Build',
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description='This script build and pack the selected mission framework.',
    epilog='This build script is primarly built to pack 7th Cavalry Script package; cScripts.\nThe tool should be cross platform and can be used for other packages as well.'
)

parser.add_argument('--build',
    default='',
    help="Add a additional tag to a to the build"
)
parser.add_argument("--deploy",
    help="Deploy mode used by CI deployment.",
    action="store_false"
)
parser.add_argument("--color",
    help="Enable colors in the script.",
    action="store_true"
)
parser.add_argument('-v', '--version', action='version', version='Author: Andreas Broström <andreas.brostrom.ce@gmail.com>\nScript version: {}'.format(__version__))

args = parser.parse_args()


def printC(string='', color='\033[0m', sep=' ', end='\n'):
    if args.color:
        return print('\033[0m{}{}\033[0m'.format(color,string), end=end, sep=sep)
    else:
        return print(string,  end=end, sep=sep)

def check_or_create_folder(dir=''):
    if not os.path.exists(dir):
        os.makedirs(dir)

def print_list_Content(files, directoies):
    printC('\nFound Objects:', color='\033[1m')
    print("  ", end="")
    for obj in directoies:
        objName = os.path.basename(obj)
        printC(objName, end='  ', color='\033[42m')
    for obj in files:
        objName = os.path.basename(obj)
        printC(objName, end='  ', color='\033[96m')
    print()


def get_git_commit_hash(longhash=False):
    commit_hash = ''
    if not os.path.isdir(os.path.join(ProjectRoot, '.git')):
        return commit_hash
    if longhash:
        try:
            commit_hash = subprocess.check_output(['git', 'rev-parse', 'HEAD']).strip()
            return commit_hash.decode("utf-8")
        except:
            return commit_hash
    else: 
        try:
            commit_hash = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).strip()
            return commit_hash.decode("utf-8")
        except:
            return commit_hash


def get_git_branch_name():
    branch_name = ''
    if not os.path.isdir(os.path.join(ProjectRoot, '.git')):
        return branch_name
    try:
        branch_name = subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD']).strip()
        return branch_name.decode("utf-8")
    except:
        return branch_name


def copy_build_content(files, directoies):
    for obj in files:
        objName = os.path.basename(obj)
        print("Featching files", end=' ')
        printC(objName, color='\033[96m', end='')
        print("...")
        shutil.copy2(obj, tmpFolder)

    for obj in directoies:
        objName = os.path.basename(obj)
        print("Featching directories and files from", end=' ')
        printC(objName, color='\033[42m', end='')
        print("...")
        shutil.copytree(obj, os.path.join(tmpFolder, objName))


def write_header_file(content=['{{name}}', '{{version}}', '{{branch}}', '{{hash}}']):
    print('Creating header file...')
    if len(content) != 4:
        printC('ERROR:', color='\033[31m', end=' ')
        print('Header file can\'t be created. Expected 4 list strings got {}. Use following format:'.format(len(content)), ['{{name}}', '{{version}}', '{{branch}}', '{{hash}}'])
        sys.exit(1)
    header = open(os.path.join(tmpFolder, '{}_{}.md'.format(content[0],content[1])), "w+")
    header.write('{} ({})\nrev: {}\nbranch: {}'.format(content[0], content[1], content[3], content[2]))
    header.close()


def manipulate_build(config):
    def replace(file, searchExp, replaceExp):
        print("Replacing", end=' \"')
        printC(searchExp, color='\033[36m', end='\" ')
        print("with", end=' \"')
        printC(replaceExp, color='\033[96m', end='\"')
        print("...")
        for line in fileinput.input(file, inplace=1):
            if searchExp in line:
                line = line.replace(searchExp,replaceExp)
            sys.stdout.write(line)

    def additions(file, searchExp=[]):
        print("Appending", end=' ')
        printC(value, color='\033[36m', end=' ')
        print("to", end=' ')
        printC(filename, color='\033[96m', end=' ')
        print("...")
        with open(file, 'a') as add:
            for n, line in enumerate(searchExp):
                add.write('{}'.format(line))
                if n != (len(searchExp)-1):
                    add.write('\n')
        add.close()

    def remove(file, searchExp=[]):
        for rem in searchExp:
            print("Removing lines containing", end=' ')
            printC(rem, color='\033[36m', end='')
            print("...")
            for line in fileinput.input(file, inplace=1):
                if not rem in line:
                    sys.stdout.write(line)

    print('Making custom build...')
    for filename in config:
        if filename == 'build':
            continue
        if filename == 'patch':
            print("Applying patch file", end=' ')
            printC(config[filename], color='\033[96m', end='')
            print("...")
            filePath = os.path.join(ProjectRoot, config[filename])
            os.chdir(tmpFolder)
            subprocess.call(['git','apply', filePath, '--verbose'])
            os.chdir(ProjectRoot)
            continue
        if (type(config[filename])) is str:
            filePath = os.path.join(tmpFolder, filename)
            if config[filename] == 'REMOVE':
                print("Removing", end=' ')
                printC(filename, color='\033[96m', end='')
                print("...")
                if os.path.exists(filePath):
                    os.remove(filePath)
            continue
        else:
            print("Applying adjustmetns to", end=' ')
            printC(filename, color='\033[96m', end='')
            print("...")
            filePath = os.path.join(tmpFolder, filename)
            for key in config[filename]:
                value = config[filename][key]
                if (type(config[filename][key])) is list:
                    if key == 'add':
                        if len(value) == 0:
                            continue
                        additions(filePath, value)
                        continue
                    if key == 'rem':
                        if len(value) == 0:
                            continue
                        remove(filePath, value)
                        continue
                if (type(config[filename][key])) is str:
                    replace(filePath, key, value)

def make_archive(name='', version='', hash=''):
    print('Making release...')
    if version.upper() == 'DEVBUILD':
        version = '{}-{}'.format(version, hash)
    name = name.replace(' ', '_')
    name = '{}-{}'.format(name, version)

    archive_type = 'zip'
    shutil.make_archive(os.path.join(releaseFolder, name), archive_type, tmpFolder)


def main():
    if args.build:
        if not os.path.isfile(os.path.join(scriptRoot, args.build)):
            printC('ERROR:', color='\033[31m', end=' ')
            print('\'{}\' does not exist'.format(args.build))
            sys.exit(1)
        if 'config.json' in args.build:
            printC('WARNING:', color='\033[93m', end=' ')
            print('\'{}\' looks like the default config.\n'.format(args.build))

    with open(os.path.join(scriptRoot, 'config.json')) as main_config:
        config           = json.load(main_config)
        config_name      = config['build']['scriptName']
        config_version   = config['build']['version']
        config_notlist   = config['build']['notlist']
    
    if args.build:
        with open(os.path.join(scriptRoot, args.build)) as build_config:
            config           = json.load(build_config)
            if config['build'].get('scriptName'):
                config_name      = config['build']['scriptName']
            if config['build'].get('version'):
                config_version   = config['build']['version']
            if config['build'].get('notlist'):
                config_notlist   = config['build']['notlist']


    git_branch_name     = get_git_branch_name()
    git_commit_shash    = get_git_commit_hash(False)
    git_commit_lhash    = get_git_commit_hash(True)

    printC('Preparing build for {}.'.format(config_name),'\033[1m')
    
    # Collect directoies and files
    file_collection = []
    dir_collection  = []
    for obj in glob.glob(os.path.join(ProjectRoot, '*')):
        objName = os.path.basename(obj)
        if objName in config_notlist:
            continue
        if os.path.isdir(obj):
            dir_collection.append(obj)
        if os.path.isfile(obj):
            file_collection.append(obj)
    
    print("  Name:    {}".format(config_name))
    print("  Version: {}".format(config_version))
    if os.path.isdir(os.path.join(ProjectRoot, '.git')):
        print("  Branch:  {}".format(git_branch_name))
        print("  Hash:    {}".format(git_commit_shash))

    # Show files
    print_list_Content(file_collection, dir_collection)

    input('\nPress enter to start the build process...') if args.deploy else True

    global tmpFolder
    tmpFolder = tempfile.mkdtemp()

    copy_build_content(file_collection, dir_collection)

    if args.build:
        manipulate_build(config)

    write_header_file([config_name, config_version, git_branch_name, git_commit_lhash])


    check_or_create_folder(releaseFolder)
    make_archive(config_name, config_version, git_commit_shash)

if __name__ == "__main__":
    sys.exit(main())
