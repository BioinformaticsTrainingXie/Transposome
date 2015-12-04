Transposome
===========

Annotation of transposable element families from unassembled sequence reads

[![Build Status](https://travis-ci.org/sestaton/Transposome.png?branch=master)](https://travis-ci.org/sestaton/Transposome)

### What is Transposome?

Transposome is a command line application to annotate [transposable elements](http://en.wikipedia.org/wiki/Transposable_element) from paired-end whole genome shotgun data. There are many tools to estimate the mathematical nature of repeats from short sequence reads. There are also a number of tools for analyzing repeats directly from a genome assembly. This tool allows you to infer the abundance of repeat types in the genome without a reference genome sequence. The output files make it easy to quickly summarize genomic abundance by transposable element class, superfamily, family, or any other level of the repeat taxonomy.

There is also a Perl API which allows you to build custom analysis pipelines, repeat stages of the analysis, or test a range of parameter values for each phase of Transposome (see the [API Tutorial](https://github.com/sestaton/Transposome/wiki/API-Tutorial) page for more information and the [transposome-scripts](https://github.com/sestaton/transposome-scripts) repository).

**DEPENDENCIES**

To use Transposome, you will need Perl installed (version 5.10 or greater) and it is very simple to install Perl with a tool called perlbrew. A [step-by-step set of instructions](https://github.com/sestaton/Transposome/wiki/Installing-dependencies#installing-perl) is provided for installing a recent version of Perl. That wiki page also explains the commands below.

**INSTALLATION**

Note that the following commands assume a fresh cloud instance with no compilers or libraries installed. There are only a couple of steps, but please be advised that it can take a little while (perhaps 20 minutes) to compile the dependencies.

For Ubuntu/Debian as the OS:

    apt-get install -y build-essential lib32z1 git ncbi-blast+ curl
    curl -L cpanmin.us | perl - git://github.com/sestaton/Transposome.git

For RHEL/Fedora:

    yum groupinstall "Development Tools"
    yum install -y glibc.i686 gcc-c++ git ncbi-blast+
    curl -L cpanmin.us | perl - git://github.com/sestaton/Transposome.git

It is **highly** recommended that you use these methods to install and update Transposome and not try to install manually. However, if you run into issues, it is possible to download the latest [release](https://github.com/sestaton/Transposome/releases) and install manually (see the [troubleshooting](https://github.com/sestaton/Transposome/wiki/Troubleshooting) page for more information) with the following commands.

    tar xzf Transposome.tar.gz
    cd Transposome
    curl -L cpanmin.us | perl - --installdeps .
    perl Makefile.PL
    make
    make test
    make install 

These steps will give a clear indication of any issues. Updating your installation can be achieved by simply running the same commands. Please report any issues.

**BASIC USAGE**

Following installation, get the Transposome configuration file:

    curl -L tr.im/transposomeconfig > transposome_config.yml 

Next, edit the configuration file by specifying the location of data files and parameters for analysis. Note that if you downloaded manually, a configuration file can be found in the 'config' directory, or the configuration file on the [Quick Start](https://github.com/sestaton/Transposome/wiki/Quick-Start) page can be copied into a text editor and saved locally. It makes no difference which way you create the configuration file, though the `curl` method is faster.

Then, simply run the `transposome` program, specifying your configuration file:

    transposome --config transposome_config.yml

The name of the configuration file does not matter, this is just an example. Though, the format is important. It is also possible to [run individual steps of the analysis](https://github.com/sestaton/Transposome/wiki/Running-some-or-all-of-the-analysis-steps) from the command line. See the [Quick Start](https://github.com/sestaton/Transposome/wiki/Quick-Start) wiki page for more details.

**ADVANCED USAGE**

It is possible to run only one part of the Transposome package, the clustering methods for example, or create 
your own analysis methods to plug into Transposome. In addition, you can extend existing methods.

For all available methods, simply type `perldoc` followed by the name of the class you are interested in 
using. For example,

    perldoc Transposome::Cluster

Available classes are: 

    Transposome
    Transposome::Annotation
    Transposome::Cluster
    Transposome::PairFinder
    Transposome::SeqFactory
    Transposome::SeqUtil
    Transposome::Run::Blast
                      

**SUPPORT AND DOCUMENTATION**

You can get usage information at the command line with the following command:

    perldoc transposome 

The `transposome` program will also print a diagnostic help message when executed with no arguments.

You can also look for information at:

    Transposome wiki
        https://github.com/sestaton/Transposome/wiki

    Transposome issue tracker
        https://github.com/sestaton/Transposome/issues

**CITATION**

Transposome is published in the journal *Bioinformatics*, and if you use this software in your work please use the following citation:

    Staton SE, and Burke JM. 2015. Transposome: A toolkit for annotation of transposable element families from unassembled sequence reads
        Bioinformatics, 31:1827-1829.

**LICENSE AND COPYRIGHT**

Copyright (C) 2013-2015 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: http://www.opensource.org/licenses/mit-license.php

