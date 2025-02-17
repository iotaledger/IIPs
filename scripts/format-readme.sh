touch tmp
FIRST="<picture>"
SECOND="  <source media=\"(prefers-color-scheme: dark)\" srcset=\"logo_dark.svg\">"
THIRD="  <source media=\"(prefers-color-scheme: light)\" srcset=\"logo_light.svg\">"
FOURTH="  <img alt=\"Shows a black IOTA logo in light color mode and a white one in dark color mode.\">"
LAST="</picture>"
while IFS= read -r line
do
  if [[ $line == $FIRST || $line == $SECOND ||$line == $THIRD ||$line == $FOURTH ]]; then
      continue
  fi
    if [[ $line == $LAST ]]; then
        line="![image](logo_dark.svg)"
    fi
  echo "$line" >> tmp
done < "$1"

mv tmp $1