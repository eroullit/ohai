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

Ohai.plugin do
  provides "languages/ruby"

  depends "languages"

  def run_ruby(command)
    cmd = "ruby -e \"require 'rbconfig'; #{command}\""
    so = shell_out(cmd)
    so.stdout.strip
  end

  collect_data do
    languages[:ruby] = Mash.new

    values = {
      :platform => "RUBY_PLATFORM",
      :version => "RUBY_VERSION",
      :release_date => "RUBY_RELEASE_DATE",
      :target => "::Config::CONFIG['target']",
      :target_cpu => "::Config::CONFIG['target_cpu']",
      :target_vendor => "::Config::CONFIG['target_vendor']",
      :target_os => "::Config::CONFIG['target_os']",
      :host => "::Config::CONFIG['host']",
      :host_cpu => "::Config::CONFIG['host_cpu']",
      :host_os => "::Config::CONFIG['host_os']",
      :host_vendor => "::Config::CONFIG['host_vendor']",
      :bin_dir => "::Config::CONFIG['bindir']",
      :ruby_bin => "::File.join(::Config::CONFIG['bindir'], ::Config::CONFIG['ruby_install_name'])"
    }

    # Create a query string from above hash
    env_string = ""
    values.keys.each do |v| 
      env_string << "#{v}=\#{#{values[v]}},"
    end

    # Query the system ruby
    result = run_ruby "puts %Q(#{env_string})"

    # Parse results to plugin hash
    result.split(',').each do |entry|
      key, value = entry.split('=')
      languages[:ruby][key.to_sym] = value || ""
    end

    # Perform one more (conditional) query
    bin_dir = languages[:ruby][:bin_dir]
    ruby_bin = languages[:ruby][:ruby_bin]
    gem_binaries = [ 
                    run_ruby("require 'rubygems'; puts ::Gem.default_exec_format % 'gem'"),
                    "gem"
                   ].map {|bin| ::File.join(bin_dir, bin)}
    gem_binary = gem_binaries.find {|bin| ::File.exists? bin }
    if gem_binary
      languages[:ruby][:gems_dir] = run_ruby "puts %x{#{ruby_bin} #{gem_binary} env gemdir}.chomp!"
      languages[:ruby][:gem_bin] = gem_binary
    end
  end
end
