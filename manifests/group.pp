# @summary Manage RANCID - http://www.shrubbery.net/rancid/
# @param devices Devices to manage
define rancid::group (
  Array[Rancid::Device] $devices,
) {
  $delimiter = $rancid::router_db_delimiter
  exec { "rancid-cvs-${name}":
    command => "rancid-cvs ${name}",
    path    => $rancid::rancid_path_env,
    user    => $rancid::user,
    creates => "${rancid::homedir}/${name}/CVS",
  }
  file { "${rancid::homedir}/${name}/router.db":
    ensure  => 'file',
    owner   => $rancid::user,
    group   => $rancid::group,
    mode    => '0640',
    content => template('rancid/router.db.erb'),
    require => Exec["rancid-cvs-${name}"],
  }
}
