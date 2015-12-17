#--
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010-2015 Chef Software, Inc.
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

require 'tmpdir'
require 'bundler'

class Chef
  class Cookbook
    class GemInstaller
      attr_accessor :cookbook_collection
      attr_accessor :gems

      def initialize(cookbook_collection)
        @cookbook_collection = cookbook_collection
        @gems = []
      end

      def install
        cookbook_collection.each do |cookbook_name, cookbook_version|
          @gems += cookbook_version.metadata.gems
        end

        return if @gems.empty?

        Dir.mktmpdir do |dir|
          File.open("#{dir}/Gemfile", "w") do |f|
            @gems.each do |gem|
              f.puts gem.join(' ')
            end
          end

          Bundler.with_clean_env do
            old_ui = Bundler.ui
            Bundler.ui = ChefBundlerUI.new

            Dir.chdir(dir) do
              definition = Bundler.definition
              definition.validate_ruby!

              Bundler::Installer.install(Bundler.root, definition, system: true)
            end
            Bundler.ui = old_ui
          end
        end
      end

      class ChefBundlerUI < Bundler::UI::Silent
        def confirm(msg, newline = nil)
          Chef::Log.warn("CONFIRM: #{msg}")
        end

        def error(msg, newline = nil)
          Chef::Log.warn("ERROR: #{msg}")
        end
      end
    end
  end
end
