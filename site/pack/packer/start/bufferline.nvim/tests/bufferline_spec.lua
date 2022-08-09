local utils = require("tests.utils")

describe("Bufferline tests:", function()
  vim.opt.swapfile = false
  vim.opt.hidden = true

  local bufferline
  ---@module "bufferline.state"
  local state
  ---@module "nvim-web-devicons"
  local icons

  before_each(function()
    package.loaded["bufferline"] = nil
    package.loaded["bufferline.state"] = nil
    package.loaded["nvim-web-devicons"] = nil
    -- dependent modules need to also be reset as
    -- they keep track of state themselves now
    package.loaded["bufferline.commands"] = nil
    bufferline = require("bufferline")
    state = require("bufferline.state")
    icons = require("nvim-web-devicons")
    icons.setup({ default = true })
  end)

  after_each(function()
    vim.cmd("silent %bwipeout!")
  end)

  describe("render buffer - ", function()
    it("should create corresponding buffers in state", function()
      bufferline.setup()
      vim.cmd("edit test-1.txt")
      vim.cmd("edit test-2.txt")
      local tabline = nvim_bufferline()
      assert.truthy(tabline)
      assert.is.equal(#state.components, 2)
    end)

    it("should allow configuring the indicator icon", function()
      local icon = "R"
      bufferline.setup({
        options = {
          indicator_icon = icon,
        },
      })
      vim.cmd("edit test.txt")
      local tabline = nvim_bufferline()
      assert.truthy(tabline)
      assert.is_truthy(tabline:match(icon))
    end)

    it("should allow formatting names", function()
      bufferline.setup({
        options = {
          name_formatter = function(buf)
            if buf.path:match("test.txt") then
              return "TEST"
            end
          end,
        },
      })
      vim.cmd("edit test.txt")
      local tabline = nvim_bufferline()
      assert.truthy(tabline)
      assert.truthy(tabline:match("TEST"))
    end)
  end)

  describe("Snapshots - ", function()
    local snapshots = {
      "       a.txt       ▕       b.txt       ▕▎      c.txt         ",
      "       a.txt      ▕       b.txt      ▕▎      c.txt        ",
      "       a.txt              b.txt              c.txt         ",
    }
    it("should add correct padding if close icons are present", function()
      bufferline.setup()
      vim.cmd("file! a.txt")
      vim.cmd("edit b.txt")
      vim.cmd("edit c.txt")
      local tabline = nvim_bufferline()
      assert.is_truthy(tabline)
      local snapshot = utils.format_tabline(tabline)
      assert.is_equal(snapshot, snapshots[1])
    end)

    it("should add correct padding if close icons are absent", function()
      bufferline.setup({
        options = {
          show_buffer_close_icons = false,
        },
      })
      vim.cmd("file! a.txt")
      vim.cmd("edit b.txt")
      vim.cmd("edit c.txt")
      local tabline = nvim_bufferline()
      assert.is_truthy(tabline)
      local snapshot = utils.format_tabline(tabline)
      assert.is_equal(snapshot, snapshots[2])
    end)
    it("should show the correct separators", function()
      bufferline.setup({
        options = {
          separator_style = "slant",
        },
      })
      vim.cmd("file! a.txt")
      vim.cmd("edit b.txt")
      vim.cmd("edit c.txt")
      local tabline = nvim_bufferline()
      assert.is_truthy(tabline)
      local snapshot = utils.format_tabline(tabline)
      assert.is_equal(snapshot, snapshots[3])
    end)

    it("should not show a default icon if specified", function()
      bufferline.setup({
        options = {
          show_buffer_default_icon = false,
        },
      })
      vim.cmd("edit test.rrj")
      local tabline = nvim_bufferline()
      local snapshot = utils.format_tabline(tabline)
      local icon = icons.get_icon("")
      assert.is_false(snapshot:match(icon) == nil)
    end)

    it("should show a default icon if specified", function()
      bufferline.setup({
        options = {
          show_buffer_default_icon = true,
        },
      })
      vim.cmd("edit test.rrj")
      local tabline = nvim_bufferline()
      local snapshot = utils.format_tabline(tabline)
      local icon = icons.get_icon("")
      assert.is_true(snapshot:match(icon) ~= nil)
    end)
  end)

  describe("clicking - ", function()
    it("should left handle mouse clicks correctly", function()
      local bufnum = vim.api.nvim_get_current_buf()
      bufferline.setup({
        options = {
          left_mouse_command = "vertical sbuffer %d",
        },
      })
      bufferline.handle_click(bufnum, "l")
      assert.is_equal(#vim.api.nvim_list_wins(), 2)
    end)

    it("should middle handle mouse clicks correctly", function()
      local bufnum = vim.api.nvim_get_current_buf()
      bufferline.setup({
        options = {
          middle_mouse_command = function(bufid)
            vim.bo[bufid].filetype = "test"
          end,
        },
      })
      bufferline.handle_click(bufnum, "m")
      assert.is_equal(vim.bo[bufnum].filetype, "test")
    end)

    it("should right handle mouse clicks correctly", function()
      local bufnum = vim.api.nvim_get_current_buf()
      bufferline.setup({
        options = {
          right_mouse_command = "setfiletype egg",
        },
      })
      bufferline.handle_click(bufnum, "r")
      assert.is_equal(vim.bo.filetype, "egg")
    end)

    it("should handle close click correctly", function()
      local bufnum = vim.api.nvim_get_current_buf()
      local count = 1
      local expected = bufnum + count
      bufferline.setup({
        options = {
          close_command = function(bufid)
            count = count + bufid
          end,
        },
      })
      bufferline.handle_close(bufnum)
      assert.is_equal(count, expected)
    end)
  end)

  -- FIXME: nvim_bufferline() needs to be manually called
  describe("commands - ", function()
    it("should close buffers to the right of the current buffer", function()
      bufferline.setup()
      vim.cmd("file! a.txt")
      vim.cmd("edit b.txt")
      vim.cmd("edit c.txt")
      vim.cmd("edit d.txt")
      vim.cmd("edit e.txt")
      nvim_bufferline()

      vim.cmd("edit c.txt")
      bufferline.close_in_direction("right")
      local bufs = vim.api.nvim_list_bufs()
      assert.is_equal(3, #bufs)
    end)

    it("should close buffers to the left of the current buffer", function()
      bufferline.setup()
      vim.cmd("edit! a.txt")
      vim.cmd("edit b.txt")
      vim.cmd("edit c.txt")
      vim.cmd("edit d.txt")
      vim.cmd("edit e.txt")
      nvim_bufferline()

      assert.is.equal(5, #state.components)

      local bufs = vim.api.nvim_list_bufs()
      assert.is_equal(5, #bufs)
      bufferline.close_in_direction("left")
      bufs = vim.api.nvim_list_bufs()
      assert.is_equal(1, #bufs)
    end)
  end)
end)
