
class.Socket()
function Socket:_init(handle)
    if handle then
        self.handle = handle
    else
        self.handle = comm.rawSocketCreate()
    end
end

function Socket:bind(host, port)
    local err = comm.rawSocketBind(self.handle, host, port)
    if not err then return true, nil end
    return false, err
end

function Socket:listen(backlog)
    local err = comm.rawSocketListen(self.handle, backlog)
    if not err then return true, nil end
    return false, err
end

function Socket:accept()
    local newHandle, err = comm.rawSocketAccept(self.handle)
    if newHandle == 0 and not err then return nil, "timeout" end
    if newHandle > 0 then
        return Socket(newHandle)
    end
    return nil, err
end

function Socket:connect(host, port)
    local err = comm.rawSocketConnect(self.handle, host, port)
    if not err then return true, nil end
    return false, err
end

function Socket:setTimeout(timeout)
    return comm.rawSocketSetTimeout(self.handle, timeout)
end

function Socket:send(s)
    local sent, err = comm.rawSocketSend(self.handle, stringToByteArray(s))
    return sent, err
end

function Socket:receive(length)
    local data, err = comm.rawSocketReceive(self.handle, length)
    if data then data = byteArrayToString(data) end
    if not data and not err then return data, "timeout" end
    return data, err
end

function Socket:close()
    return comm.rawSocketDestroy(self.handle)
end

-- unified error interface should match the luasocket interface