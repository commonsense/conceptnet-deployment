# This configuration effectively extends the base ConceptNet configuration,
# setting up the Web server that serves the Web site and API.

package { 'nginx':
  ensure  => 'latest',
}

# Install the ConceptNet web package from source
python::pip { 'conceptnet_web':
  virtualenv => '/home/conceptnet/env',
  pkgname     => '/home/conceptnet/conceptnet5/web',
  owner      => 'conceptnet',
  editable   => true,
  require    => [ Vcsrepo['/home/conceptnet/conceptnet5'], Python::Pip['conceptnet'] ],
}


# Install web server config. First, nginx.
file { '/etc/nginx/conf.d/conceptnet.conf':
  ensure  => 'present',
  source  => 'puppet:///modules/conceptnet/nginx/conceptnet.conf',
  require => Package['nginx'],
}

file { '/home/conceptnet/nginx':
  ensure  => 'directory',
  owner   => 'conceptnet',
  require => User['conceptnet'],
}

file { '/home/conceptnet/nginx/cache':
  ensure  => 'directory',
  owner   => 'www-data',
  require => File['/home/conceptnet/nginx'],
}

# Remove Debian's "presumptuous" default Nginx configuration
file { '/etc/nginx/sites-enabled/default':
  ensure  => 'absent',
  require => Package['nginx'],
}

# The uWSGI processes need to be running, as well. Set up the uWSGI Emperor
# as a systemd unit, running the two apps we define in
# /home/conceptnet/uwsgi/apps.
python::pip { 'uwsgi':
  ensure     => 'latest',
  virtualenv => '/home/conceptnet/env',
}

file { '/home/conceptnet/uwsgi':
  ensure  => 'directory',
  owner   => 'conceptnet',
  require => User['conceptnet'],
}

file { '/home/conceptnet/uwsgi/run':
  ensure  => 'directory',
  owner   => 'conceptnet',
  require => User['conceptnet'],
}

file { '/home/conceptnet/uwsgi/apps':
  ensure  => 'directory',
  owner   => 'conceptnet',
  require => User['conceptnet'],
}

file { '/home/conceptnet/uwsgi/emperor.ini':
  ensure  => 'present',
  source  => 'puppet:///modules/conceptnet/uwsgi/emperor.ini',
  owner   => 'conceptnet',
  require => User['conceptnet'],
}

file { '/home/conceptnet/uwsgi/apps/conceptnet-web.ini':
  ensure  => 'present',
  source  => 'puppet:///modules/conceptnet/uwsgi/apps/conceptnet-web.ini',
  owner   => 'conceptnet',
  require => User['conceptnet'],
}

file { '/home/conceptnet/uwsgi/apps/conceptnet-api.ini':
  ensure  => 'present',
  source  => 'puppet:///modules/conceptnet/uwsgi/apps/conceptnet-api.ini',
  owner   => 'conceptnet',
  require => User['conceptnet'],
}


# Manage systemd units

file { '/etc/systemd/system/conceptnet.service':
  ensure  => 'present',
  source  => 'puppet:///modules/conceptnet/systemd/conceptnet.service',
  owner   => 'root',
}

exec { 'systemctl restart nginx':
  path        => ['/usr/sbin', '/bin'],
  refreshonly => true,
  logoutput   => true,
  subscribe   => File['/etc/nginx/conf.d/conceptnet.conf'],
  require     => [Package['nginx'], File['/home/conceptnet/nginx/cache'], File['/etc/nginx/sites-enabled/default'], File['/etc/nginx/conf.d/conceptnet.conf']]
}

exec { 'systemctl enable conceptnet':
  path        => ['/bin'],
  refreshonly => true,
  subscribe   => File['/etc/systemd/system/conceptnet.service'],
  require     => File['/etc/systemd/system/conceptnet.service'],
}

exec { 'systemctl restart conceptnet':
  path        => ['/bin'],
  refreshonly => true,
  subscribe   => File['/etc/systemd/system/conceptnet.service'],
  require     => [File['/etc/systemd/system/conceptnet.service'],
                  File['/home/conceptnet/uwsgi/apps/conceptnet-web.ini'],
                  File['/home/conceptnet/uwsgi/apps/conceptnet-api.ini'],
                  Python::Pip['conceptnet_web'],
                  Python::Pip['uwsgi']],
}


# Configure the system's hostname
host { $hostname:
  ip => '127.0.1.1',
  host_aliases => [ 'api.conceptnet.localhost', 'www.conceptnet.localhost' ],
}
