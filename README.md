# NAME

ec2-cssh - Cluster SSH your EC2 instances

# INSTALLATION

This is a standard Perl package.

On system Perl:

    cpan -i App::EC2Cssh

With cpanm:

    cpanm App::EC2Cssh

# SYNOPSIS

Cssh using a predefined set called 'frontend' in your config file (see CONFIGURATION section):

    ec2-ssh -s=frontends

# OPTIONS

- --set=<name>, -s=<name>

    **Required.** Use the set <name> of instances defined in your config file

- --verbose, -v

    Go in verbose mode

- --config=<config file>, -c=<config file>

    Use the config file instead of the automatically detected one (see CONFIGURATION section)

- --help, -h

    Display this help.

# CONFIGURATION

ec2-cssh relies on a configuration files to hold your Amazon AWS EC2 settings, your machine set settings
and the command line to use to ClusterSSH onto your machines.

If no --config option is given, ec2-cssh will look for the following files in order: **.ec2ssh.conf**, **$HOME/.ec2ssh.conf**, **/etc/ec2ssh.conf**

## Linux Config example:

In this example, only one instances set 'mytagvalue' defined. This
set will generate all the instances with a tag 'mytag' having a value 'myvalue'

    {
       'ec2_config' => {
           AWSAccessKeyId => '.. Your access Key ID ..',
           SecretAccessKey => '.. Your secret access Key ..',
           region => 'eu-west-1',
           debug => 0,
       },
       'ec2_sets' => {
           'mytagvalue' => {
               'Filter' =>  [
                   [ 'tag:mytag' , 'myvalue' ],
               ]
           }
       },
       'command' => q|cssh { join(' ' , map{ '<your username>@'.$_.':22' }  @hosts ) }|
     }

Then you can do:

    $ ec2-ssh -s=mytagvalue

## OSX Config example:

Only the command changes. See Section 'INSTALLING cssh' for more help on
CsshX for Mac OSX.

    {
       .. Same a Linux. Only this changes: ..
       'command' => q|csshX --screen 1 { join(' ' , map{ '<your username>@'.$_.':22' }  @hosts ) }|
    }

# SPLIT CONFIGURATION

Having a config file is fine, but what if you want to keep your credentials secret, and have
your EC2 sets of machine in a .ec2cssh.conf file per projects?

With ec2-cssh, this is possible by splitting the configuration in severl files.
For instance, you can have:

- .ec2cssh.conf in your project directory:

        {
           'ec2_config' => { region => 'project-specific-aws-region' },
           'ec2_sets' => { 'projectspecificset' => ... },
        }

- $HOME/.ec2cssh.conf:

        {
           'ec2_config' => { .. Your credentials },
           'ec2_sets' => { 'asetilike' => ... }
        }

- /etc/ec2cssh.conf:

        {
          ec2_sets => { 'asystemwideset' => .. }
          command => '.. System wide Cssh command ..'
        }

## INSTALLING cssh

To install cssh on Linux (Debian):

    sudo  apt-get install clusterssh

To install CsshX for Mac OSX:

    brew install csshx

# SEE ALSO

Cluster SSH (Linux) Homepage: [https://github.com/duncs/clusterssh/wiki](https://github.com/duncs/clusterssh/wiki)

CsshX (Mac OSX) Homepage: [https://github.com/brockgr/csshx](https://github.com/brockgr/csshx)