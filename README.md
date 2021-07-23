# ogg-image-blobber

Simple script to convert jpg files into base64 blobs suitable for attaching to ogg image files as `metadata_block_picture`
Runs in bash, no known dependencies, simply uses what come on a standard Linux install

The image width/height determination method feels fragile, but it seems to work so far.

Follows the format outlined by ogg creators:
https://xiph.org/flac/format.html#metadata_block_picture
