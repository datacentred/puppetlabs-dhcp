# ----------
# DHCP Server Configuration
# ----------
class dhcp (
  $dnsdomain,
  $nameservers,
  $ntpservers,
  $dhcp_conf_header    = 'dhcp/dhcpd.conf-header.erb', # default template
  $dhcp_conf_pxe       = 'dhcp/dhcpd.conf.pxe.erb',    # default template
  $dhcp_conf_extra     = 'dhcp/dhcpd.conf-extra.erb',  # default template
  $dhcp_conf_omapi     = 'dhcp/dhcpd.conf.omapi.erb',  # default template
  $dhcp_conf_fragments = {},
  $interfaces          = undef,
  $interface           = 'NOTSET',
  $pxeserver           = undef,
  $pxefilename         = undef,
  $logfacility         = 'daemon',
  $default_lease_time  = 3600,
  $max_lease_time      = 86400,
  $failover            = '',
  $ddns                = false,
  $omapi_secret        = '',
  $omapi_key           = 'omapi_key',
  $manage_service      = true,
  $leases_file         = undef,
) {

  include dhcp::params

  $dhcp_dir    = $dhcp::params::dhcp_dir
  $packagename = $dhcp::params::packagename
  $servicename = $dhcp::params::servicename
  $dhcpd       = $dhcp::params::dhcpd

  # Incase people set interface instead of interfaces work around
  # that. If they set both, use interfaces and the user is a unwise
  # and deserves what they get.
  if $interface != 'NOTSET' and $interfaces == undef {
    $dhcp_interfaces = [ $interface ]
  } elsif $interface == 'NOTSET' and $interfaces == undef {
    fail ("You need to set \$interfaces in ${module_name}")
  } else {
    $dhcp_interfaces = $interfaces
  }

  package { $packagename:
    ensure => installed,
  }

  # OS Specifics
  case $operatingsystem {
    'debian','ubuntu': {
      include dhcp::debian
      Service { subscribe => File['/etc/default/isc-dhcp-server'] }
    }
  }

  Concat { require => Package[$packagename] }

  #
  # Build up the dhcpd.conf
  concat {  "${dhcp_dir}/dhcpd.conf": }

  concat::fragment { 'dhcp-conf-header':
    target  => "${dhcp_dir}/dhcpd.conf",
    content => template($dhcp_conf_header),
    order   => 01,
  }

  if $pxeserver {
    concat::fragment { 'dhcp-conf-pxe':
      target  => "${dhcp_dir}/dhcpd.conf",
      content => template($dhcp_conf_pxe),
      order   => 20,
    }
  }

  concat::fragment { 'dhcp-conf-omapi':
    target  => "${dhcp_dir}/dhcpd.conf",
    content => template($dhcp_conf_omapi),
    order   => 80,
  }

  concat::fragment { 'dhcp-conf-extra':
    target  => "${dhcp_dir}/dhcpd.conf",
    content => template($dhcp_conf_extra),
    order   => 99,
  }

  # Using DDNS will require a dhcp::ddns class composition, else, we should
  # turn it off.
  if $ddns == 'false' {
    class { "dhcp::ddns": enable => false; }
  }

  # Any additional dhcpd.conf fragments the user passed in as a hash for
  # create_resources.  This allows the end user almost total control over the
  # DHCP server without modifying this module at all.

  # JJM This is commented out because the create_resources in PE does not
  # support the third option.
  # $fragment_defaults = {
  #   content => "# Managed by Puppet\n",
  #   target  => "${dhcp_dir}/dhcpd.conf",
  #   order   => 80,
  # }
  create_resources('concat::fragment', $dhcp_conf_fragments)

  #
  # Build the dhcpd.pools
  concat { "${dhcp_dir}/dhcpd.pools": }

  concat::fragment { 'dhcp-pools-header':
    target  => "${dhcp_dir}/dhcpd.pools",
    content => "# DHCP Pools\n",
    order   => 01,
  }

  #
  # Build the dhcpd.hosts
  # SM: This is handled by the synchronisation agent daemon
  #concat { "${dhcp_dir}/dhcpd.hosts": }
  #
  #concat::fragment { 'dhcp-hosts-header':
  #  target  => "${dhcp_dir}/dhcpd.hosts",
  #  content => "# static DHCP hosts\n",
  #  order   => 01,
  #}
  exec { 'dhcpd.hosts':
    command => "touch ${dhcp_dir}/dhcpd.hosts",
    unless  => "ls ${dhcp_dir}/dhcpd.hosts",
  }

  #
  # Build the dhcpd.zones
  if $ddns {
    concat { "${dhcp_dir}/dhcpd.zones": }

    concat::fragment { 'dhcp-zones-header':
      target  => "${dhcp_dir}/dhcpd.zones",
      content => "# DDNS zones\n",
      order   => 01,
    }
  }

  if $manage_service {
    service { $servicename:
      ensure    => running,
      enable    => true,
      hasstatus => true,
      subscribe => [Concat["${dhcp_dir}/dhcpd.pools"], Concat["${dhcp_dir}/dhcpd.zones"], Concat["${dhcp_dir}/dhcpd.conf"]],
      require   => Package[$packagename],
      restart   => "${dhcpd} -t && service ${servicename} restart",
    }
  }

  include dhcp::monitor

}
