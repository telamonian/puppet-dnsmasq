# Public: Install and configure dnsmasq from homebrew.
#
# Examples
#
#   include dnsmasq
class dnsmasq {
  if $::osfamily == 'Darwin' {
    $dnsmasq_package_ensure = '2.71-boxen1'
    $dnsmasq_package_name = 'boxen/brews/dnsmasq'
    $dnsmasq_package_provider = homebrew
    $dnsmasq_service_name = 'dev.dnsmasq'
  }
  elsif $::osfamily == 'Debian' {
    $dnsmasq_package_ensure = latest
    $dnsmasq_package_name = 'dnsmasq'
    $dnsmasq_package_provider = apt
    $dnsmasq_service_name = 'dnsmasq'
  }
  else {
    fail("Unsupported OS for dnsmasq module")
  }

  if $::osfamily == 'Darwin' {
    require homebrew
    require dnsmasq::config

    file { [$dnsmasq::config::configdir, $dnsmasq::config::logdir, $dnsmasq::config::datadir]:
      ensure => directory
    }

    file { "${dnsmasq::config::configdir}/dnsmasq.conf":
      notify  => Service[$dnsmasq_service_name],
      require => File[$dnsmasq::config::configdir],
      source  => 'puppet:///modules/dnsmasq/dnsmasq.conf'
    }

    file { '/Library/LaunchDaemons/dev.dnsmasq.plist':
      content => template('dnsmasq/dev.dnsmasq.plist.erb'),
      group   => $::boxen_rootgroup,
      notify  => Service[$dnsmasq_service_name],
      owner   => $::boxen_rootuser,
    }

    file { '/etc/resolver':
      ensure => directory,
      group  => $::boxen_rootgroup,
      owner  => $::boxen_rootuser
    }

    file { '/etc/resolver/dev':
      content => 'nameserver 127.0.0.1',
      group   => $::boxen_rootgroup,
      owner   => $::boxen_rootuser,
      require => File['/etc/resolver'],
      notify  => Service[$dnsmasq_service_name],
    }

    homebrew::formula { 'dnsmasq':
      before => Package['boxen/brews/dnsmasq'],
    }

    service { 'com.boxen.dnsmasq': # replaced by dev.dnsmasq
      before => Service[$dnsmasq_service_name],
      enable => false
    }
  }

  package {
    $dnsmasq_package_name:
      ensure   => $dnsmasq_package_ensure,
      provider => $dnsmasq_package_provider,
      notify => Service[$dnsmasq_service_name]
  }

  service { $dnsmasq_service_name:
    ensure  => running,
    require => Package[$dnsmasq_package_name]
  }
}