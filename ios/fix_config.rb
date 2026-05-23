
require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find or create the Pods xcconfig file references
debug_config_path = 'Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig'
release_config_path = 'Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig'
profile_config_path = 'Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig'

# Add file references if they don't exist
def add_file_ref(project, path)
  ref = project.files.find { |f| f.path == path }
  return ref if ref

  # Group logic: Place in a 'Pods' group or root
  pods_group = project.main_group['Pods'] || project.main_group.new_group('Pods')
  pods_group.new_file(path)
end

debug_ref = add_file_ref(project, debug_config_path)
release_ref = add_file_ref(project, release_config_path)
profile_ref = add_file_ref(project, profile_config_path)

# Apply to the Runner target
target = project.targets.find { |t| t.name == 'Runner' }
if target
  puts "Fixing configuration for target: #{target.name}"
  target.build_configurations.each do |config|
    if config.name == 'Debug'
      config.base_configuration_reference = debug_ref
      puts "  - Linked Debug configuration to Pods-Runner.debug.xcconfig"
    elsif config.name == 'Release'
      config.base_configuration_reference = release_ref
      puts "  - Linked Release configuration to Pods-Runner.release.xcconfig"
    elsif config.name == 'Profile'
      config.base_configuration_reference = profile_ref
      puts "  - Linked Profile configuration to Pods-Runner.profile.xcconfig"
    end
  end
else
  puts "Runner target not found!"
end

project.save
puts "Xcode project configurations successfully linked to CocoaPods."
