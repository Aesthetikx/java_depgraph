glob = "src/**/*.java"
prefix = nil #com.example.
forward = false
show_deps = true
min_dep = 2

java_files = Dir.glob(glob)

java_classes = []

class JavaClass
  attr_accessor :package
  attr_accessor :identifier
  attr_accessor :forward_dependencies
  attr_accessor :reverse_dependencies

  def initialize
    @forward_dependencies = []
    @reverse_dependencies = []
  end

  def to_s
    @identifier
  end
end

#
# Find imports, compute forward dependencies
#

java_classes = java_files.collect do |path|
  JavaClass.new.tap do |java|
    File.open(path).each do |line|
      if (line =~ /^package .*/)
        # Determine the package of this file
        java.package = line.gsub(/^package /, "").gsub(/;[^;]*$/, "")
      elsif (line =~ /^public (?:class|abstract class|interface) (\w+)/)
        # Determine name of the class or interface
        java.identifier = java.package + "." + $~[1]
      elsif (line =~ /^import .*/)
        # Add this import line to forward dependencies
        package = line.gsub(/^import /, "").gsub(/;[^;]*$/, "")
        if prefix.nil? or package.start_with? prefix
          java.forward_dependencies << package
        end
      end
    end
  end
end

#
# Compute reverse dependencies
#

java_classes.each do |klass|
  klass.forward_dependencies.each do |dependency|
    k = java_classes.select { |x| x.identifier == dependency }.first
    if k
      k.reverse_dependencies << klass
    end
  end
end

#
# Display
#

deps_name = forward ? "forward_dependencies" : "reverse_dependencies"

java_classes.select do |klass|
  # Filter by at least min_dep dependencies
  klass.send(deps_name).size >= min_dep
end.sort_by do |klass|
  # Sort in order of dependency size, descending
  -klass.send(deps_name).size
end.each do |klass|
  deps = klass.send(deps_name)
  puts "#{deps.size} #{klass}"
  if show_deps
    deps.each do |dep|
      puts "\t#{dep}"
    end
  end
end
