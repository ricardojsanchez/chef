#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'

class Chef
  class Provider
    class Package
      class Rubygems < Chef::Provider::Package  
      
        def gem_list_parse(line)
          installed_versions = Array.new
          if line.match("^#{@new_resource.package_name} \\((.+?)\\)$")
            installed_versions = $1.split(/, /)
            installed_versions
          else
            nil
          end
        end
      
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(nil)
        
          # First, we need to look up whether we have the local gem installed or not
          status = popen4("gem list --local #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdin.close
            stdout.each do |line|
              installed_versions = gem_list_parse(line)
              next unless installed_versions
              # If the version we are asking for is installed, make that our current
              # version.  Otherwise, go ahead and use the highest one, which
              # happens to come first in the array.
              if installed_versions.detect { |v| v == @new_resource.version }
                Chef::Log.debug("#{@new_resource.package_name} at version #{@new_resource.version}")
                @current_resource.version(@new_resource.version)
              else
                iv = installed_versions.first
                Chef::Log.debug("#{@new_resource.package_name} at version #{iv}")
                @current_resource.version(iv)
              end
            end
          end
          
          unless status.exitstatus == 0
            raise Chef::Exception::Package, "gem list --local failed - #{status.inspect}!"
          end
          
          status = popen4("gem list --remote #{@new_resource.package_name}#{' --source=' + @new_resource.source if @new_resource.source}") do |pid, stdin, stdout, stderr|
            stdin.close
            stdout.each do |line|
              installed_versions = gem_list_parse(line)
              next unless installed_versions
              Chef::Log.debug("I have #{installed_versions.inspect}")
              
              if installed_versions.length >= 1
                Chef::Log.debug("Setting candidate version")
                @candidate_version = installed_versions.first
              end
            end
          end

          unless status.exitstatus == 0
            raise Chef::Exception::Package, "gem list --remote failed - #{status.inspect}!"
          end
        
          @current_resource
        end
      
        def install_package(name, version)
          src = nil
          if @new_resource.source
            src = "  --source=#{@new_resource.source} --source=http://gems.rubyforge.org"
          end  
          run_command(
            :command => "gem install #{name} -q --no-rdoc --no-ri -v #{version}#{src}"
          )
        end
      
        def upgrade_package(name, version)
          install_package(name, version)
        end
      
        def remove_package(name, version)
          if version
            run_command(
              :command => "gem uninstall #{name} -q -v #{version}"
            )
          else
            run_command(
              :command => "gem uninstall #{name} -q -a"
            )
          end
        end
      
        def purge_package(name, version)
          remove_package(name, version)
        end
      
      end
    end
  end
end
