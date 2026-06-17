{
  lib,
  kdl,
  niri-flake-internal,
  toplevel-options,
  appearance,
  ...
}:
let
  inherit (niri-flake-internal)
    nullable
    fmt
    float-or-int
    make-rendered-section
    make-ordered-options
    subopts
    required
    ;
  inherit (lib) types;
in
[
  {
    options.recent-windows = make-rendered-section "recent-windows" { partial = true; } [
      {
        options.enable = nullable types.bool;
        render = config: [
          (lib.mkIf (config.enable == false) [
            (kdl.flag "off")
          ])
        ];
      }
      {
        options.debounce-ms = nullable types.int // {
          description = ''
             Delay, in milliseconds, between the window receiving focus and getting "committed" to the recent windows list.

            When you want to focus some window, you might end up focusing some unrelated windows on the way:
            ${fmt.list [
              "with keyboard navigation, the windows between your current one and the target one;"
              "with ${fmt.link-opt (subopts (subopts toplevel-options.input).focus-follows-mouse).enable}, the windows you happen to cross with the mouse pointer on the way to the target window. "
            ]}

            The debounce delay prevents those intermediate windows from polluting the recent windows list.

            Note that some actions, like keyboard input into the target window, will skip this delay and commit the window to the list immediately. This way, the recent windows list stays responsive while not getting polluted too much with unintended windows.

            If you want windows to appear in recent windows right away, including intermediate windows, you can reduce the delay or set it to zero.           
          '';
        };
        render = config: [
          (lib.mkIf (config.debounce-ms != null) [
            (kdl.leaf "debounce-ms" config.debounce-ms)
          ])
        ];
      }
      {
        options.open-delay-ms = nullable types.int // {
          description = ''
            Delay, in milliseconds, between pressing the Alt-Tab bind and the recent windows switcher visually appearing on screen.

            The switcher is delayed by default so that quickly tapping Alt-Tab to switch windows wouldn't cause annoying fullscreen visual changes.
          '';
        };
        render = config: [
          (lib.mkIf (config.open-delay-ms != null) [
            (kdl.leaf "open-delay-ms" config.open-delay-ms)
          ])
        ];
      }
      {
        options.highlight = make-rendered-section "highlight" { partial = true; } [
          {
            options.active-color = nullable types.str // {
              description = ''
                Normal color of the focused window highlight.
              '';
            };
            render = config: [
              (lib.mkIf (config.active-color != null) [
                (kdl.leaf "active-color" config.active-color)
              ])
            ];
          }
          {
            options.urgent-color = nullable types.str // {
              description = ''
                Color of an urgent focused window highlight, also visible in a darker shade on unfocused windows.
              '';
            };
            render = config: [
              (lib.mkIf (config.urgent-color != null) [
                (kdl.leaf "urgent-color" config.urgent-color)
              ])
            ];
          }
          {
            options.padding = nullable types.int // {
              description = ''
                Padding of the highlight around the window preview, in logical pixels.
              '';
            };
            render = config: [
              (lib.mkIf (config.padding != null) [
                (kdl.leaf "padding" config.padding)
              ])
            ];
          }
          {
            options.corner-radius = nullable types.int // {
              description = ''
                Corner radius of the highlight, for rounded corner.
              '';
            };

            render = config: [
              (lib.mkIf (config.corner-radius != null) [
                (kdl.leaf "corner-radius" config.corner-radius)
              ])
            ];
          }
        ];
        render = config: config.highlight.rendered;
      }
      {
        options.previews = make-rendered-section "previews" { partial = true; } [
          {
            options.max-height = nullable types.int // {
              description = ''
                Maximum height of the window previews. Further limits the size of the previews in order to occupy less space on large monitors.
              '';
            };
            render = config: [
              (lib.mkIf (config.max-height != null) [
                (kdl.leaf "max-height" config.max-height)
              ])
            ];
          }
          {
            options.max-scale = nullable float-or-int // {
              description = ''
                Maximum scale of the window previews. Windows cannot be scaled bigger than this value.
              '';
            };
            render = config: [
              (lib.mkIf (config.max-scale != null) [
                (kdl.leaf "max-scale" config.max-scale)
              ])
            ];
          }
        ];
        render = config: config.previews.rendered;
      }
      {
        options.binds = lib.mkOption {
          default = null;
          type = types.nullOr (
            types.attrsOf (
              types.submoduleWith {
                description = "recent windows bindings";
                shorthandOnlyDefinesConfig = true;
                modules = [
                  (make-ordered-options
                    {
                      finalize =
                        rendered:
                        { config, name, ... }:
                        {
                          options.rendered = {
                            name = lib.mkOption {
                              type = lib.types.str;
                              readOnly = true;
                              internal = true;
                              visible = false;
                            };
                            properties = lib.mkOption {
                              type = lib.types.attrsOf kdl.types.kdl-value;
                              internal = true;
                              visible = false;
                            };
                            children = lib.mkOption {
                              type = kdl.types.kdl-document;
                              readOnly = true;
                              internal = true;
                              visible = false;
                            };
                          };

                          config.rendered = lib.mkMerge [
                            { inherit name; }
                            (lib.mkMerge rendered)
                          ];
                        };
                    }
                    [
                      {
                        options.action = required kdl.types.kdl-leaf // {
                          description = ''
                            See ${fmt.link-opt (subopts toplevel-options.binds).action} for the expected structures.

                            The only difference is the accepted actions, being either ${fmt.code "next-window"} or ${fmt.code "previous-window"}. Both can be modified with the following attributs:

                            ${fmt.list [
                              "${fmt.code ''filter="app-id"''}: filters the switcher to the windows of the currently selected application, as determined by the Wayland app ID."
                              "${fmt.code ''scope="all"''}, ${fmt.code ''scope="output"''}, ${fmt.code ''scope="workspace"''}: sets the pre-selected scope when this bind is used to open the recent windows switcher."
                            ]}

                            These binds are overriden if they are also used in ${fmt.link-opt toplevel-options.binds}, and won't have any effect in the recent windows view.
                          '';
                        };
                        render = config: {
                          children = lib.mapAttrsToList kdl.leaf config.action;
                        };
                      }
                    ]
                  )
                ];
              }
            )
          );
        };
        render = config: [
          (lib.mkIf (config.binds != null) [
            (kdl.plain "binds" [
              (map (cfg: cfg.rendered) (builtins.attrValues config.binds))
            ])
          ])
        ];
      }
    ];
    render = config: config.recent-windows.rendered;

  }
]
