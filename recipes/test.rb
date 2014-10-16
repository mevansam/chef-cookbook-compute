#
# Cookbook Name:: network
# Recipe:: test
#

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

# vm "xen_vm_test" do

# 	description "Xen VM Test"

# 	template "T-U1404-FID14a"

# 	cpus 2
# 	memory 2048

# 	image "fd5bbf6f-6cce-44e7-a435-d8a8fe758cba"
# 	storage "133f0028-7126-a3a9-52fe-1ea7cd6d313c"

# 	network "vlan714"

# 	ssh_user "root"
# 	ssh_key "-----BEGIN RSA PRIVATE KEY-----\nMIIEoAIBAAKCAQEAnt0WVjO0yr/RicnZeXTDIbiv+cgPxtloFEGRt49BlsTG1/JD\nkSY/VH1IxPae8LJcIvgXaRZPG/D9vxMisVXdyHuG6hLB79gVhuPx48jS+JdE/b78\nVsEQHSlRDAnRtcA4tHvV1CapHvxZRzSSQXz3ehq/Pr2jRFrsPtiTgU1Bo/uA9DEo\n2sGMDoy/SPRq+IhLEfjrNdyfrblyUT6wNKdqAI4ZEgEIXawWcjxS+hykRUf85ZLh\nOpiRkuGMqW64WTCummM33THLL1fHQTZpx2Y9A2VLs/sZZYhitblJQ0wt2Z593/Gy\ndOjLFV2MAUTtW9W1BAWfLOInZ1fB/tnFdwo3UwIBIwKCAQAx7baQHuEMhW29lzW4\ndSdiXp205xrmuVs5kPNIUZhFU8l3EaA07sNyU0LBj1aGKW1qE3USZhjc5VcQKpXf\n9mpGUrVfgjzzm67+gidzeaFkEkjiCNL2sbSbc2KdYiv3SwqB3cbcRqouT09CQ7jw\nArQtsKKBbszpmOspscf1cA1QyuRFZ/NmHZ18YgnkRd7Jnc9/fEEVPu2VoG+eaNRW\nkDeSCxWQuTwvZg8raZjSyX7KynqyOWXfPCD26oegDh97z3tNV9OQLd6+znsBZsKq\nlbAFAFYGGhuDMt0PW5nCOe4CUyULUusMKP93PUUD6ZloW/dDbmCtwczP68PW2lQ6\n18MDAoGBAMw86oqOqT/u3XrN+/Hqq10tyIiBsN1WeYrknwvCbEMLQ437PeHX4MnY\nF/jW8lcpoxp4htPFZGik/AQmnKJU16RhSsdG5cjsima8rj5tVHQAvUNZP36QfBho\nmO1qSKIgbG++/3xi0jqLoyGEpqosuEiJcjdb34l6fz3O2EBFTcN1AoGBAMcgQa8e\ndD/Cd1ONX/oAuEJl05OfHbceEuFdUhgY++qBsulhjQnu+u3KMXPhkeg5Ty17yclR\n0e6Wb6puSA7uxN79L4mc/+BvU6qXWHokBvYKBA3qOf15anOn5aEpM/ODQMbOXr6O\nTkxra9S1/M9usvykBaiQ38xujUObp+2NyB6nAoGAC6u1oYR+szI4iqyvT6cCelpj\nOwAYvDDTvss8SdCYeNwSfSRMrdHSVK1DMsp0P3643PDxwvVWMd2KvmibPHngb8sL\nllvSncRfrhlpCuGtDfFp5pditsZtfbzViejQ81JPVte20+hjyNTHfkIYJvs9uwCK\nLwyQbkGDnSHDNt9jh4MCgYBERZLc9H+g1PW2PxmXizfcQCtIjlNUudqWaSN1+e/4\noX8rcec2mxQ0RVLIpRwVGvaTQGJw6NpDLEOK4/ty1YVTxIVTwMzB+kiSQoS8KZv8\nlbg/SP3wgWZTigWWV0UDCG37BO1IpdGzzQ8HGdMFSoaCgWEGmBI3dlxRsbXrDAoZ\nIwKBgGw7ECMLb2etUr+9BW+rLERtShOfFDhjJMIqdsNFi5wt7RrMFjb9PoejWdq/\nHGXL4HDqxmz/alJnVGSx/+FzySV7/EktCsOz2fU1TDVWHPhARHh5NqSPbOSW3unD\nNrvEjh9Bz7q875xqPorCk3EjGMndIk+db9BCa5f8xy7PEn1j\n-----END RSA PRIVATE KEY-----"
# 	target_network "vlan702"

# 	extra_block_storage [ 50, 100 ]

# 	domain "fmr.com"
# 	address "10.207.102.30"
# 	gateway "10.207.102.1"
# 	netmask "255.255.255.0"
# 	dns_servers "172.25.10.15 10.47.42.15 172.22.102.76"
# end
