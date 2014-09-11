# Copyright (c) 2014 Fidelity Investments.
#
# Author: Mevan Samaratunga
# Email: mevan.samaratunga@fmr.com
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

require 'chef/resource'

class Chef
    class Resource

        class Vm < Chef::Resource
            
            include SysUtils::Helper

            def initialize(name, run_context=nil)
                super
                
                @resource_name = :vm

                # Check for Xen Hypervisor
                @provider = nil

                if !run_context.nil?

                    # Check for Xen Hypervisor
                    @provider = nil

                    xe_path = shell_out("which xe")
                    if !xe_path.empty?

                        fqdn = run_context.node["fqdn"]
                        pool_master_uuid = shell_out("xe pool-list params=master --minimal")
                        
                        if !pool_master_uuid.empty?

                            hostname = shell_out("xe host-list params=hostname uuid=#{pool_master_uuid} --minimal")
                            @provider = Chef::Provider::Vm::Xen if fqdn==hostname
                        end
                    end

                    Chef::Application.fatal!("Unable to determine hypervisor type.", 999) if @provider.nil?
                end

                @action = :create
                @allowed_actions = [:create, :start, :stop, :delete]

                @name = name
                @description = nil
                @template = nil

                @cpus = 1
                @memory = 512

                @image = nil
                @storage = nil

                @extra_block_storage = nil

                @ssh_user = nil
                @ssh_key = nil

                @network = nil
                @target_network = nil

                @hostname = nil
                @domain = nil
                @address = nil
                @gateway = nil
                @netmask = nil
                @dns_servers = nil

                @boot_options = nil
            end

            # A long description for the VM
            def description(arg=nil)
                set_or_return(:description, arg, :kind_of => String)
            end

            # The template to use when building the VM
            def template(arg=nil)
                set_or_return(:template, arg, :kind_of => String, :required => true)
            end

            # The number of CPUs for the VM
            def cpus(arg=nil)
                set_or_return(:cpus, arg, :kind_of => Integer)
            end

            # The amount of memory in MB
            def memory(arg=nil)
                set_or_return(:memory, arg, :kind_of => Integer)
            end

            # VM image to use
            def image(arg=nil)
                set_or_return(:image, arg, :kind_of => String)
            end

            # VM storage to use
            def storage(arg=nil)
                set_or_return(:storage, arg, :kind_of => String)
            end

            # Extra storage disks
            def extra_block_storage(arg=nil)
                set_or_return(:extra_block_storage, arg, :kind_of => Array)
            end

            # The name of the network to bring the VM up on. If static IP and no target_network is provided then xenstore vmdata will be used
            def network(arg=nil)
                set_or_return(:network, arg, :kind_of => String, :required => true)
            end

            # The name of the network to re-attach to after configuring the network static IP settings via SSH
            def target_network(arg=nil)
                set_or_return(:target_network, arg, :kind_of => String)
            end

            # User to login/ssh with after first boot for vm configuration
            def ssh_user(arg=nil)
                set_or_return(:ssh_user, arg, :kind_of => String)
            end

            # ID of User key/password to use to login/ssh on first boot read from the "users" encrypted data bag
            def ssh_key(arg=nil)
                set_or_return(:ssh_key, arg, :kind_of => String)
            end

            # The VMs hostname
            def hostname(arg=nil)
                set_or_return(:hostname, arg, :kind_of => String, :required => true)
            end

            # The network domain
            def domain(arg=nil)
                set_or_return(:domain, arg, :kind_of => String)
            end

            # A static IP for the VM (if not provided then it will be assumed the image is configured for DHCP)
            def address(arg=nil)
                set_or_return(:address, arg, :kind_of => String)
            end

            # The gateway for static configuration
            def gateway(arg=nil)
                set_or_return(:gateway, arg, :kind_of => String)
            end

            # The netmask for static configuration
            def netmask(arg=nil)
                set_or_return(:netmask, arg, :kind_of => String)
            end

            # Space separated list DNS servers to configure if statc IP
            def dns_servers(arg=nil)
                set_or_return(:dns_servers, arg, :kind_of => String)
            end
        end

    end
end
