use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Component::SubWrapper',
    'VERSION_FROM'	=> 'VERSION', # finds $VERSION
    'PREREQ_PM'		=> { 'POE' => 0.23,
                             'Devel::Symdump' => 2.01,
			     'Test::More' => 0.08,
			   },
    'dist' => { 'COMPRESS' => 'gzip -9f',
                'SUFFIX' => 'gz',
              },
    'AUTHOR' => 'sungo (eek+cpan@eekeek.org)',
    'ABSTRACT' => 'Event based module interface',
);
