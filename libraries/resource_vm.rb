# Copyright (c) 2014 Fidelity Investments.

require 'chef/resource'

class Chef
	class Resource

		class Vm < Chef::Resource

			def initialize(name, run_context=nil)
				super
				
				@resource_name = :vm

				# TODO: The provider type should be determined by introspecting the hypervisor type
				@provider = Chef::Provider::Vm::Xen

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
