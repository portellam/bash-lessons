## Description
Scratch space for bash functions
Bash functions that do cool stuff go here

## Useful links:
* https://devhints.io/bash

## NOTES
* function for backups makes a '.old' file
* when making a 'master backup' of a file, name with extension '.bak'

* for manipulating system files, do this
    * create master backup or copy from a good master, save as '.bak'
    * make changes to file
    * exec func for '.old' file

* VFIO setup
    * use arrays and stuff, keys and elements
    * input vars with arguments (blank for all but uninstall, -p for post-install only, -i for install only, -u for uninstall only)
    * additional vars (-m for multiboot, -s for static)
    * output known good PCI info to text file, have ability to parse/read from file (better update method) :)