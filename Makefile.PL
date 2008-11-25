use 5.000000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Pairtree',
    #EXE_FILES         => [ 'pt' ],
    #VERSION_FROM      => 'lib/Pairtree.pm',    # finds $VERSION
    VERSION_FROM      => 'VERSION',    # finds $VERSION
    #VERSION           => '0.1',
    PREREQ_PM         => {
	#'File::Path'		=> '0',		# ??? XXXX
	#'File::Find'		=> '0',		# ??? XXXX
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/Pairtree.pm', # get abstract from moduleXXX
       AUTHOR         => 'John Kunze <jak@ucop.edu>') : ()),
);
