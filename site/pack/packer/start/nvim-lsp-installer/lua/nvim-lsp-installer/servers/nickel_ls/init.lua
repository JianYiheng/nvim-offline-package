local path = require "nvim-lsp-installer.path"
local server = require "nvim-lsp-installer.server"
local installer = require "nvim-lsp-installer.core.installer"
local cargo = require "nvim-lsp-installer.core.managers.cargo"
local git = require "nvim-lsp-installer.core.managers.git"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://nickel-lang.org/",
        languages = { "nickel" },
        async = true,
        installer = installer.serial {
            git.clone { "https://github.com/tweag/nickel" },
            ---@param ctx InstallContext
            function(ctx)
                ctx.spawn.cargo {
                    "install",
                    "--root",
                    ".",
                    "--path",
                    path.concat { "lsp", "nls" },
                }
            end,
        },
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
