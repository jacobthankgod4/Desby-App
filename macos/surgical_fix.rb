
require 'fileutils'

def fix_project(project_path)
  if File.exist?(project_path)
    puts "Surgically removing malformed flags from #{project_path}..."
    content = File.read(project_path)

    # 1. Fix -GCC_WARN_INHIBIT_ALL_WARNINGS -> -w
    new_content = content.gsub(/-GCC_WARN_INHIBIT_ALL_WARNINGS/, '-w')

    # 2. Fix standalone -G (this is the one causing the error)
    # Match standalone -G in COMPILER_FLAGS or OTHER_CFLAGS
    # Example: COMPILER_FLAGS = "-D... -G -w ..."
    new_content = new_content.gsub(/(-G)(\s|")/, '\2')

    if content != new_content
      File.write(project_path, new_content)
      puts "Successfully scrubbed #{project_path}."
    else
      puts "No malformed flags found in #{project_path}."
    end
  end
end

fix_project('Pods/Pods.xcodeproj/project.pbxproj')
fix_project('Runner.xcodeproj/project.pbxproj')
