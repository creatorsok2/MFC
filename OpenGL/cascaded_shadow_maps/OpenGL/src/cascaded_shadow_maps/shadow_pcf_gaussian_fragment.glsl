//----------------------------------------------------------------------------------
// File:   shadow_single_fragment.glsl
// Author: Rouslan Dimitrov
// Email:  sdkfeedback@nvidia.com
// Cascaded shadows maps, single shadow sample
// Copyright (c) NVIDIA Corporation. All rights reserved.
//----------------------------------------------------------------------------------

#version 120
#extension GL_EXT_texture_array : enable

uniform sampler2D tex;
uniform vec4 far_d;
uniform vec2 texSize; // x - size, y - 1/size


varying vec4 vPos;

uniform sampler2DArrayShadow stex;
float shadowCoef()
{
	int index = 3;
	
	// find the appropriate depth map to look up in based on the depth of this fragment
	if(gl_FragCoord.z < far_d.x)
		index = 0;
	else if(gl_FragCoord.z < far_d.y)
		index = 1;
	else if(gl_FragCoord.z < far_d.z)
		index = 2;
	
	// transform this fragment's position from view space to scaled light clip space
	// such that the xy coordinates are in [0;1]
	// note there is no need to divide by w for othogonal light sources
	vec4 shadow_coord = gl_TextureMatrix[index]*vPos;

	shadow_coord.w = shadow_coord.z;
	
	// tell glsl in which layer to do the look up
	shadow_coord.z = float(index);

	
	// Gaussian 3x3 filter
	float ret = shadow2DArray(stex, shadow_coord).x * 0.25;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( -1, -1)).x * 0.0625;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( -1, 0)).x * 0.125;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( -1, 1)).x * 0.0625;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( 0, -1)).x * 0.125;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( 0, 1)).x * 0.125;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( 1, -1)).x * 0.0625;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( 1, 0)).x * 0.125;
	ret += shadow2DArrayOffset(stex, shadow_coord, ivec2( 1, 1)).x * 0.0625;
	
	
	return ret;
}

void main()
{
    const float shadow_ambient = 0.9;
	vec4 color_tex = texture2D(tex, gl_TexCoord[0].st);
	float shadow_coef = shadowCoef();
	float fog = clamp(gl_Fog.scale*(gl_Fog.end + vPos.z), 0.0, 1.0);
	gl_FragColor = mix(gl_Fog.color, (shadow_ambient * shadow_coef * gl_Color * color_tex + (1.0 - shadow_ambient) * color_tex), fog);
}