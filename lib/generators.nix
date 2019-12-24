/* General purpose file format generator functions.
 * - toSwayInputs: Generate sway 'input' configurations
 * - toSwayOutputs: Generate kanshi 'output' configurations
 */
{ lib }:
with lib;

rec {
  /* Convert a set representing sway 'input' expressions
   * to valid sway config.
   *
   * For example:
   *
   *   inputs = {
   *     "1:1:AT_Translated_Set_2_keyboard" = {
   *       xkb_layout = "gb";
   *       xkb_options = "ctrl:nocaps";
   *     };
   *
   *     "1739:0:Synaptics_TM3381-002" = {
   *       pointer_accel = "0.7";
   *       tap = "enabled";
   *       dwt = "enabled";
   *       natural_scroll = "enabled";
   *     };
   *   };
   */
  toSwayInputs = inputs:
    concatStringsSep "\n" (
      mapAttrsToList (device: config: ''
      input "${device}" {
        ${concatStringsSep "\n  " (
          mapAttrsToList (p: v: "${p} ${v}") config
        )}
      }
      '') inputs
    );


  /* Convert a list of sets representing sway 'output' expressions
   * to valid kanshi config.
   *
   * For example:
   *
   *   outputs = [
   *     { eDP1 = {};}
   *
   *     {
   *       "DP-1" = {
   *         position = "0,0";
   *         transform = "270";
   *       };
   *
   *       "HDMI-A-2" = { position = "1440,470"; };
   *       "eDP-1" = { position = "1440,1910"; };
   *     }
   *   ];
   */
  toSwayOutputs = outputs:
    concatStringsSep "\n" (
      forEach outputs (block: ''
        {
          ${concatStringsSep "\n  " (
            mapAttrsToList (display: config:
              "output ${display} ${concatStringsSep " "
                (mapAttrsToList (p: v: "${p} ${v}") config)}"
            ) block)
           }
        }'' )
    );
}
