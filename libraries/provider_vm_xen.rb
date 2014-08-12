# Copyright (c) 2014 Fidelity Investments.

require 'chef/provider'
require 'chef/mixin/shell_out'
require 'uri/http'
require 'erb'

class Chef
	class Provider

		class Vm

			class Xen < Chef::Provider

				include Chef::Mixin::ShellOut
				include ERB::Util

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
							sh = shell_out!("xe vdi-list name-label=\"#{@current_resource.image}\" --minimal"); sh.error!
							image_uuid = sh.stdout.chomp
						end
						Chef::Log.debug("Using image with uuid: #{image_uuid}")
					end

					if !@current_resource.storage.nil?
						if @current_resource.storage =~ /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/
							storage_uuid = @current_resource.storage
						else
							sh = shell_out!("xe sr-list name-label=\"#{@current_resource.storage}\" --minimal"); sh.error!
							storage_uuid = sh.stdout.chomp
						end
						Chef::Log.debug("Using storage with uuid: #{storage_uuid}")

						sh = shell_out!("xe sr-scan uuid=#{storage_uuid}"); sh.error!
					end

					sh = shell_out!("xe template-list name-label=\"#{@current_resource.template}\" --minimal"); sh.error!
					template_uuid = sh.stdout.chomp
					Chef::Log.debug("Using template with uuid: #{template_uuid}")

					sh = shell_out!( "xe network-list name-label=\"#{@current_resource.network}\" params=all | " + 
						"grep -B 4 \"PIF-uuids (SRO): [a-z0-9-]\" | awk '/uuid \\( RO\\)/ { print $5 }'" ); sh.error!
					network_uuid = sh.stdout.chomp
					Chef::Log.debug("VM will be first booted on network with uuid: #{network_uuid}")

					if !@current_resource.target_network.nil?
						sh = shell_out!( "xe network-list name-label=\"#{@current_resource.target_network}\" params=all | " + 
							"grep -B 4 \"PIF-uuids (SRO): [a-z0-9-]\" | awk '/uuid \\( RO\\)/ { print $5 }'" ); sh.error!
						target_network_uuid = sh.stdout.chomp
						Chef::Log.debug("VM will be configured on network with uuid: #{target_network_uuid}")
					end

					sh = shell_out!("xe vm-install new-name-label=\"#{name}\" template-uuid=\"#{template_uuid}\""); sh.error!
					vm_uuid = sh.stdout.chomp

					Chef::Log.debug("Created new VM with uuid: #{vm_uuid}")

					cpus = @current_resource.cpus
					memory = @current_resource.memory * 1048576
					memory_min = (memory * 0.005).to_i

					shell_out!( "xe vm-param-set uuid=#{vm_uuid} " + 
						"name-description=\"#{@current_resource.description}\" " +
						"VCPUs-max=#{cpus} " + 
						"VCPUs-at-startup=#{cpus} " + 
						"memory-static-max=#{memory} " + 
						"memory-dynamic-max=#{memory} " + 
						"memory-dynamic-min=#{memory} " + 
						"memory-static-min=#{memory_min}" ); sh.error!

					if !image_uuid.nil?

						sh = shell_out!("xe vbd-list vm-uuid=#{vm_uuid} | " + 
							"grep -B 3 \"vdi-uuid ( RO): [a-f0-9]\" | awk '/^uuid/ { print $5 }'" ); sh.error!
						vbd_uuids = sh.stdout.chomp.split

						vbd_uuids.each do |vbd_uuid|
							shell_out!("xe vbd-destroy uuid=#{vbd_uuid}"); sh.error!
						end

	                    sh = shell_out!("xe vdi-copy uuid=#{image_uuid} sr-uuid=#{storage_uuid}"); sh.error!
	                    vdi_uuid = sh.stdout.chomp

	                    shell_out!("xe vdi-param-set name-label=\"#{name}_disk_0\" uuid=#{vdi_uuid}"); sh.error!

	                    sh = shell_out!("xe vbd-create vm-uuid=#{vm_uuid} device=0 vdi-uuid=#{vdi_uuid} bootable=true mode=RW type=Disk"); sh.error!
	                    vbd_uuid = sh.stdout.chomp

	                    shell_out!("xe vbd-param-add param-name=other-config owner=true uuid=#{vbd_uuid}"); sh.error!

	                    Chef::Log.debug("Root disk uuid is: #{vbd_uuid}")
	                end

                    i = 1
                    @current_resource.extra_block_storage.each do |disk_size|

                    	Chef::Log.debug("Creating extra storage disk with size #{disk_size} GB.")
                    	size = disk_size * 1073741824

                    	sh = shell_out!("xe vdi-create " +
                    		"sr-uuid=#{storage_uuid} " +
                    		"name-label=#{name}_disk_#{i} " +
                    		"type=user " +
                    		"virtual-size=#{size}"); sh.error!
                    	vdi_uuid = sh.stdout.chomp

                    	sh = shell_out!("xe vbd-create vm-uuid=#{vm_uuid} device=#{i} vdi-uuid=#{vdi_uuid} mode=RW type=Disk"); sh.error!
	                    vbd_uuid = sh.stdout.chomp

	                    shell_out!("xe vbd-param-add param-name=other-config owner=true uuid=#{vbd_uuid}"); sh.error!

                    	i += 1
                    end

                    shell_out!("xe vif-create network-uuid=#{network_uuid} vm-uuid=#{vm_uuid} device=0"); sh.error!

                    if target_network_uuid.nil?
                    	shell_out!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/ip=\"#{@current_resource.address}\""); sh.error!
                    	shell_out!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/gw=\"#{@current_resource.gateway}\""); sh.error!
                    	shell_out!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/nm=\"#{@current_resource.netmask}\""); sh.error!
                    	shell_out!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/ns=\"#{@current_resource.dns_servers}\""); sh.error!
                    	shell_out!("xe vm-param-add uuid=#{vm_uuid} param-name=xenstore-data vm-data/dm=\"#{@current_resource.domain}\""); sh.error!
                    end

                    xen_host = node['fqdn']
                    sh = shell_out!("xe host-list name-label=\"#{xen_host}\" --minimal"); sh.error!
                    xen_host_uuid = sh.stdout.chomp

	                Chef::Log::debug("Starting VM \"#{name}\" and waiting for it to become active...")
                    shell_out!("xe vm-start uuid=#{vm_uuid} on=#{xen_host_uuid}"); sh.error!

	                shell_out!("while [ \"$(xe vm-param-list uuid=#{vm_uuid} | awk '/power-state/ { print $4 }')\" != \"running\" ]; do sleep 1; done"); sh.error!
                	shell_out!("while [ \"$(xe vm-param-list uuid=#{vm_uuid} | awk '/networks/ { print $4 }')\" == \"in\" ]; do sleep 1; done"); sh.error!

                	if !target_network_uuid.nil?

                		sh = shell_out!("xe vm-param-list uuid=#{vm_uuid} | awk '$1==\"networks\" { print $4 }'")
                		vm_ip = sh.stdout.chomp
	                	Chef::Log::debug("SSH'ing to VM with IP #{vm_ip} to complete network configuration.")

						@ssh = OSEnv::Helper::SSH.new(vm_ip, @current_resource.ssh_user, @current_resource.ssh_key)

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

						shell_out!("xe vm-shutdown uuid=#{vm_uuid}"); sh.error!

						sh = shell_out!("xe vif-list vm-uuid=#{vm_uuid} | awk '/^uuid/ { print $5 }'"); sh.error!
						vif_uuids = sh.stdout.chomp.split

						vif_uuids.each do |vif_uuid|
							shell_out!("xe vif-destroy uuid=#{vif_uuid}"); sh.error!
						end

                    	shell_out!("xe vif-create network-uuid=#{target_network_uuid} vm-uuid=#{vm_uuid} device=0"); sh.error!
                    	shell_out!("xe vm-start uuid=#{vm_uuid} on=#{xen_host_uuid}"); sh.error!
                	end
				end

				def action_start
					sh = shell_out!("xe vm-list name-label=\"@current_resource.name\" --minimal"); sh.error!
					vm_uuid = sh.stdout.chomp

					sh = shell_out!("xe vm-start uuid=#{vm_uuid}"); sh.error!
				end

				def action_stop
					sh = shell_out!("xe vm-list name-label=\"@current_resource.name\" --minimal"); sh.error!
					vm_uuid = sh.stdout.chomp

					sh = shell_out!("xe vm-shutdown uuid=#{vm_uuid}"); sh.error!
				end

				def action_delete
					sh = shell_out!("xe vm-list name-label=\"@current_resource.name\" --minimal"); sh.error!
					vm_uuid = sh.stdout.chomp

					sh = shell_out!("xe vm-uninstall uuid=#{vm_uuid} force=true"); sh.error!
				end
			end

		end

	end
end
