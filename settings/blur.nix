{
  lib,
  kdl,
  niri-flake-internal,
  ...
}:
let
  inherit (niri-flake-internal)
    nullable
    fmt
    float-or-int
    make-rendered-section
    ;
  inherit (lib) types;
  notNull = name: value: lib.optional (value != null) (kdl.leaf name value);
in
[
  {
    options.blur =
      make-rendered-section "blur" { partial = true; } [
        {
          options.enable = nullable types.bool;
          render = config: [
            (lib.mkIf (config.enable == false) [
              (kdl.flag "off")
            ])
          ];
        }
        {
          options.passes = nullable types.int // {
            description = ''
              Number of downsample and upsample passes. More passes produce a smoother and larger blur but cost more GPU resources.
            '';
          };

          render = config: notNull "passes" config.passes;
        }
        {
          options.offset = nullable float-or-int // {
            description = ''
              Pixel offset multiplier of each pass (default is 1). Larger values produce smoother blur at no GPU cost. However, visual artifacts can appear with larger values. The solution is to increase the number of passes as well.

              Try to increase ${fmt.code "offset"} first, until artifacts appear. If a smoother blur is needed, increment ${fmt.code "passes"} by 1 until the artifacts disappear.
            '';
          };

          render = config: notNull "offset" config.offset;
        }
        {
          options.noise = nullable float-or-int // {
            description = ''
              Amount of noise to add on top of the blur.

              This is helpful to reduce color banding artifacts.
            '';
          };

          render = config: notNull "noise" config.noise;
        }
        {
          options.saturation = nullable float-or-int // {
            description = ''
              Color saturation applied to the blurred background.

              Values above ${fmt.code "1"} increase saturation; values below ${fmt.code "1"} reduce it.
            '';
          };

          render = config: notNull "saturation" config.saturation;
        }
      ]
      // {
        description = ''
          Global blur settings for both the ${fmt.code "ext-background-effect"} wayland protocol and layer or window rules.
        '';
      };
    render = config: config.blur.rendered;
  }
]
