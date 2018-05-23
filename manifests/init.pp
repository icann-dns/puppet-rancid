# == Class: rancid
#
# Manage RANCID - http://www.shrubbery.net/rancid/
#
class rancid (
  Enum['ALL', 'YES', 'NO'] $filterpwds,
  Boolean                  $nocommstr,
  Integer[1]               $maxrounds,
  Integer[1]               $oldtime,
  Integer[1]               $locktime,
  Integer[1]               $parcount,
  Optional[String]         $maildomain,
  Array                    $packages,
  Stdlib::Absolutepath     $rancid_config,
  Array                    $rancid_path_env,
  Stdlib::Absolutepath     $homedir,
  Stdlib::Absolutepath     $logdir,
  String                   $user,
  String                   $group,
  Stdlib::Absolutepath     $shell,
  String                   $cloginrc_content,
  String[1,1]              $router_db_delimiter,
  Optional[Hash]           $groups,
) {
  $cloginrc_path = "${homedir}/.cloginrc"

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
