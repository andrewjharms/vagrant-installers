class vagrant_substrate::staging::windows {
  include vagrant_substrate

  $cache_dir         = $vagrant_substrate::cache_dir
  $embedded_dir      = $vagrant_substrate::embedded_dir
  $staging_dir       = $vagrant_substrate::staging_dir
  $installer_version = $vagrant_substrate::installer_version

  $staging_dir_32   = "${staging_dir}\\x32"
  $staging_dir_64   = "${staging_dir}\\x64"

  $embedded_dir_32  = "${staging_dir_32}\\embedded"
  $embedded_dir_64  = "${staging_dir_64}\\embedded"

  $ruby_version      = hiera("ruby::version")
  $ruby_files_path   = "${cache_dir}\\ruby-files"
  $ruby_build_path   = "${cache_dir}\\ruby-build"
  $ruby_bash_builder = "${cache_dir}\\bash-builder.sh"

  $builder_path      = "${cache_dir}\\substrate_builder.sh"
  $builder_cwd       = "C:\\msys64\\home\\vagrant\\styrene"
  $builder_config    = "${builder_cwd}\\vagrant.cfg"

  $launcher_path     = "${cache_dir}\\launcher"

  file { $staging_dir_64:
    ensure => "directory",
    recurse => true,
  }

  file { $staging_dir_32:
    ensure => "directory",
    recurse => true,
  }

  file { $embedded_dir_64:
    ensure => "directory",
    recurse => true,
  }

  file { $embedded_dir_32:
    ensure => "directory",
    recurse => true,
  }

  file { $builder_path:
    content => template("vagrant_substrate/substrate_builder.sh.erb"),
  }

  file { $builder_config:
    content => template("vagrant_substrate/vagrant.cfg.erb"),
  }

  file { $ruby_files_path:
    source => "puppet:///modules/vagrant_substrate/windows-ruby-${ruby_version}",
    path => $ruby_files_path,
    recurse => true,
  }

  file { $ruby_bash_builder:
    content => template("vagrant_substrate/ruby-bash-builder.sh.erb")
  }

  powershell { "build-ruby":
    content => template("vagrant_substrate/windows_ruby_builder.ps1.erb"),
    file_cache_dir => $cache_dir,
    require => [
      File[$ruby_bash_builder],
      File[$ruby_files_path],
    ],
  }

  powershell { "build-substrate":
    content => template("vagrant_substrate/substrate_waiter.ps1.erb"),
    file_cache_dir => $cache_dir,
    require => [
      File[$builder_path],
      File[$builder_config],
      File[$embedded_dir_64],
      File[$embedded_dir_32],
      Powershell["build-ruby"],
    ],
  }

  file { $launcher_path:
    source => "puppet:///modules/vagrant_substrate/launcher",
    path => $launcher_path,
    recurse => true,
  }

  # ensure dependency is around
  exec { "install-osext":
    command => "cmd.exe /c \"C:\\Go\\bin\\go.exe get github.com/mitchellh/osext\"",
    environment => [
      "GOPATH=C:\\Windows\Temp",
    ],
  }

  # install launcher
  exec { "install-launcher-x64":
    command => "C:\\Go\\bin\\go.exe build -o \"${staging_dir_64}\\bin\\vagrant.exe\" main.go",
    cwd => $launcher_path,
    environment => [
      "GOPATH=C:\\Windows\Temp",
    ],
    require => [
      File[$launcher_path],
      Exec["install-osext"],
      Powershell["build-substrate"],
    ],
  }

  exec { "install-launcher-x32":
    command => "C:\\Go\\bin\\go.exe build -o \"${staging_dir_32}\\bin\\vagrant.exe\" main.go",
    cwd => $launcher_path,
    environment => [
      "GOARCH=386",
    ],
    require => [
      File[$launcher_path],
      Exec["install-osext"],
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_64}\\etc\\gemrc":
    content => template("vagrant_substrate/gemrc.erb"),
    mode    => "0644",
    recurse => true,
    require => [
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_32}\\etc\\gemrc":
    content => template("vagrant_substrate/gemrc.erb"),
    recurse => true,
    mode    => "0644",
    require => [
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_64}\\cacert.pem":
    source => "puppet:///modules/vagrant_substrate/cacert.pem",
    mode   => "0644",
    require => [
      Powershell["build-substrate"],
    ],
  }

  file { "${embedded_dir_32}\\cacert.pem":
    source => "puppet:///modules/vagrant_substrate/cacert.pem",
    mode   => "0644",
    require => [
      Powershell["build-substrate"],
    ],
  }

  class { "rubyencoder::loaders":
    path => $staging_dir,
    require => [
      Powershell["build-substrate"],
    ],
  }
}
