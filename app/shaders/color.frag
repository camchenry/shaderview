vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(texture, texture_coords);
    vec4 tint = vec4(1, 1, 1, 1);
    return tint;
}
