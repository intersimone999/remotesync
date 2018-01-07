Gem::Specification.new do |s|
  s.name        = 'remotesync'
  s.version     = '1.0.0'
  s.date        = '2018-01-05'
  s.summary     = "Sync remote folders using ssh"
  s.description = "Sync remote folders using ssh. Supports network namespaces in Linux."
  s.authors     = ["Simone Scalabrino"]
  s.homepage    = "https://github.com/intersimone999/remotesync"
  s.email       = 's.scalabrino9@gmail.com'
  s.license     = 'GPL-3.0'
  
  s.files       = ["lib/commons.rb", "bin/rrinit", "bin/rrpull", "bin/rrpush"]
  s.executables = ["rrinit", "rrpull", "rrpush"]
  
  s.add_runtime_dependency "colorize", "~> 0.8", ">= 0.8.1"
end
