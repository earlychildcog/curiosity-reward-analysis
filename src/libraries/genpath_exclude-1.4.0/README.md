Executes like genpath, but can ignore directories. Useful to add a directory hierarchy to your path, but ignore CM directories such as "CVS" or ".svn"

Directories may be excluded using regular-expressions as well.

Tested on windows only, but should work on any platform.

Example usage:  
genpath\_exclude('C:\myDir',{'CVS'}) %\<--- simple usage to ignore CVS direcotries

genpath\_exclude('C:\myDir',{'\.svn'}) %\<--- simple usage to ignore .svn (note that "." must be escaped for proper handling in the regexp)

genpath\_exclude('C:\myDir',{'CVS','#.\*'}) %\<----more advanced usage to ignore CVS directories and any directory starting with "#"