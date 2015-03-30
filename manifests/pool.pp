define dhcp::pool (
  $network,
  $mask,
  $range      = '',
  $gateway    = '',
  $nextserver = '',
  $pxefile    = '',
  $failover   = '',
  $options    = '',
  $parameters = '',
  $range_params = '',
) {

  include dhcp::params

  $nameservers = hiera(dnsmasters)
  # Expectation is that the first element of the dnsmasters
  # array in Hiera is the primary
  $zonemaster = $nameservers[0]

  $dhcp_dir = $dhcp::params::dhcp_dir

  if $dhcp::ddns {
    if member($parameters, 'ddns-updates on') {
        $o = split($network, '[.]')
        $reversezone = "${o[2]}.${o[1]}.${o[0]}.in-addr.arpa"
        concat::fragment { "dhcp_zone_${name}":
          target  => "${dhcp_dir}/dhcpd.zones",
          content => template('dhcp/dhcpd.zone.erb'),
        }
    }
  }

  concat::fragment { "dhcp_pool_${name}":
    target  => "${dhcp_dir}/dhcpd.pools",
    content => template('dhcp/dhcpd.pool.erb'),
  }

}

