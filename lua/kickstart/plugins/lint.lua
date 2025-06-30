return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        typescript = { 'eslint_d' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })
      require('lint').linters.eslint_d = {
        cmd = 'eslint_d',
        args = {
          '--format',
          'json',
          '--stdin',
          '--stdin-filename',
          function()
            return vim.api.nvim_buf_get_name(0)
          end,
        },
        stream = 'stdout',
        ignore_exitcode = true,
        parser = function(output, bufnr)
          local diagnostics = {}
          if output == '' then
            return diagnostics
          end
          local data = vim.json.decode(output)
          if not data or not data[1] or not data[1].messages then
            return diagnostics
          end
          for _, message in ipairs(data[1].messages) do
            table.insert(diagnostics, {
              bufnr = bufnr,
              lnum = message.line - 1,
              col = message.column - 1,
              end_lnum = message.endLine and (message.endLine - 1) or message.line - 1,
              end_col = message.endColumn and (message.endColumn - 1) or message.column - 1,
              severity = message.severity == 2 and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
              message = string.format('[%s] %s', message.ruleId or 'unknown', message.message),
              source = 'eslint',
            })
          end
          return diagnostics
        end,
      }
    end,
  },
}
