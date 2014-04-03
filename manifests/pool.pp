define dhcp::pool (
  $network,
  $mask,
  $range,
  $gateway,
  $nextserver = '',
  $pxefile    = '',
  $failover   = '',
  $options    = '',
  $parameters = ''
) {

  include dhcp::params

  $zonemaster = hiera(dnsmasters)

  $dhcp_dir = $dhcp::params::dhcp_dir

  if member($parameters, 'ddns-updates on') {
      $o = split($network, '[.]')
      $reversezone = "${o[2]}.${o[1]}.${o[0]}.in-addr.arpa"
      concat::fragment { "dhcp_zone_${name}":
        target  => "${dhcp_dir}/dhcpd.zones",
        content => template('dhcp/dhcpd.zone.erb'),
      }
  }

  concat::fragment { "dhcp_pool_${name}":
    target  => "${dhcp_dir}/dhcpd.pools",
    content => template('dhcp/dhcpd.pool.erb'),
  }

}

