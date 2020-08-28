# System package dependencies

class { 'apt':
  update => {
    frequency => 'daily',
  },
}

$dependencies = [
  'build-essential',
  'libhdf5-dev',
  'libmecab-dev',
  'mecab-ipadic-utf8',
  'wget',
  'git',
]

package { $dependencies:
  ensure  => present,
}

class { 'postgresql::globals':
  manage_package_repo => true,
  version             => '10',
  encoding            => 'UTF-8',
}

# Create the 'conceptnet' user who will own things

user { 'conceptnet':
  ensure  => 'present',
  shell   => '/bin/bash',
  groups  => ['www-data'],
  managehome => true,
}

user { 'ubuntu':
  ensure  => 'present',
  shell   => '/bin/bash',
  groups  => ['www-data'],
  managehome => false,
}

# PostgreSQL setup

class { 'postgresql::server': }

postgresql::server::role { 'conceptnet':
  superuser => true,
  require   => Class['postgresql::server']
}

postgresql::server::db { 'conceptnet5':
  user      => 'conceptnet',
  password  => undef,
}

postgresql::server::pg_hba_rule { 'allow db access over a local socket':
  type        => 'local',
  database    => 'conceptnet5',
  user        => 'all',
  auth_method => 'trust'
}


# Python and ConceptNet setup

vcsrepo { '/home/conceptnet/conceptnet5':
  ensure   => 'latest',
  provider => 'git',
  source   => 'https://github.com/commonsense/conceptnet5.git',
  user     => 'conceptnet',
  require  => User['conceptnet'],
  revision => 'master'
}

file { '/home/conceptnet/conceptnet5/data':
  ensure  => 'directory',
  owner   => 'conceptnet',
  group   => 'www-data',
  mode    => 'ug+rw',
  require => Vcsrepo['/home/conceptnet/conceptnet5'],
}

file { '/home/conceptnet/conceptnet5/data/vectors':
  ensure  => 'directory',
  owner   => 'conceptnet',
  group   => 'www-data',
  mode    => 'ug+rw',
  require => File['/home/conceptnet/conceptnet5/data'],
}

archive { '/home/conceptnet/conceptnet5/data/vectors/mini.h5':
  ensure   => present,
  source   => 'http://conceptnet.s3.amazonaws.com/precomputed-data/2016/numberbatch/19.08/mini.h5',
  provider => 'wget',
  user     => 'conceptnet',
  group    => 'www-data',
  require  => File['/home/conceptnet/conceptnet5/data/vectors'],
}

class { 'python':
  ensure     => 'present',
  version    => '3.8',
  pip        => 'absent',
  dev        => 'present',
  virtualenv => 'present',
  gunicorn   => 'absent'
}

python::virtualenv { '/home/conceptnet/env':
  ensure     => 'present',
  version    => '3.8',
  systempkgs => true,
  ensure_venv_dir => true,
  venv_dir   => '/home/conceptnet/env',
  distribute => false,
  owner      => 'conceptnet',
  require    => [User['conceptnet'], Class['python']]
}

python::pip { 'conceptnet':
  virtualenv => '/home/conceptnet/env',
  pkgname    => '/home/conceptnet/conceptnet5[vectors]',
  owner      => 'conceptnet',
  editable   => true,
  require    => [Vcsrepo['/home/conceptnet/conceptnet5'], Python::Virtualenv['/home/conceptnet/env']],
}


# Some conveniences when at an interactive shell as the conceptnet user:
# the Python environment with ConceptNet in it should be activated, and
# IPython should be installed.

python::pip { 'ipython':
  ensure     => 'latest',
  virtualenv => '/home/conceptnet/env',
  pkgname    => 'ipython',
}

file { '/home/conceptnet/.bashrc':
  ensure  => 'present',
  content => 'source /home/conceptnet/env/bin/activate',
  require  => User['conceptnet'],
}
