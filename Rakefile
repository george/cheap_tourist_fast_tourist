require 'rake'

desc "Run specs"
task :spec do
  system 'rspec spec'
end

desc "Run features"
task :features do
  system 'cucumber features --format progress'
end

task :default => [:spec, :features]