# Opinionated piknik

Install piknik in /opt/piknik and make a symlink to the current (latest) version. [Downloads](wget https://github.com/jedisct1/piknik/releases/latest):

```bash
opt=/opt; piknik=${opt}/piknik
sudo install -o ${USER} -g ${USER} -D ${piknik} ; cd ${piknik}
wget https://github.com/jedisct1/piknik/releases/download/0.10.1/piknik-linux_x86_64-0.10.1.tar.gz
tar --one-top-level -xaf piknik-linux_x86_64-0.10.1.tar.gz
```

Fetch the "wrapping" bash script from github:

```bash
git clone https://github.com/mcarifio/piknik-wrappers /opt/piknik/current
current=${piknik}/current; cd ${current}
ln -sr piknik-linux_x86_64-0.10.1/linux-x86_64 current/bin # current version now at /opt/piknik/current/bin/piknik
```

Generate configuration files:

```bash
cd ${current}; export PATH="/opt/piknik/current/bin:$PATH"
piknik -version
piknik -config > piknik.dist.toml
```

Split `piknik.dist.toml` into three parts:

* `piknik-client-remote.toml`
* `piknik-client-local.toml`
* `piknik-server.toml`

Designate some machine to serve all the others, for example `zendeavor`. Identify all the clients that will use server `zendeavor`,
for example `zendeavor` itself, `zenterprise`, `discovery`, `atlantis` and `surface` respectively.

Using `${current}/piknik-server.sh`, start the server:

```bash
./piknik-server.sh
```

TODO: create a systemd unit and socket file based on piknik-server.

For each remote client, copy the "piknik tree" to `/opt/piknik`:

```bash
remote=discovery # edit
ssh ${remote} sudo install -o ${SSH_USER} -g ${SSH_USER} -D ${piknik}
rsync -avz ${piknik} ${remote}:${piknik}
ssh ${remote} xz ${PWD}/{piknik-client-local.toml,piknik-server.*}
```

For each client, source the bash "environment" script:

```bash
source ${current}/piknik.env.sh
```

Confirm the `piknik` "command":

```bash
type -a piknik

piknik is a function
piknik () 
{ 
    command piknik -config /opt/piknik/current/piknik-client-local.toml $*
}
piknik is /opt/piknik/current/bin/piknik
```

Confirm the service is running:

```bash
osqueryi "select distinct p.pid, p.name, p.cmdline, u.username, g.groupname, l.port from processes as p join listening_ports as l on p.pid = l.pid join users as u on p.uid = u.uid join groups as g on p.gid = g.gid where p.name = 'piknik' and (l.address = '0.0.0.0' or l.address = '::');"

+---------+--------+---------------------------------------------------------------------------------------+----------+-----------+------+
| pid     | name   | cmdline                                                                               | username | groupname | port |
+---------+--------+---------------------------------------------------------------------------------------+----------+-----------+------+
| 1526127 | piknik | /opt/piknik/current/bin/piknik -config /opt/piknik/current/piknik-server.toml -server | mcarifio | mcarifio  | 8075 |
+---------+--------+---------------------------------------------------------------------------------------+----------+-----------+------+
```

Send something and then retrieve it:

```bash
date | tee /dev/stderr | piknik -copy
Sat Jun 12 01:49:53 PM EDT 2021
Sent

piknik
Sat Jun 12 01:49:53 PM EDT 2021
```

They should be the same.

