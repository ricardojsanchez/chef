#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
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

require 'chef/provider/service'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Init < Chef::Provider::Service
        
        def initialize(node, new_resource)
          super(node, new_resource)
          @init_command ||= "/etc/init.d/#{@new_resource.service_name}"
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)
          if @new_resource.supports[:status]
            Chef::Log.debug("#{@new_resource} supports status, running")

            begin
              if run_command(:command => "#{@init_command} status") == 0
                @current_resource.running true
              end
            rescue Chef::Exception::Exec
              @current_resource.running false
              nil
            end

          elsif @new_resource.status_command
            Chef::Log.debug("#{@new_resource} doesn't support status but you have specified a status command, running..")

            begin
              if run_command(:command => @new_resource.status_command) == 0
                @current_resource.running true
              end
            rescue Chef::Exception::Exec
              @current_resource.running false
              nil
            end

          else
            Chef::Log.debug("#{@new_resource} does not support status and you have not specified a status command, falling back to process table inspection")

            if @node[:command][:ps].nil? or @node[:command][:ps].empty?
              raise Chef::Exception::Service, "#{@new_resource}: could not determine how to inspect the process table, please set this nodes 'ps' attribute"
            end

            status = popen4(@node[:command][:ps]) do |pid, stdin, stdout, stderr|
              stdin.close
              r = Regexp.new(@new_resource.pattern)
              Chef::Log.debug("#{@new_resource}: attempting to match #{@new_resource.pattern} (#{r}) against process table")
              stdout.each_line do |line|
                if r.match(line)
                  @current_resource.running true
                  break
                end
              end
              @current_resource.running false unless @current_resource.running
            end
            unless status.exitstatus == 0
              raise Chef::Exception::Service, "Command #{@node[:command][:ps]} failed"
            else
              Chef::Log.debug("#{@new_resource}: #{@node[:command][:ps]} exited and parsed succesfully, process running: #{@current_resource.running}")
            end
          end

          @current_resource
        end

        def start_service
          if @new_resource.start_command
            run_command(:command => @new_resource.start_command)
          else
            run_command(:command => "#{@init_command} start")
          end
        end

        def stop_service
          if @new_resource.stop_command
            run_command(:command => @new_resource.stop_command)
          else
            run_command(:command => "#{@init_command} stop")
          end
        end

        def restart_service
          if @new_resource.supports[:restart]
            run_command(:command => "#{@init_command} restart")
          elsif @new_resource.restart_command
            run_command(:command => @new_resource.restart_command)
          else
            stop_service
            sleep 1
            start_service
          end
        end

        def reload_service
          if @new_resource.supports[:reload]
            run_command(:command => "#{@init_command} reload")
          elsif @new_resource.reload_command
            run_command(:command => @new_resource.reload_command)
          end
        end

      end
    end
  end
end
