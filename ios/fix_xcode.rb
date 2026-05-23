
require 'fileutils'

project_path = 'Pods/Pods.xcodeproj/project.pbxproj'
if File.exist?(project_path)
  puts "Surgically removing malformed -G flags from #{project_path}..."
  content = File.read(project_path)

  # The issue is specifically the string "-GCC_WARN_INHIBIT_ALL_WARNINGS"
  # which Clang interprets as -G (unsupported) and then CC_WARN...
  new_content = content.gsub(/-GCC_WARN_INHIBIT_ALL_WARNINGS/, '-w')

  # Also remove any other raw -G flags that might be lurking in COMPILER_FLAGS
  new_content = new_content.gsub(/COMPILER_FLAGS = "([^"]*)-G([^"]*)"/) do |match|
    prefix = $1
    suffix = $2
    puts "Fixed a malformed COMPILER_FLAGS entry."
    'COMPILER_FLAGS = "' + prefix + suffix + '"'
  end

  File.write(project_path, new_content)
  puts "iOS build system hardened."
else
  puts "Pods project not found. Run pod install first."
end
