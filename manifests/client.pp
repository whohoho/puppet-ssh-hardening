# == Class: ssh_hardening::client
#
# The default SSH class which installs the SSH client
#
# === Parameters
#
# [*cbc_required*]
#   CBC-meachnisms are considered weaker and will not be used as ciphers by
#   default. Set this option to true if you really need CBC-based ciphers.
#
# [*weak_hmac*]
#   The HMAC-mechanisms are selected to be cryptographically strong. If you
#   require some weaker variants, set this option to true to get safe selection.
#
# [*weak_kex*]
#   The KEX-mechanisms are selected to be cryptographically strong. If you
#   require some weaker variants, set this option to true to get safe selection.
#
# [*ports*]
#   A list of ports that SSH expects to run on. Defaults to 22.
#
# [*ipv6_enabled*]
#   Set to true if you need IPv6 support in SSH.
#
# === Copyright
#
# Copyright 2014, Deutsche Telekom AG
#
class ssh_hardening::client (
  $cbc_required = false,
  $weak_hmac = false,
  $weak_kex = false,
  $ports = [ 22 ],
  $ipv6_enabled = false
) {
  if $ipv6_enabled == true {
    $addressfamily = "any"
  } else {
    $addressfamily = "inet"
  }
  
  if $cbc_required == true {
    $ciphers = "aes128-ctr,aes256-ctr,aes192-ctr,aes128-cbc,aes256-cbc,aes192-cbc"
  } else {
    $ciphers = "aes128-ctr,aes256-ctr,aes192-ctr"
  }

  if $weak_hmac == true {
    $mac = "hmac-sha2-256,hmac-sha2-512,hmac-ripemd160,hmac-sha1"
  } else {
    $mac = "hmac-sha2-256,hmac-sha2-512,hmac-ripemd160"
  }

  if $weak_kex == true {
    $kex = "ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1"
  } else {
    $kex = "ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256"
  }

  class { 'ssh::client':
    storeconfigs_enabled => false,
    options => {
      # Set the addressfamily according to IPv4 / IPv6 settings
      'AddressFamily' => $addressfamily,

      # The port at the destination should be defined
      'Port' => $ports,

      # Set the protocol family to 2 for security reasons. Disables legacy support.
      'Protocol' => 2,

      # Make sure passphrase querying is enabled
      'BatchMode' => 'no',

      # Prevent IP spoofing by checking to host IP against the `known_hosts` file.
      'CheckHostIP' => 'yes',

      # Always ask before adding keys to the `known_hosts` file. Do not set to `yes`.
      'StrictHostKeyChecking' => 'ask',

      # **Ciphers** -- If your clients don't support CTR (eg older versions), cbc will be added
      # CBC: is true if you want to connect with OpenSSL-base libraries
      # eg ruby Net::SSH::Transport::CipherFactory requires cbc-versions of the given openssh ciphers to work
      # -- see: (http://net-ssh.github.com/net-ssh/classes/Net/SSH/Transport/CipherFactory.html)
      # 
      'Ciphers' => $ciphers,

      # **Hash algorithms** -- Make sure not to use SHA1 for hashing, unless it is really necessary.
      # Weak HMAC is sometimes required if older package versions are used 
      # eg Ruby's Net::SSH at around 2.2.* doesn't support sha2 for hmac, so this will have to be set true in this case.
      # 
      'MACs' => $macs,

      # Alternative setting, if OpenSSH version is below v5.9
      #MACs hmac-ripemd160

      # **Key Exchange Algorithms** -- Make sure not to use SHA1 for kex, unless it is really necessary
      # Weak kex is sometimes required if older package versions are used
      # eg ruby's Net::SSH at around 2.2.* doesn't support sha2 for kex, so this will have to be set true in this case.
      # 
      'KexAlgorithms' => $kex,

      # Disable agent formwarding, since local agent could be accessed through forwarded connection.
      'ForwardAgent' => 'no',

      # Disable X11 forwarding, since local X11 display could be accessed through forwarded connection.
      'ForwardX11' => 'no',

      # Never use host-based authentication. It can be exploited.
      'HostbasedAuthentication' => 'no',
      'RhostsRSAAuthentication' => 'no',

      # Enable RSA authentication via identity files.
      'RSAAuthentication' => 'yes',

      # Disable password-based authentication, it can allow for potentially easier brute-force attacks.
      'PasswordAuthentication' => 'no',

      # Only use GSSAPIAuthentication if implemented on the network.
      'GSSAPIAuthentication' => 'no',
      'GSSAPIDelegateCredentials' => 'no',

      # Disable tunneling
      'Tunnel' => 'no',

      # Disable local command execution.
      'PermitLocalCommand' => 'no',

      # Misc. configuration
      # ===================

      # Enable compression. More pressure on the CPU, less on the network.
      'Compression' => 'yes',

      #EscapeChar ~
      #VisualHostKey yes%                                 
    },
  }
}
