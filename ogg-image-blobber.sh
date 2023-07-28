#!/usr/bin/env bash

if [ -z "${1}" ]; then
  echo "Please supply a jpg image file"
  exit 1
fi

DESCRIPTION="Cover Artwork"
IMAGE_SOURCE="${1}"
IMAGE_MIME_TYPE="image/jpeg"
TARGET="${IMAGE_SOURCE%.j*}"
TYPE_ALBUM_COVER=3

print_hex() {
  local STRING="${1}"
  printf "0: %.8x" "${STRING}"
}

print_binary() {
  local STRING="${1}"
  echo -n "${STRING}" | xxd -r -g0
}

get_image_dimension() {
  local DIMENSION="${1}"
  file "${IMAGE_SOURCE}" | \
  awk -v dimension="${DIMENSION}" '
    BEGIN {
      dimensions["width"]=1;
      dimensions["height"]=2;
    }
    {
      for(dim_index=NF; dim_index>1; dim_index--) {
        if ($dim_index ~ /[0-9]{1,}x[0-9]{1,}/) {
          sub(/,/, "", $dim_index);
          split($dim_index, fields, "x");
          printf("%s", fields[dimensions[dimension]]);
          exit 0;
        }
      }
    }'
}

image_width() {
  echo -n $(get_image_dimension "width")
}

image_height() {
  echo -n $(get_image_dimension "height")
}

# sed filter removes leading spaces
# - this for BSD-flavors of wc which insert leading spaces
get_image_size() {
  local FILE=${@}
  echo -n "$(wc -c "${FILE}" | sed 's/^[ ]*//g' | cut -d ' ' -f1)"
}

add_to_target_binary() {
  local STRING="${1}"
  print_binary "$(print_hex ${STRING})" >> "${TARGET}.tmp"
}

add_to_target_direct() {
  local STRING="${1}"
  echo -n "${STRING}" >> "${TARGET}.tmp"
}

# (re)create target
echo -n "" > "${TARGET}.tmp"

# Picture type <32>
add_to_target_binary "${TYPE_ALBUM_COVER}"

# Mime type length <32>
add_to_target_binary "${#IMAGE_MIME_TYPE}"

# Mime type (n * 8)
add_to_target_direct "${IMAGE_MIME_TYPE}"

# Description length <32>
add_to_target_binary "${#DESCRIPTION}"

# Description (n * 8)
add_to_target_direct "${DESCRIPTION}"

# Picture width <32>
##add_to_target_binary "$(image_width)"
add_to_target_binary 0

# Picture height <32>
##add_to_target_binary "$(image_height)"
add_to_target_binary 0

# Picture color depth <32> (probably should figure this out, but seems to be okay at 0)
add_to_target_binary 0

# Picture color index <32> (0 for jpg, only really applicable to gifs)
add_to_target_binary 0

# Image file size <32>
add_to_target_binary "$(get_image_size ${IMAGE_SOURCE})"

# Image file (n * 8)
cat "${IMAGE_SOURCE}" >> "${TARGET}.tmp"

# Output to base64
if [ "$(uname)" == "Darwin" ]; then
    # MacOS/BSD version of base64 tool:
    WRAP_OPT="--break=0"
else
    WRAP_OPT="--wrap=0"
fi
base64 "${WRAP_OPT}" "${TARGET}.tmp" > "${TARGET}.base64"

# Cleanup our mess
rm -f "${TARGET}.tmp"
