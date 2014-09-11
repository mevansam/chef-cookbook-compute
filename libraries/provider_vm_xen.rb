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

require 'chef/provider'
require 'uri/http'
require 'erb'

class Chef
	class Provider

		class Vm

			class Xen < Chef::Provider

				include ERB::Util
                include SysUtils::Helper

				def load_current_resource
					@current_resource ||= Chef::Resource::Vm.new(new_resource.name)

					if new_resource.description.nil?
						@current_resource.description(new_resource.name)
					else
						@current_resource.description(new_resource.description)
					end

					@current_resource.template(new_resource.template)

					@current_resource.cpus(new_resource.cpus)
					@current_resource.memory(new_resource.memory)

					@current_resource.image(new_resource.image)
					@current_resource.storage(new_resource.storage)
					@current_resource.extra_block_storage(new_resource.extra_block_storage)

					@current_resource.ssh_user(new_resource.ssh_user)
					@current_resource.ssh_key(new_resource.ssh_key)
					
					@current_resource.network(new_resource.network)
					@current_resource.target_network(new_resource.target_network)
					
					if new_resource.hostname.nil?
						@current_resource.hostname(new_resource.name)
					else
						@current_resource.hostname(new_resource.hostname)
					end	

					@current_resource.domain(new_resource.domain)
					@current_resource.address(new_resource.address)
					@current_resource.gateway(new_resource.gateway)
					@current_resource.netmask(new_resource.netmask)
					@current_resource.dns_servers(new_resource.dns_servers)
				end

				def action_create

					name = @current_resource.name

					image_uuid = nil
					storage_uuid = nil

					if !@current_resource.image.nil?
						if @current_resource.image =~ /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/
							image_uuid = @current_resource.image
						else
							image_uuid = shell("xe vdi-list name-label=\"#{@current_resource.image}\" --minimal")
						end
						Chef::Log.debug("Using image with uuid: #{image_uuid}")
					end

					if !@current_resource.storage.nil?
						if @current_resource.storage =~ /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/
							storage_uuid = @current_resource.storage
						else
							storage_uuid = shell("xe sr-list name-label=\"#{@current_resource.storage}\" --minimal")
						end
						Chef::Log.debug("Using storage with uuid: #{storage_uuid}")

						shell!("xe sr-scan uuid=#{storage_uuid}")
					end

					template_uuid = shell("xe template-list name-label=\"#{@current_resource.template}\" --minimal")
					Chef::Log.debug("Using template with uuid: #{template_uuid}")

					network_uuid = shell( "xe network-list name-label=\"#{@current_resource.network}\" params=all | " + 
						"grep -B 4 \"PIF-uuids (SRO): [a-z0-9-]\" | awk '/uuid \\( RO\\)/ { print $5 }'" )
					Chef::Log.debug("VM will be first booted on network with uuid: #{network_uuid}")

					if !@current_resource.target_network.nil?
						target_network_uuid = shell( "xe network-list name-label=\"#{@current_resource.target_network}\" params=all | " + 
							"grep -B 4 \"PIF-uuids (SRO): [a-z0-9-]\" | awk '/uuid \\( RO\\)/ { print $5 }'" )
						Chef::Log.debug("VM will be configured on network with uuid: #{target_network_uuid}")
					end

					vm_uuid = shell("xe vm-install new-name-label=\"#{name}\" template-uuid=\"#{template_uuid}\"")
					Chef::Log.debug("Created new VM with uuid: #{vm_uuid}")

					cpus = @current_resource.cpus
					memory = @current_resource.memory * 1048576
					memory_min = (memory * 0.005).to_i

					shell!( "xe vm-param-set uuid=#{vm_uuid} " + 
						"name-description=\"#{@current_resource.description}\" " +
						"VCPUs-max=#{cpus} " + 
						"VCPUs-at-startup=#{cpus} " + 
						"memory-static-max=#{memory} " + 
						"memory-dynamic-max=#{memory} " + 
						"memory-dynamic-min=#{memory} " + 
						"memory-static-min=#{memory_min}" )

					if !image_uuid.nil?

						vbd_uuids = shell("xe vbd-list vm-uuid=#{vm_uuid} | " + 
							"grep -B 3 \"vdi-uuid ( RO): [a-f0-9]\" | awk '/^uuid/ { print $5 }'" )

						vbd_uuids.each do |vbd_uuid|
							shell!("xe vbd-destroy uuid=#{vbd_uuid}")
						end

	                    vdi_uuid = shell("xe vdi-copy uuid=#{image_uuid} sr-uuid=#{storage_uuid}")
	                    shell!("xe vdi-param-set name-label=\"#{name}_disk_0\" uuid=#{vdi_uuid}")
	                    vbd_uuid = shell("xe vbd-create vm-uuid=#{vm_uuid} device=0 vdi-uuid=#{vdi_uuid} bootable=true mode=RW type=Disk")
	                    shell!("xe vbd-param-add param-name=other-config owner=true uuid=#{vbd_uuid}")

	                    Chef::Log.debug("Root disk uuid is: #{vbd_uuid}")
	                end

                    i = 1
                    @current_resource.extra_block_storage.each do |disk_size|

                    	Chef::Log.debug("Creating extra storage disk with size #{disk_size} GB.")
                    	size = disk_size * 1073741824

                    	vdi_uuid = shell("xe vdi-create " +
                    		"sr-uuid=#{storage_uuid} " +
                    		"name-label=#{name}_disk_#{i} " +
                    		"type=user " +
                    		"virtual-size=#{size}")

                    	vbd_uuid = shell("xe vbd-create vm-uuid=#{vm_uuid} device=#{i} vdi-uuid=#{vdi_uuid} mode=RW type=Disk")
	                    shell!("xe vbd-param-add param-name=other-config owner=true uuid=#{vbd_uuid}")

                    	i += 1
                    end

                    shell!("xe vif-create network-uuid=#{network_uuid} vm-uuid=#{vm_uuid} device=0")

                    if target_network_uuid.nil?
                    	shell!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/ip=\"#{@current_resource.address}\"")
                    	shell!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/gw=\"#{@current_resource.gateway}\"")
                    	shell!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/nm=\"#{@current_resource.netmask}\"")
                    	shell!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/ns=\"#{@current_resource.dns_servers}\"")
                    	shell!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/dm=\"#{@current_resource.domain}\"")
                    end

                    xen_host = node['fqdn']
                    xen_host_uuid = shell("xe host-list name-label=\"#{xen_host}\" --minimal")

	                Chef::Log::debug("Starting VM \"#{name}\" and waiting for it to become active...")
                    shell!("xe vm-start uuid=#{vm_uuid} on=#{xen_host_uuid}")

	                shell!("while [ \"$(xe vm-param-list uuid=#{vm_uuid} | awk '/power-state/ { print $4 }')\" != \"running\" ]; do sleep 1; done")
                	shell!("while [ \"$(xe vm-param-list uuid=#{vm_uuid} | awk '/networks/ { print $4 }')\" == \"in\" ]; do sleep 1; done")

                	if !target_network_uuid.nil?

                		vm_ip = shell("xe vm-param-list uuid=#{vm_uuid} | awk '$1==\"networks\" { print $4 }'")
	                	Chef::Log::debug("SSH'ing to VM with IP #{vm_ip} to complete network configuration.")

						@ssh = ::SysUtils::SSH.new(vm_ip, @current_resource.ssh_user, @current_resource.ssh_key)

						hostname = @current_resource.hostname
						domain = @current_resource.domain

						results = @ssh.execute( "echo \"#{hostname}\" > /etc/hostname && " +
                        	"sed -i 's|127\.0\.1\.1.*|127.0.1.1\t#{hostname}.#{domain}\t#{hostname}|' /etc/hosts && " +
                            "sed -i 's|iface eth0 inet dhcp|iface eth0 inet static\\n" + 
                            "    address #{@current_resource.address}\\n" + 
                            "    gateway #{@current_resource.gateway}\\n" + 
                            "    netmask #{@current_resource.netmask}\\n" + 
                            "    dns-nameservers #{@current_resource.dns_servers}\\n" + 
                            "    dns-search #{@current_resource.domain}|' /etc/network/interfaces" )

						Chef::Log::debug("SSH configuration of #{vm_ip} results: #{results}")

						shell!("xe vm-shutdown uuid=#{vm_uuid}")

						vif_uuids = shell("xe vif-list vm-uuid=#{vm_uuid} | awk '/^uuid/ { print $5 }'")

						vif_uuids.each do |vif_uuid|
							shell!("xe vif-destroy uuid=#{vif_uuid}")
						end

                    	shell!("xe vif-create network-uuid=#{target_network_uuid} vm-uuid=#{vm_uuid} device=0")
                    	shell!("xe vm-start uuid=#{vm_uuid} on=#{xen_host_uuid}")
                	end
				end

				def action_start
					vm_uuid = shell("xe vm-list name-label=\"@current_resource.name\" --minimal")
					shell!("xe vm-start uuid=#{vm_uuid}")
				end

				def action_stop
					vm_uuid = shell("xe vm-list name-label=\"@current_resource.name\" --minimal")
					shell!("xe vm-shutdown uuid=#{vm_uuid}")
				end

				def action_delete
					vm_uuid = shell("xe vm-list name-label=\"@current_resource.name\" --minimal")
					shell!("xe vm-uninstall uuid=#{vm_uuid} force=true")
				end
			end

		end

	end
end
