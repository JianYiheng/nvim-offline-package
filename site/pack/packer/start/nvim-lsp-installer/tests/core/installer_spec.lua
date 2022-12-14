local spy = require "luassert.spy"
local match = require "luassert.match"
local fs = require "nvim-lsp-installer.core.fs"
local installer = require "nvim-lsp-installer.core.installer"
local InstallContext = require "nvim-lsp-installer.core.installer.context"
local process = require "nvim-lsp-installer.process"
local Optional = require "nvim-lsp-installer.core.optional"

describe("installer", function()
    it(
        "should call installer",
        async_test(function()
            spy.on(fs, "mkdirp")
            spy.on(fs, "rename")
            local installer_fn = spy.new(
                ---@param c InstallContext
                function(c)
                    c.receipt:with_primary_source(c.receipt.npm "the-pkg")
                end
            )
            local destination_dir = ("%s/installer_spec"):format(os.getenv "INSTALL_ROOT_DIR")
            local ctx = InstallContext.new {
                name = "installer_spec_success",
                destination_dir = destination_dir,
                boundary_path = os.getenv "INSTALL_ROOT_DIR",
                stdio_sink = process.empty_sink(),
                requested_version = Optional.empty(),
            }
            local result = installer.execute(ctx, installer_fn)
            assert.is_nil(result:err_or_nil())
            assert.spy(installer_fn).was_called(1)
            assert.spy(installer_fn).was_called_with(match.ref(ctx))
            assert.spy(fs.mkdirp).was_called(1)
            assert.spy(fs.mkdirp).was_called_with(destination_dir .. ".tmp")
            assert.spy(fs.rename).was_called(1)
            assert.spy(fs.rename).was_called_with(destination_dir .. ".tmp", destination_dir)
        end)
    )

    it(
        "should return failure if installer errors",
        async_test(function()
            spy.on(fs, "rmrf")
            local installer_fn = spy.new(function()
                error("something went wrong. don't try again.", 4) -- 4 because spy.new callstack
            end)
            local destination_dir = ("%s/installer_spec_failure"):format(os.getenv "INSTALL_ROOT_DIR")
            local ctx = InstallContext.new {
                name = "installer_spec_failure",
                destination_dir = destination_dir,
                boundary_path = os.getenv "INSTALL_ROOT_DIR",
                stdio_sink = process.empty_sink(),
                requested_version = Optional.empty(),
            }
            local result = installer.execute(ctx, installer_fn)
            assert.spy(installer_fn).was_called(1)
            assert.spy(installer_fn).was_called_with(match.ref(ctx))
            assert.is_true(result:is_failure())
            assert.equals("something went wrong. don't try again.", result:err_or_nil())
            assert.spy(fs.rmrf).was_called(2)
            assert.spy(fs.rmrf).was_called_with(destination_dir .. ".tmp")
            assert.spy(fs.rmrf).was_not_called_with(destination_dir)
        end)
    )

    it(
        "should write receipt",
        async_test(function()
            spy.on(fs, "write_file")
            local destination_dir = ("%s/installer_spec_receipt"):format(os.getenv "INSTALL_ROOT_DIR")
            local ctx = InstallContext.new {
                name = "installer_spec_receipt",
                destination_dir = destination_dir,
                boundary_path = os.getenv "INSTALL_ROOT_DIR",
                stdio_sink = process.empty_sink(),
                requested_version = Optional.empty(),
            }
            installer.execute(ctx, function(c)
                c.receipt:with_primary_source(c.receipt.npm "my-pkg")
            end)
            assert.spy(fs.write_file).was_called(1)
            assert.spy(fs.write_file).was_called_with(
                ("%s.tmp/nvim-lsp-installer-receipt.json"):format(destination_dir),
                match.is_string()
            )
        end)
    )
end)
