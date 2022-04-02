local socket = require("socket")

class.Socket()
function Socket:_init(sock)
	self:super()
    if sock then
        self.socket = sock
    else
        self.socket = socket.tcp()
    end
end

function Socket:bind(host, port)
    return self.socket:bind(host, port)
end

function Socket:listen(backlog)
    return self.socket:listen(backlog)
end

function Socket:accept()
    local newSocket, err = self.socket:accept()
    if newSocket then
        return Socket(newSocket), err
    end
    return nil, err
end

function Socket:connect(host, port)
    return self.socket:connect(host, port)
end

function Socket:setTimeout(timeout)
    self.socket:settimeout(timeout)
end

function Socket:send(s)
    return self.socket:send(s)
end

function Socket:receive(length)
    return self.socket:receive(length)
end

function Socket:close()
    self.socket:close()
end