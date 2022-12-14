local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local npm = require "nvim-lsp-installer.core.managers.npm"
local git = require "nvim-lsp-installer.core.managers.git"
local installer = require "nvim-lsp-installer.core.installer"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "ansible" },
        homepage = "https://github.com/ansible/ansible-language-server",
        async = true,
        installer = installer.serial {
            git.clone { "https://github.com/ansible/ansible-language-server" },
            -- ansiblels has quite a strict npm version requirement.
            -- Install dependencies using the the latest npm version.
            npm.exec { "npm@latest", "install" },
            npm.run { "compile" },
        },
        default_options = {
            cmd = { "node", path.concat { root_dir, "out", "server", "src", "server.js" }, "--stdio" },
        },
    }
end
