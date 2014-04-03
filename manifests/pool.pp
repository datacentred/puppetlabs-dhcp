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

  $dhcp_dir = $dhcp::params::dhcp_dir

  if member($parameters, 'ddns-updates on') {
      $o = split($network, '[.]')
      $reversezone = "${o[2]}.${o[1]}.${o[0]}.in-addr.arpa"
      dhcp::ddns { "$reversezone" :
        zonemaster => hiera(dnsmasters),
        key        => hiera(rndc_key),
        domains    => $reversezone,
      }
  }

  concat::fragment { "dhcp_pool_${name}":
    target  => "${dhcp_dir}/dhcpd.pools",
    content => template('dhcp/dhcpd.pool.erb'),
  }

}

