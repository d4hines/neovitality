{ pkgs, lib ? pkgs.lib }:
let
  vimOptions = lib.evalModules {
    modules = [
      {
        imports = [
          (
            { config, lib, pkgs, ... }:
              with lib;
              with builtins;
              let
                wrapLuaConfig = luaConfig: ''
                  lua << EOF
                  ${luaConfig}
                  EOF
                '';
                mkMappingOption = it: mkOption ({
                  example = { abc = ":FZF<CR>"; Ctrl-p = ":FZF<CR>"; }; # Probably should be overwritten per option basis
                  default = { };
                  type = with types; attrsOf (nullOr str);
                } // it);
                languagesOpts = { name, config, ... }: {
                  options = {
                    lspConfig = {

                      cmd = mkOption {
                        default = [ ];
                        type = with types; listOf str;
                      };

                      filetypes = mkOption {
                        default = [ ];
                        type = with types; listOf str;
                      };
                    };
                  };
                };
              in
              {
                options = {
                  vim.enable = mkEnableOption "vitality vim package";

                  vim.languages = mkOption {
                    default = { };
                    type = with types; attrsOf (submodule languagesOpts);
                  };

                  vim.startPlugins = mkOption {
                    type = with types; listOf package;
                    default = [ ];
                    description = "";
                    example = [ pkgs.vim-clap ];
                  };

                  vim.optPlugins = mkOption {
                    type = with types; listOf package;
                    default = [ ];
                    description = "";
                    example = [ pkgs.vim-clap ];
                  };

                  vim.plugins = mkOption {
                    type = with types; listOf attrs; # Probably some legit type should be set
                    default = [ ];
                    description = "";
                    example = [{ plugin = pkgs.vim-clap; config = "abc"; }];
                  };

                  vim.configRC = mkOption {
                    default = "";
                    description = ''VimScript config'';
                    type = types.lines;
                  };



                  vim.globals = mkOption {
                    example = { some_fancy_varialbe = 1; };
                    default = { };
                    type = types.attrs;
                  };

                  vim.nnoremap = mkMappingOption {
                    description = "Defines 'Normal mode' mappings";
                  };

                  vim.inoremap = mkMappingOption {
                    description = "Defines 'Insert and Replace mode' mappings";
                  };

                  vim.vnoremap = mkMappingOption {
                    description = "Defines 'Visual and Select mode' mappings";
                  };

                  vim.xnoremap = mkMappingOption {
                    description = "Defines 'Visual mode' mappings";
                  };

                  vim.snoremap = mkMappingOption {
                    description = "Defines 'Select mode' mappings";
                  };

                  vim.cnoremap = mkMappingOption {
                    description = "Defines 'Command-line mode' mappings";
                  };

                  vim.onoremap = mkMappingOption {
                    description = "Defines 'Operator pending mode' mappings";
                  };

                  vim.tnoremap = mkMappingOption {
                    description = "Defines 'Terminal mode' mappings";
                  };



                  vim.nmap = mkMappingOption {
                    description = "Defines 'Normal mode' mappings";
                  };

                  vim.imap = mkMappingOption {
                    description = "Defines 'Insert and Replace mode' mappings";
                  };

                  vim.vmap = mkMappingOption {
                    description = "Defines 'Visual and Select mode' mappings";
                  };

                  vim.xmap = mkMappingOption {
                    description = "Defines 'Visual mode' mappings";
                  };

                  vim.smap = mkMappingOption {
                    description = "Defines 'Select mode' mappings";
                  };

                  vim.cmap = mkMappingOption {
                    description = "Defines 'Command-line mode' mappings";
                  };

                  vim.omap = mkMappingOption {
                    description = "Defines 'Operator pending mode' mappings";
                  };

                  vim.tmap = mkMappingOption {
                    description = "Defines 'Terminal mode' mappings";
                  };
                };

                config =
                  let
                    matchCtrl = it: match "Ctrl-(.)(.*)" it;
                    filterNonNull = mappings: filterAttrs (name: value: value != null) mappings;

                    mapKeybinding = it:
                      let groups = matchCtrl it; in if groups == null then it else "<C-${toUpper (head groups)}>${head (tail groups)}";
                    mapVimBinding = prefix: mappings: mapAttrsFlatten (name: value: "${prefix} ${mapKeybinding name} ${value}") (filterNonNull mappings);

                    globalsVimscript = mapAttrsFlatten (name: value: "let g:${name}=${toJSON value}") (filterNonNull config.vim.globals);

                    nmap = mapVimBinding "nmap" config.vim.nmap;
                    imap = mapVimBinding "imap" config.vim.imap;
                    vmap = mapVimBinding "vmap" config.vim.vmap;
                    xmap = mapVimBinding "xmap" config.vim.xmap;
                    smap = mapVimBinding "smap" config.vim.smap;
                    cmap = mapVimBinding "cmap" config.vim.cmap;
                    omap = mapVimBinding "omap" config.vim.omap;
                    tmap = mapVimBinding "tmap" config.vim.tmap;

                    nnoremap = mapVimBinding "nnoremap" config.vim.nnoremap;
                    inoremap = mapVimBinding "inoremap" config.vim.inoremap;
                    vnoremap = mapVimBinding "vnoremap" config.vim.vnoremap;
                    xnoremap = mapVimBinding "xnoremap" config.vim.xnoremap;
                    snoremap = mapVimBinding "snoremap" config.vim.snoremap;
                    cnoremap = mapVimBinding "cnoremap" config.vim.cnoremap;
                    onoremap = mapVimBinding "onoremap" config.vim.onoremap;
                    tnoremap = mapVimBinding "tnoremap" config.vim.tnoremap;

                    attrsWithConfig = filter (it: it ? config) config.vim.plugins;
                    configs = builtins.concatStringsSep " " (map
                      (plugin: ''

          "{{{ ${plugin.plugin.name}
          ${plugin.config}
          "}}}
        '')
                      (attrsWithConfig));
                    start = map (plugin: plugin.plugin) config.vim.plugins;

                    luaArray = name: values: optionalString
                      (any (it: true) values)
                      "${name} = {'${builtins.concatStringsSep "', '" values}'},";


                    buildLspConfig = name: config: ''
                      lspconfig.${name}.setup {
                        ${luaArray "cmd" config.cmd}
                        ${luaArray "filetypes" config.filetypes}
                        capabilities = capabilities,
                      }
                    '';
                    lspConfigs = mapAttrsFlatten (name: value: buildLspConfig name value.lspConfig) config.vim.languages;
                  in
                  {
                    vim.languages =
                      with pkgs;
                      {
                        bashls = { };
                        clangd = lib.mkIf (system == "x86_64-linux") { };
                        clojure_lsp = { };
                        dhall_lsp_server = { };
                        dockerls = { };
                        gopls = { };
                        hls = { };
                        jdtls = { };
                        kotlin_language_server = { };
                        metals = { };
                        ocamlls = { };
                        pyright = { };
                        rnix = { };
                        rust_analyzer = { };
                        solargraph = { };
                        sourcekit = lib.mkIf (pkgs.system == "x86_64-darwin") { };
                        sumneko_lua = lib.mkIf (pkgs.system == "x86_64-linux") { };
                        texlab = { };
                        terraformls = { };
                        tsserver = { };
                        vimls = { };
                        yamlls = { };
                      };

                    vim.startPlugins = start;
                    vim.configRC = ''
                      ${configs}

                      ${builtins.concatStringsSep "\n" nmap}
                      ${builtins.concatStringsSep "\n" imap}
                      ${builtins.concatStringsSep "\n" vmap}
                      ${builtins.concatStringsSep "\n" xmap}
                      ${builtins.concatStringsSep "\n" smap}
                      ${builtins.concatStringsSep "\n" cmap}
                      ${builtins.concatStringsSep "\n" omap}
                      ${builtins.concatStringsSep "\n" tmap}

                      ${builtins.concatStringsSep "\n" nnoremap}
                      ${builtins.concatStringsSep "\n" inoremap}
                      ${builtins.concatStringsSep "\n" vnoremap}
                      ${builtins.concatStringsSep "\n" xnoremap}
                      ${builtins.concatStringsSep "\n" snoremap}
                      ${builtins.concatStringsSep "\n" cnoremap}
                      ${builtins.concatStringsSep "\n" onoremap}
                      ${builtins.concatStringsSep "\n" tnoremap}
                      ${builtins.concatStringsSep "\n" globalsVimscript}

                      ${wrapLuaConfig ''
                          local lspconfig = require'lspconfig'
                          local capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())

                          ${builtins.concatStringsSep "\n" lspConfigs}

                          local lspconfig = require"lspconfig"

                          local function preview_location_callback(_, _, result)
                            if result == nil or vim.tbl_isempty(result) then
                              return nil
                            end
                            vim.lsp.util.preview_location(result[1])
                          end

                          function PeekDefinition()
                            local params = vim.lsp.util.make_position_params()
                            return vim.lsp.buf_request(0, 'textDocument/definition', params, preview_location_callback)
                          end
                        ''}
                    '';
                  };
              }
          )
        ];
      }
      ({
        vim =
          with builtins;
          with lib;
          let

            wrapLuaConfig = luaConfig: ''
              lua << EOF
              ${luaConfig}
              EOF
            '';

          in
          {
            plugins = with pkgs.vimPlugins; with pkgs.vitalityVimPlugins;  [
                            { /*0*/ plugin = telescope-nvim; config = wrapLuaConfig (readFile ./config/telescope-nvim-config.lua); }
                                          { plugin = blamer-nvim; config = readFile ./config/blamer-nvim-config.vim; }
                                          { plugin = cmp-buffer; }               { plugin = cmp-nvim-lsp; }
              { plugin = cmp-path; }
                            { plugin = cmp-treesitter; }
                                                                                                                              { plugin = gitsigns-nvim; config = wrapLuaConfig (builtins.readFile ./config/gitsigns-nvim-config.lua); }
              { plugin = neon; config = readFile ./config/theme-config.vim; }
              { plugin = harpoon; config = wrapLuaConfig (readFile ./config/harpoon-config.lua); }
                                          { plugin = lsp_extensions-nvim; }               { plugin = lsp_signature-nvim; config = "lua require'lsp_signature'.on_attach()"; }
              { plugin = lspkind-nvim; config = "lua require('lspkind').init()"; }
                            { plugin = neogit; }
              { plugin = nvim-cmp; config = wrapLuaConfig (readFile ./config/nvim-cmp-config.lua); }
                                          { plugin = nvim-lightbulb; config = "autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()"; }               { plugin = nvim-lspconfig; }
                            { plugin = nvim-treesitter-context; }
              { plugin = nvim-treesitter-textobjects; config = readFile ./config/nvim-treesitter-textobjects-config.vim; }
                            { plugin = comment-nvim; config = wrapLuaConfig "require('Comment').setup()"; }
              { plugin = nvim-ts-rainbow; }
                            { plugin = octo-nvim; }
              { plugin = pkgs.vimPlugins.nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars); config = wrapLuaConfig (readFile ./config/nvim-treesitter-config.lua); }
              { plugin = pkgs.vimPlugins.telescope-fzy-native-nvim; config = "lua require('telescope').load_extension('fzy_native')"; }
              { plugin = plenary-nvim; }
              { plugin = popup-nvim; }
                                          { plugin = surround; }
              { plugin = tabular; }
                                          { plugin = telescope-file-browser-nvim; config = "lua require('telescope').load_extension('file_browser')"; }
                                                                      { plugin = vim-commentary; }
                                                        { plugin = vim-devicons; }
              { plugin = vim-dispatch; }
                            { plugin = vim-hexokinase; config = "let g:Hexokinase_optInPatterns = 'full_hex,rgb,rgba,hsl,hsla'"; }
                                          { plugin = vim-polyglot; }
                            { plugin = vim-repeat; }
              { plugin = vim-sensible; }
              { plugin = vim-sneak; config = "let g:sneak#label=1"; }
              { plugin = which-key-nvim; config = wrapLuaConfig (readFile ./config/which-key-nvim-config.lua); }
            ];

            configRC = ''
              :set timeoutlen=100
              ${wrapLuaConfig (builtins.readFile ./config/init.lua)}
            '';

            nnoremap = {

              # nvim lsp
              "<F2>" = "<cmd>lua vim.lsp.buf.rename()<cr>";
              "[d" = "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>";
              "]d" = "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>";
              gi = "<cmd>lua vim.lsp.buf.implementation()<cr>";
              K = "<cmd>lua vim.lsp.buf.hover()<cr>";

              Ctrl-_ = "<cmd>lua require('telescope.builtin').live_grep({layout_strategy='vertical',layout_config={width=0.9}})<cr>";
              Ctrl-B = "<cmd>lua require('telescope.builtin').buffers()<cr>";
              Ctrl-P = "<cmd>lua require('telescope.builtin').find_files({layout_strategy='vertical',layout_config={width=0.9}})<cr>";
              gd = "<cmd>lua require('telescope.builtin').lsp_definitions({layout_strategy='vertical',layout_config={width=0.9}})<cr>";
              gr = "<cmd>lua require('telescope.builtin').lsp_references({layout_strategy='vertical',layout_config={width=0.9}})<cr>";

              # navigation
              Ctrl-h = "<C-W>h";
              Ctrl-j = "<C-W>j";
              Ctrl-k = "<C-W>k";
              Ctrl-l = "<C-W>l";

            "<leader>hg" = "<cmd>FloatermNew --title=gitui ${pkgs.gitui}/bin/gitui<cr>";
            };

            inoremap = { };

            snoremap = { };

            tnoremap = {
              "<leader>x" = "<Esc> <C-\\><C-n>";
            };
          };
      })
    ];
    specialArgs = {
      inherit pkgs;
    };
  };
  vim = vimOptions.config.vim;
in
{
  neovim = pkgs.wrapNeovim pkgs.neovim {
    configure = {
      customRC = vim.configRC;

      packages.myVimPackage = with pkgs.vimPlugins; {
        start = vim.startPlugins;
        opt = vim.optPlugins;
      };
    };

  };

  init-vim = vim.configRC;
}
