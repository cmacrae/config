/* General purpose file format generator functions.
 * - toSwayInputs: Generate sway 'input' configurations
 * - toSwayOutputs: Generate mako 'output' configurations
 */
{ lib }:
with lib;

rec {
  /* 
   */
  toSwayInputs = input:
    concatStringsSep "\n" (

      mapAttrsToList (device: config: ''
      input "${device}" {
        ${concatStringsSep "\n  " (
          mapAttrsToList (param: value: "${param} ${value}") config
        )}
      }
      '') input
    );
}
