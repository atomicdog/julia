# This file is a part of Julia. License is MIT: https://julialang.org/license
#
# Pluto launch script for the ppc64le dev container. Constructs a session
# with the desired bind/port up front so the URL+secret can be written to
# disk before Pluto.run blocks.
#
# Writes the URL to /root/.julia/.pluto-url (= $HOME/.julia-jdev/.pluto-url
# on the host) so the file lives in the persistent depot rather than the
# workspace.

import Pluto

const HOST = "0.0.0.0"
const PORT = 1234
const URL_FILE = joinpath(first(DEPOT_PATH), ".pluto-url")

options = Pluto.Configuration.Options(
    server = Pluto.Configuration.ServerOptions(
        host = HOST,
        port = PORT,
        launch_browser = false,
    ),
)
session = Pluto.ServerSession(options=options)

let url = "http://localhost:$(PORT)/?secret=$(session.secret)"
    open(URL_FILE, "w") do io
        println(io, url)
    end
    println("URL: ", url)
    flush(stdout)
end

Pluto.run(session)
