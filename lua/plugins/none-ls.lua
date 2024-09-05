return {
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonLog", "MasonUninstallAll" },
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    event = { "BufRead", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvimtools/none-ls-extras.nvim",
      "williamboman/mason.nvim",
      "jay-babu/mason-null-ls.nvim",
    },
    config = function()
      -- enable eslint_d tracking for nvim is running
      vim.env.ESLINT_D_PPID = vim.fn.getpid()
      -- disable error when no eslint
      vim.env.ESLINT_D_MISS = "ignore"

      -- Helper to conditionally register eslint handlers only if eslint is
      -- config. If eslint is not configured for a project, it just fails.
      local function has_eslint_config(utils)
        return utils.root_has_file({
          ".eslintrc",
          ".eslintrc.cjs",
          ".eslintrc.js",
          ".eslintrc.json",
          "eslint.config.cjs",
          "eslint.config.js",
          "eslint.config.mjs",
        })
      end

      require("null-ls").setup({
        sources = {
          -- Lua
          require("null-ls.builtins.formatting.stylua"),
          -- .env files
          require("null-ls.builtins.diagnostics.dotenv_linter"),
          -- editorconfig
          require("null-ls.builtins.diagnostics.editorconfig_checker"),
          -- markdown
          require("null-ls.builtins.diagnostics.markdownlint"),
          require("null-ls.builtins.formatting.markdownlint"),
          -- Shells
          require("null-ls.builtins.formatting.shellharden"),
          -- Gitcommit
          require("null-ls.builtins.diagnostics.commitlint"),
          -- Docker
          require("null-ls.builtins.diagnostics.hadolint"),
          -- Python
          require("null-ls.builtins.diagnostics.pylint"),
          -- JavaScript / TypeScript
          require("none-ls.code_actions.eslint_d").with({
            condition = has_eslint_config,
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
              "vue",
              "svelte",
              "astro",
              "html",
              "htmlangular",
              "angular2html",
            },
          }),
          require("none-ls.diagnostics.eslint_d").with({
            condition = has_eslint_config,
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
              "vue",
              "svelte",
              "astro",
              "html",
              "htmlangular",
              "angular2html",
            },
          }),
          require("none-ls.formatting.eslint_d").with({
            condition = has_eslint_config,
          }),
          -- Yaml
          require("none-ls.diagnostics.yamllint"),
          -- HTML
          require("null-ls.builtins.formatting.prettierd").with({
            filetypes = {
              "angular",
              "htmlangular",
              "angular2html",
              "html",
              "markdown",
              "markdown.mdx",
              "yaml",
              "graphql",
            },
          }),
        },
      })

      require("mason-null-ls").setup({
        ensure_installed = nil,
        automatic_installation = true,
      })

      local function is_null_ls_formatting_enabled(bufnr)
        local file_type = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        local generators =
          require("null-ls.generators").get_available(file_type, require("null-ls.methods").internal.FORMATTING)
        return #generators > 0
      end

      local none_ls_formatting = function(bufnr)
        vim.lsp.buf.format({
          filter = function(client)
            return client.name == "null-ls"
          end,
          bufnr = bufnr,
          async = true,
          timeout_ms = 5000,
        })
      end

      local lsp_formatting = function(bufnr)
        vim.lsp.buf.format({
          filter = function(client)
            return client.name ~= "null-ls"
          end,
          bufnr = bufnr,
          async = true,
          timeout_ms = 5000,
        })
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local bufnr = ev.buf

          local format_function
          if is_null_ls_formatting_enabled(bufnr) then
            format_function = none_ls_formatting
          else
            format_function = lsp_formatting
          end

          vim.keymap.set("n", "<leader>f", function()
            format_function(bufnr)
          end, { buffer = bufnr })
        end,
      })
    end,
  },
}
