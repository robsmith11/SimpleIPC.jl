module SimpleIPC

export
 ipc_connect,
 ipc_eval,
 ipc_listen,
 ipc_run,
 ipc_set

import Serialization
import Sockets

macro async_showerr(ex)
 quote
  t = @async while true
   try
    eval($(esc(ex)))
   catch err
    err isa EOFError && break 
    bt = catch_backtrace()
    println("Async error: ")
    showerror(stderr, err, bt)
   end
  end
 end
end


function ipc_listen(addr::Sockets.InetAddr)
 server = Sockets.listen(addr)
 @async while true
  socket = Sockets.accept(server)
  Sockets.nagle(socket, false)
  @async_showerr begin
   b = read(socket, UInt8)
   if b == 0x01
    Main.eval(Serialization.deserialize(socket))
   elseif b == 0x02
    name = Serialization.deserialize(socket)
    val = Serialization.deserialize(socket)
    @eval(Main, $name = $val)
   elseif b == 0x03
    fun = Serialization.deserialize(socket)
    args = Serialization.deserialize(socket)
    @eval(Main, $fun($args...))
   end
  end
 end
 server
end
ipc_listen(host::Sockets.IPAddr, port::Integer) = ipc_listen(Sockets.InetAddr(host, port))
ipc_listen(host::AbstractString, port::Integer) = ipc_listen(Sockets.InetAddr(Sockets.getaddrinfo(host), port))
ipc_listen(port::Integer) = ipc_listen(Sockets.localhost, port)

function ipc_connect(addr::Sockets.InetAddr)
 socket = Sockets.connect(addr)
 Sockets.nagle(socket, false)
 socket
end
ipc_connect(host::Sockets.IPAddr, port::Integer) = ipc_connect(Sockets.InetAddr(host, port))
ipc_connect(host::AbstractString, port::Integer) = ipc_connect(Sockets.InetAddr(Sockets.getaddrinfo(host), port))
ipc_connect(port::Integer) = ipc_connect(Sockets.localhost, port)

function ipc_eval(h::Sockets.TCPSocket, x::Expr)
 write(h, 0x01)
 Serialization.serialize(h, x)
 flush(h)
end

function ipc_set(h::Sockets.TCPSocket, name::Symbol, val)
 write(h, 0x02)
 Serialization.serialize(h, name)
 Serialization.serialize(h, val)
 flush(h)
end

function ipc_run(h::Sockets.TCPSocket, fun::Union{Expr,Symbol}, args::Tuple)
 write(h, 0x03)
 Serialization.serialize(h, fun)
 Serialization.serialize(h, args)
 flush(h)
end

end # module
