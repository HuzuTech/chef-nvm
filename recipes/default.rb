#
# Cookbook Name:: nvm
# Recipe:: default
#

package 'curl'
package 'git-core'

$user  = node['nvm']['user']
$group = node['nvm']['group'] || $user
$home  = node['nvm']['home'] || "/home/#{$user}"
$env   = { 'HOME' => $home }
$profile = "#{$home}/.bashrc"
$flags = "-x"
$nvm_sh = "#{$home}/.nvm/nvm.sh"
$nvm_source = "source #{$nvm_sh}"

bash "clone-nvm" do
  user  $user
  group $group
  cwd   $home
  environment $env
  flags $flags

  creates "#{$home}/.nvm"
  code "git clone git://github.com/creationix/nvm.git #{$home}/.nvm"
  notifies :run, "bash[install-nvm]", :immediately
end

bash "install-nvm" do
  user  $user
  group $group
  cwd   $home
  environment $env
  flags $flags

  code "#{$home}/.nvm/install.sh && #{$nvm_source}"
  notifies :run, "bash[activate-nvm]", :immediately
end

bash "activate-nvm" do
  user  $user
  group $group
  cwd   $home
  environment $env
  flags $flags

  code <<-EOF
if ! grep -qc 'nvm.sh' #{$profile}; then
  echo #{$nvm_source} >> #{$profile}
fi
  EOF
  notifies :run, "bash[install-nodes]", :immediately
end

bash "install-nodes" do
  user  $user
  group $group
  cwd   $home
  environment $env
  flags $flags

  versions = Array(node['nvm']['node_versions'])

  code versions.map { |v| "#{$nvm_source} && nvm install #{v}" }.join("\n").strip
  if node['nvm']['default_node_version'] || versions.count > 0
    notifies :run, "bash[make-default-node-version]", :immediately
  end
  action :nothing
end

bash "make-default-node-version" do
  user  $user
  group $group
  cwd   $home
  environment $env
  flags $flags

  version = node['nvm']['default_node_version'] || Array(node['nvm']['node_versions']).first
  code "#{$nvm_source} && nvm alias default #{version}"
  notifies :run, "bash[install-npm]", :immediately
  action :nothing
end

bash "install-npm" do
  user  $user
  group $group
  cwd   $home
  environment $env
  flags $flags

  code <<-EOF
git clone git://github.com/isaacs/npm.git /tmp/npm && \
#{$nvm_source} && nvm use default && cd /tmp/npm \
&& make install && rm -Rf /tmp/npm
  EOF
  action :nothing
end
