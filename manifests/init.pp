# @summary Manage RANCID - http://www.shrubbery.net/rancid/
# @param filterpwds Filter passwords from config files
# @param nocommstr Do not include comments in config files
# @param maxrounds Maximum number of rounds to run
# @param oldtime Time to wait before considering a device old
# @param locktime Time to wait before considering a device locked
# @param parcount Number of devices to process in parallel
# @param maildomain Mail domain to use for sending emails
# @param vcs VCS to use for storing config files
# @param vcsroot VCS root directory
# @param packages Packages to install
# @param rancid_config Path to rancid.conf
# @param homedir Home directory for rancid
# @param logdir Log directory for rancid
# @param user User to run rancid as
# @param group Group to run rancid as
# @param shell Shell to use for rancid
# @param cloginrc_content Content of .cloginrc
# @param router_db_delimiter Delimiter to use in router.db
# @param groups Groups to create
# @param rancid_path_env PATH environment variable for rancid
#
class rancid (
  Enum['ALL', 'YES', 'NO']  $filterpwds          = 'ALL',
  Boolean                   $nocommstr           = true,
  Integer[1]                $maxrounds           = 4,
  Integer[1]                $oldtime             = 4,
  Integer[1]                $locktime            = 4,
  Integer[1]                $parcount            = 5,
  Enum['cvs', 'svn', 'git'] $vcs                 = 'cvs',
  Optional[String]          $maildomain          = undef,
  Optional[String]          $vcsroot             = undef,
  Array                     $packages            = ['rancid', 'cvs'],
  Stdlib::Absolutepath      $rancid_config       = '/etc/rancid/rancid.conf',
  Stdlib::Absolutepath      $homedir             = '/var/lib/rancid',
  Stdlib::Absolutepath      $logdir              = '/var/log/rancid',
  String                    $user                = 'rancid',
  String                    $group               = 'rancid',
  Stdlib::Absolutepath      $shell               = '/bin/bash',
  String                    $cloginrc_content    = '# managed by puppet',
  String[1,1]               $router_db_delimiter = ';',
  Hash                      $groups              = {},
  Array                     $rancid_path_env     = [
    '/usr/lib/rancid/bin',
    '/bin',
    '/usr/bin',
    '/usr/local/bin',
    '/sbin',
    '/usr/sbin',
    '/usr/local/sbin',
  ],
) {
  $cloginrc_path = "${homedir}/.cloginrc"
  $_vcsroot = $vcsroot ? {
    undef => $vcs ? {
      'cvs' => '$BASEDIR/CVS',
      'svn' => '$BASEDIR/svn',
      'git' => '$BASEDIR/.git',
    },
    default => $vcsroot,
  }
  ensure_packages($packages)

  group { $group:
    ensure  => present,
    system  => true,
    require => Package[$packages],
  }
  user { $user:
    ensure  => present,
    gid     => $group,
    shell   => $shell,
    home    => $homedir,
    require => Package[$packages],
  }
  file { $logdir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }
  file { $homedir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }
  file { $rancid_config:
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => template('rancid/rancid.conf.erb'),
    require => Package[$packages],
  }
  file { $cloginrc_path:
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0600',
    content => $cloginrc_content,
  }
  cron { 'rancid-run':
    ensure      => present,
    user        => $user,
    minute      => 1,
    environment => "PATH=${rancid_path_env.join(':')}",
    command     => 'rancid-run',
  }
  if $groups {
    create_resources(rancid::group, $groups)
  }
}
