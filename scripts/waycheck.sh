set -e
sanity() {
    if [ $# -lt 1 ]; then
	echo "ERR: No service name provided"
	exit 1
    fi
}

slurp() {
    @jq@ -Mc --slurp --raw-input \
	 'split("\n")
        | map(select(. != "") 
        | split("=") 
        | {"key": .[0], "value": (.[1:] | join("="))})
        | from_entries'
}

sanity $@
SVC=${1}
STATE=$(@systemctl@ show --no-page $SVC \
	    | @grep@ -E '^ActiveState|^SubState' \
	     | slurp)
ACT=$(echo $STATE | @jq@ -Mcr '.ActiveState')
SUB=$(echo $STATE | @jq@ -Mcr '.SubState')

# '{"text": "$text", "tooltip": "$tooltip", "class": "$class"}'
if [[  $ACT == "active" && $SUB == "running" ]]; then
    export CLASS="active"
elif [[  $ACT == "active" && $SUB == "dead" ]]; then
    export CLASS="inactive"
else
    export CLASS="disabled"
fi

printf "text=%s\ntooltip=%s\nclass=%s" "" "$ACT: $SUB" "$CLASS" | slurp
