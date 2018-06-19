# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::haproxy
#
# Loadbalancer profile for tripleo
#
# === Parameters
#
# [*mysql_read_default_file*]
#   (Optional) Name of the file that will be passed to pymysql connection strings
#   Defaults to hiera('tripleo::profile::base:database::mysql::read_default_file', '/etc/my.cnf.d/tripleo.cnf')
#
# [*mysql_read_default_group*]
#   (Optional) Name of the ini section to be passed to pymysql connection strings
#   Defaults to hiera('tripleo::profile::base:database::mysql::read_default_group', 'tripleo')
#
# [*mysql_client_bind_address*]
#   (Optional) Client IP address of the host that will be written in the mysql_read_default_file
#   Defaults to hiera('tripleo::profile::base:database::mysql::client_bind_address', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::database::mysql::client (
  $mysql_read_default_file   = hiera('tripleo::profile::base:database::mysql::read_default_file', '/etc/my.cnf.d/tripleo.cnf'),
  $mysql_read_default_group  = hiera('tripleo::profile::base:database::mysql::read_default_group', 'tripleo'),
  $mysql_client_bind_address = hiera('tripleo::profile::base:database::mysql::client_bind_address', undef),
  $step = hiera('step'),
) {
  if $step >= 1 {
    # If the folder /etc/my.cnf.d does not exist (e.g. if mariadb is not
    # present in the base image but installed as a package afterwards),
    # create it. We do not want to touch the permissions in case it already
    # exists due to the mariadb server package being pre-installed
    # Note: We use exec instead of file in the case that the mysql class is
    # included on this node as well (we'd get duplicate declaration in such a
    # situation when using file)
    if $mysql_client_bind_address {
      $changes = [
        "set ${mysql_read_default_group}/bind-address '${mysql_client_bind_address}'"
      ]
    } else {
      $changes = [
        "rm ${mysql_read_default_group}/bind-address"
      ]
    }
    exec { 'directory-create-etc-my.cnf.d':
      command => 'mkdir -p /etc/my.cnf.d',
      path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    } ->
    # Create /etc/my.cnf.d/tripleo.cnf with the [tripleo]bind-address=<IP of the node in the mysql network>
    augeas { 'mysql-bind-address':
      incl    => $mysql_read_default_file,
      lens    => 'Puppet.lns',
      changes => $changes,
    }
  }
}
