function color_name_to_rgb(color) {
    var ctx = document.createElement('canvas').getContext('2d');
    ctx.fillStyle = color;
    return ctx.fillStyle;
}
function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
}
;
function shadeColor(color, percent) {
    // from https://stackoverflow.com/questions/5560248
    color = color_name_to_rgb(color);
    const num = parseInt(color.slice(1), 16);
    const amt = Math.round(2.55 * percent);
    let R = (num >> 16) + amt;
    let G = (num >> 8 & 0x00FF) + amt;
    let B = (num & 0x0000FF) + amt;
    R = clamp(R, 0, 255);
    G = clamp(G, 0, 255);
    B = clamp(B, 0, 255);
    return "#" + (1 << 24 | R << 16 | G << 8 | B).toString(16).slice(1);
}
export function colorIcon(fill) {
    fill = color_name_to_rgb(fill);
    let stroke = shadeColor(fill, -10);
    // Note: Attach styles directly to paths, as styles within <style></style> are overwritten by new SVG Icons
    let svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="30" height="40" viewBox="0 0 50.29 81.47">
    <defs>
      <linearGradient id="linear-gradient" x1="281.94" y1="307.83" x2="281.94" y2="383.66" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#fff" stop-opacity="0.2"/>
        <stop offset="1" stop-color="#fff" stop-opacity="0.0"/>
      </linearGradient>
    </defs>
    <g id="bg"><path fill="${fill}" d="M282.11,383.48s19.55-37,21-41.5c14.34-45.08-56.28-44.9-42.58-.1C262.09,347.07,282.11,383.48,282.11,383.48Z" transform="translate(-256.73 -306.23)"/></g>
    <g id="grad"><path fill="url(#linear-gradient)" d="M282.11,383.48s19.55-37,21-41.5c14.34-45.08-56.28-44.9-42.58-.1C262.09,347.07,282.11,383.48,282.11,383.48Z" transform="translate(-256.73 -306.23)"/></g>
    <g id="outWhiteBorder"><path stroke-miterlimit="10" fill="none" stroke="#fff" stroke-opacity="0.15" stroke-width="5px" d="M282.11,383.48s19.55-37,21-41.5c14.34-45.08-56.28-44.9-42.58-.1C262.09,347.07,282.11,383.48,282.11,383.48Z" transform="translate(-256.73 -306.23)"/></g>
    <g id="outBorder"><path fill="none" stroke-miterlimit="10" stroke="${stroke}" stroke-width="2px" d="M282.11,383.48s19.55-37,21-41.5c14.34-45.08-56.28-44.9-42.58-.1C262.09,347.07,282.11,383.48,282.11,383.48Z" transform="translate(-256.73 -306.23)"/></g>
    <g id="inWhiteBorder"><circle class="cls-3" cx="25.27" cy="24.83" r="9.15"/></g>
    <g id="inBorder"><circle fill="#fff" stroke="${stroke}" stroke-width="2px" cx="25.27" cy="24.83" r="9.15"/></g>
  </svg>
`;
    return L.divIcon({
        html: svg,
        className: "leaflet-color-icon",
        iconSize: [40, 40],
        iconAnchor: [13, 40],
    });
}
