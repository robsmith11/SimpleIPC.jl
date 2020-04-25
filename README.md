# SimpleIPC.jl

Simple inter-process communication (IPC) functions to evaluate expressions, set values, and run functions on another Julia process using TCP sockets.

These functions were inspired by the simple IPC of kdb+/q.  TCP sockets are used so that IPC can work with processes running on the same machine or remote networks.

Slightly better performance could be achieved with the same interface by using platform-dependent IPC (e.g., named pipes for Linux may be added in the future).

## Security Warning

This package currently includes no access restrictions (pull requests accepted).  Running an open socket that can evaluate arbitrary code, especially when bound to a public network interface, can put your system at significant risk.  Careful consideration of your network and firewall rules is required for secure use.

## Example

Server Process:
```julia
julia> using SimpleIPC

# Bind to local interface by default
# Use `ipc_listen("123.123.123.123", 12345)` for remote host
julia> h = ipc_listen(12345) 
Sockets.TCPServer(RawFD(0x00000012) active)

...

julia> close(h)  # When finished, the socket can be closed
```

Client Process:
```julia
julia> using SimpleIPC

julia> h = ipc_connect(12345)
Sockets.TCPSocket(RawFD(0x00000013) open, 0 bytes waiting)

julia> ipc_eval(h, :(println(rand())))

julia> ipc_set(h, :xx, rand(10^6))

# Arguments to the function to be run must be passed as a tuple
julia> ipc_run(h, :println, ("hello",))

julia> ipc_run(h, :println, ("hello ", rand()))

julia> close(h)
```
