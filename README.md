# Opinionated piknik

Install piknik in /opt/piknik and make a symlink to the current (latest) version. [Downloads](https://github.com/jedisct1/piknik/releases/latest) here:

```bash
opt=/opt; piknik=${opt}/piknik
sudo install -o ${USER} -g ${USER} -D ${piknik} ; cd ${piknik}
wget https://github.com/jedisct1/piknik/releases/download/0.10.1/piknik-linux_x86_64-0.10.1.tar.gz # edit version
tar --one-top-level -xaf piknik-linux_x86_64-0.10.1.tar.gz # edit version
```
At this point, you have:

```bash
tree piknik-linux_x86_64-0.10.1
piknik-linux_x86_64-0.10.1
└── linux-x86_64
    └── piknik
```
which is piknik for `X86_64` version `0.10.1`. Your architecture and version might be different.


Fetch the "wrapping" bash scripts from github:

```bash
git clone https://github.com/mcarifio/piknik-wrappers /opt/piknik/current
current=${piknik}/current; cd ${current}
ln -sr ${pitnik}/piknik-linux_x86_64-0.10.1/linux-x86_64 ${current}/bin # current version now at /opt/piknik/current/bin/piknik
```

At this point you have:

```bash
tree -F
.
├── current/
│   ├── bin -> ../piknik-linux_x86_64-0.10.1/linux-x86_64/
│   ├── LICENSE
│   ├── piknik.env.sh
│   ├── piknik-server.sh*
│   └── README.md
├── piknik-linux_x86_64-0.10.1/
│   └── linux-x86_64/
│       └── piknik*
└── piknik-linux_x86_64-0.10.1.tar.gz
```

IMO when you install a new version of `piknik`, you should install it alongside `piknik-linux_x86_64-0.10.1` and link `bin` to "the right one."


Generate configuration files:

```bash
export PATH="/opt/piknik/current/bin:$PATH"
piknik -version
piknik -genkeys > piknik.dist.toml
```

Split `piknik.dist.toml` into three parts:

* `piknik-client-remote.toml`
* `piknik-client-local.toml`
* `piknik-server.toml`

Designate some machine to serve all the others, for example `zendeavor`. Identify all the clients that will use server `zendeavor`,
for example `zendeavor` itself, `zenterprise`, `discovery`, `atlantis` and `surface` respectively.

Using `${current}/piknik-server.sh`, start the server:

```bash
./piknik-server.sh # runs nohup
```

TODO: create a systemd unit and socket file based on `piknik-server.sh`.

Confirm the service is running:

```bash
osqueryi "select distinct p.pid, p.name, p.cmdline, u.username, g.groupname, l.port from processes as p join listening_ports as l on p.pid = l.pid join users as u on p.uid = u.uid join groups as g on p.gid = g.gid where p.name = 'piknik' and (l.address = '0.0.0.0' or l.address = '::');"

+---------+--------+---------------------------------------------------------------------------------------+----------+-----------+------+
| pid     | name   | cmdline                                                                               | username | groupname | port |
+---------+--------+---------------------------------------------------------------------------------------+----------+-----------+------+
| 1526127 | piknik | /opt/piknik/current/bin/piknik -config /opt/piknik/current/piknik-server.toml -server | mcarifio | mcarifio  | 8075 |
+---------+--------+---------------------------------------------------------------------------------------+----------+-----------+------+
```

There are all sorts of ways to do this and `osqueryi` is a little exotic. `ps aux|grep piknik` works.

On `localhost`, copy and paste something to test the server. By starting with `localhost` you simplify your investigation. No firewalls.

First source the bash "environment" script:

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

Send something and then retrieve it:

```bash
date | tee /dev/stderr | piknik -copy
Sat Jun 12 01:49:53 PM EDT 2021
Sent

piknik
Sat Jun 12 01:49:53 PM EDT 2021
```

The dates should match exactly.

For each remote client, copy the "piknik tree" to `${remote}:/opt/piknik`. This will include the executable image as well.
If your remotes aren't all the same architecture (e.g. `X86_64`), you may have to install the correct image per architecture.
The arch command can be helpful here.

```bash
remote=discovery # edit the remote or write a script
remote_user=${USER} # edit
ssh ${remote} sudo install -o ${remote_user} -g ${remote_user} -D ${piknik} # create the target root with the correct ownership
rsync -avz ${piknik} ${remote}:${piknik}
ssh ${remote} xz ${PWD}/{piknik-client-local.toml,piknik-server.*}
```

If you are running a firewall, you need to expose port 8075 (or whatever port you chose). This depends on the platform. Ubuntu uses [`ufw`](https://wiki.ubuntu.com/UncomplicatedFirewall),
Fedora uses [`firewalld`](https://docs.fedoraproject.org/en-US/quick-docs/firewalld/), Windows uses [Window Defender](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/windows-firewall-with-advanced-security) and you may use yet something else. If you're accessing the server from beyond your firewall, you may have to update two firewalls (one at your router and one on the server machine).
This gets complicated. If you are having issues connecting from a remote machine, but `localhost` worked, then it's very likely a firewall block. If you want to confirm that, shut off the firewall temporarily and
try `nc -zw3 ${server} 8075`. If you can connect, great! Now you need to figure out how to "open" `${server}:8075`. Let's assume you're running a firewall if you want to and your `${remote}` can "see"
`${server}:8075`. Now you reproduce the `localhost` client test on the `${remote}`, e.g. `discovery` above:

```bash
source ${current}/piknik.env.sh

type -a piknik

piknik is a function
piknik () 
{ 
    command piknik -config /opt/piknik/current/piknik-client-remote.toml $*
}
piknik is /opt/piknik/current/bin/piknik
```
Note that the client configuration file has a different name. You compressed `piknik-client-local.toml` so it isn't "found."


Retrieve something, send something and then retrieve it again:

```bash
piknik
Sat Jun 12 01:49:53 PM EDT 2021


date | tee /dev/stderr | piknik -copy
Sat Jun 12 02:49:53 PM EDT 2021
Sent

piknik
Sat Jun 12 02:49:53 PM EDT 2021
```

Once you've done one remote, you can do each remote you want. The firewall rules might be different. And confusing.
Think of all the TCP/IP you'll learn!




# An Aside

Note that you could probably obviate copying the `*.toml` files around by generating them locally with a password:

```bash
echo drowssap | piknik -genkeys -password > piknik.dist.toml
```

And then edit them on each remote. Either way you still have to manually edit them (at least currently).

TODO: announce the service using mdns? something like `_piknik._tcp: ${hostname}:8075`? How is this done?

