{ hostName, lib, pkgs }:
let
  # systemd service checker for waybar
  waycheck = pkgs.writeShellScriptBin "waycheck"
  ''
    set -e
    sanity() {
      if [ $# -lt 1 ]; then
    	  echo "ERR: No service name provided"
    	  exit 1
      fi
    }
    
    slurp() {
      ${pkgs.jq}/bin/jq -Mc --slurp --raw-input \
    	 'split("\n")
            | map(select(. != "") 
            | split("=") 
            | {"key": .[0], "value": (.[1:] | join("="))})
            | from_entries'
    }
    
    sanity $@
    SVC=''${1}
    STATE=$(${pkgs.systemd}/bin/systemctl show --no-page $SVC \
            | ${pkgs.gnugrep}/bin/grep -E '^ActiveState|^SubState' \
    	      | slurp)
    ACT=$(echo $STATE | ${pkgs.jq}/bin/jq -Mcr '.ActiveState')
    SUB=$(echo $STATE | ${pkgs.jq}/bin/jq -Mcr '.SubState')
    
    # '{"text": "$text", "tooltip": "$tooltip", "class": "$class"}'
    if [[  $ACT == "active" && $SUB == "running" ]]; then
        export CLASS="active"
    elif [[  $ACT == "active" && $SUB == "dead" ]]; then
        export CLASS="inactive"
    else
        export CLASS="disabled"
    fi
    
    ${pkgs.coreutils}/bin/printf \
    "text=%s\ntooltip=%s\nclass=%s" "" "$ACT: $SUB" "$CLASS" \
    | slurp
  '';

  baseModulesRight = [
    "idle_inhibitor"
    "pulseaudio"
    "network"
    "battery"
    "clock"
  ];

  baseConfig = {
    layer = "top";
    modules-left = [ "sway/workspaces" "sway/mode" ];
    modules-center = [ "sway/window" ];
    modules-right = baseModulesRight;
  
    "sway/window" = { max-length = 50; };
    "sway/workspaces" = {
      disable-scroll = true;
      all-outputs = true;
      format = "{icon}";
      format-icons = {
        "1" = "";
        "2" = "";
        "3" = "";
        "4" = "";
        "5" = "";
        "6" = "";
        "7" = "";
        "8" = "";
        "9" = "";
        "10" = "";
      };
    };
  
    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "";
        deactivated = "";
      };
    };
  
    network = {
      format-wifi = "";
      format-ethernet = "";
      format-disconnected = "";
      tooltip-format-wifi = "{essid} ({signalStrength}%) ";
      tooltip-format-ethernet = "{ipaddr}/{cidr} ";
      tooltip-format-disconnected = "disconnected ";
    };
  
    pulseaudio = {
      format = "{volume}% {icon}";
      format-bluetooth = "{volume}% {icon}";
      format-muted = "";
      format-icons = {
        headphones = "";
        default = [ "" "" ];
      };
    };
  
    battery = {
      format = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-icons = ["" "" "" "" ""];
      tooltip = false;
    };
  
    clock = {
      format-alt = "{:%a, %d. %b  %H:%M}";
      tooltip = false;
    };
  
  };

  workConfig = {
    modules-right = ["custom/openvpn"] ++ baseModulesRight;
    "custom/openvpn" = {
        format = "{}";
        max-length = 40;
        interval = 10;
        return-type = "json";
        exec = "${waycheck}/bin/waycheck openvpn-moo";
        on-click = ''
          ${pkgs.sudo}/bin/sudo ${pkgs.systemd}/bin/systemctl start openvpn-moo
        '';
        on-click-right = ''
          ${pkgs.sudo}/bin/sudo ${pkgs.systemd}/bin/systemctl stop openvpn-moo
        '';
    };
  };

in baseConfig // (lib.optionalAttrs (hostName == "thinkpad") workConfig)
