use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Component::SubWrapper',
    'VERSION_FROM'	=> 'SubWrapper.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'POE' => 0.11,
                             'Devel::Symdump' => 2.01
			   },
    'dist' => { 'COMPRESS' => 'gzip -9f',
                'SUFFIX' => 'gz',
              },
    'AUTHOR' => 'Michael Stevens <michael@etla.org>',
    'PM' => {'SubWrapper.pm' => '${INST_LIBDIR}/SubWrapper.pm'},
    'ABSTRACT' => 'Event based module interface',
);
