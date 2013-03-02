# == Class: pam::ldap
#
# This module manages the LDAP module for PAM. This allows the
# server to authenticate via directory services such as Openldap
# and Active Directory
#
# === Parameters
#
# [*ensure*]
#   Controls the software installation
#   Valid values: <tt>present</tt>, <tt>absent</tt>, <tt>purge</tt>
#
# [*autoupgrade*]
#   If Puppet should upgrade the software automatically
#   Valid values: <tt>true</tt>, <tt>false</tt>
#
# [*source*]
#   Path to Puppet source file for Debuntu pam auth
#   configuration file.
#   Valid values: <tt>puppet:///modules/mymodule/myfile</tt>
#
# === Sample Usage
#
# * Installing with default settings
#   class { 'pam::ldap': }
#
# * Uninstalling the software
#   class { 'pam::ldap': ensure => absent }
#
# === Supported platforms
#
# This module has been tested on the following platforms
# * Ubuntu LTS 10.04
#
# To add support for other platforms, edit the params.pp file and provide
# settings for that platform.
#
class pam::ldap (
  $ensure       = 'UNDEF',
  $autoupgrade  = 'UNDEF',
  $source       = 'UNDEF'
) {

  include pam::params

  # puppet 2.6
  $ensure_real = $ensure ? {
    'UNDEF' => $pam::params::ensure,
    default => $ensure
  }
  $autoupgrade_real = $autoupgrade ? {
    'UNDEF' => $pam::params::autoupgrade,
    default => $autoupgrade
  }
  $source_real = $source ? {
    'UNDEF' => $pam::params::pam_auth_update_ldap_source,
    default => $source
  }

  # Debuntu uses pam-auth-update to build pam configuration
  case $::operatingsystem {
    'Ubuntu', 'Debian': {
      file { 'pam_auth_update_ldap_file':
        ensure  => $ensure,
        path    => $pam::params::pam_auth_update_ldap_file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => $source_real,
        notify  => Exec['pam_auth_update'],
        require => Package['pamldap']
      }
    }
    default: {
      fail("Unsupported operatingsystem ${::operatingsystem}")
    }
  }

  # Input validation
  $valid_ensure_values = [ 'present', 'absent', 'purged' ]
  validate_re($ensure_real, $valid_ensure_values)
  validate_bool($autoupgrade_real)

  # Manages automatic upgrade behavior
  if $ensure_real == 'present' and $autoupgrade_real == true {
    $ensure_package = 'latest'
  } else {
    $ensure_package = $ensure_real
  }

  package { 'pamldap':
    ensure  => $ensure_package,
    name    => $pam::params::ldap_package
  }

}
